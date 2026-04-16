import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/core/storage/prefs_storage.dart';
import '../models/exam_meta.dart';
import '../models/exam_attempt.dart';

part 'exam_session_notifier.freezed.dart';
part 'exam_session_notifier.g.dart';

// Supabase trả về snake_case, nhưng fromJson expect camelCase
Map<String, dynamic> _mapExamJson(Map<String, dynamic> e) => {
  'id': e['id'],
  'title': e['title'],
  'durationMinutes': e['duration_minutes'] ?? e['durationMinutes'] ?? 0,
};

Map<String, dynamic> _mapSectionJson(Map<String, dynamic> s) => {
  'id': s['id'],
  'skill': s['skill'],
  'label': s['label'],
  'questionCount': s['question_count'] ?? s['questionCount'] ?? 0,
  'sectionDurationMinutes': s['section_duration_minutes'] ?? s['sectionDurationMinutes'],
  'orderIndex': s['order_index'] ?? s['orderIndex'] ?? 0,
};

Map<String, dynamic> _mapAttemptJson(Map<String, dynamic> a) => {
  'id': a['id'],
  'examId': a['exam_id'] ?? a['examId'],
  'userId': a['user_id'] ?? a['userId'],
  'status': a['status'] ?? 'in_progress',
  'answers': a['answers'] ?? {},
  'remainingSeconds': a['remaining_seconds'] ?? a['remainingSeconds'],
  'startedAt': a['started_at'] ?? a['startedAt'],
  'submittedAt': a['submitted_at'] ?? a['submittedAt'],
};

// ── Status ──────────────────────────────────────────────────────────────────

enum ExamSessionStatus {
  initializing,
  ready,
  autosaving,
  autosaveFailed,
  submitting,
  submitted,
}

enum AutosaveStatus { idle, saving, saved, failed }

// ── State ───────────────────────────────────────────────────────────────────

@freezed
class ExamSessionState with _$ExamSessionState {
  const factory ExamSessionState({
    required ExamAttempt attempt,
    required ExamMeta meta,
    @Default(ExamSessionStatus.ready) ExamSessionStatus status,
    @Default({}) Map<String, String> currentAnswers, // questionId → optionId/text
    @Default(0) int currentSectionIndex,
    @Default(0) int currentQuestionIndex,
    @Default(false) bool showSectionTransition,
    @Default(AutosaveStatus.idle) AutosaveStatus autosaveStatus,
    String? errorMessage,
  }) = _ExamSessionState;
}

extension ExamSessionStateX on ExamSessionState {
  SectionMeta get currentSection => meta.sections[currentSectionIndex];

  int get globalQuestionIndex {
    int offset = 0;
    for (var i = 0; i < currentSectionIndex; i++) {
      offset += meta.sections[i].questionCount;
    }
    return offset + currentQuestionIndex;
  }

  int get totalQuestions => meta.totalQuestions;
  int get answeredCount => currentAnswers.length;
  int get unansweredCount => totalQuestions - answeredCount;
}

// ── Notifier ────────────────────────────────────────────────────────────────

@riverpod
class ExamSessionNotifier extends _$ExamSessionNotifier {
  Timer? _autosaveTimer;
  static const _autosaveDebounce = Duration(seconds: 30);
  static const _prefsPrefix = 'exam_answers_';

  @override
  Future<ExamSessionState> build(String attemptId) async {
    ref.onDispose(() => _autosaveTimer?.cancel());

    // Fetch attempt
    final attemptData = await supabase
        .from('exam_attempts')
        .select()
        .eq('id', attemptId)
        .single();
    final attempt = ExamAttempt.fromJson(_mapAttemptJson(attemptData));

    // Fetch exam meta
    final examData = await supabase
        .from('exams')
        .select()
        .eq('id', attempt.examId)
        .single();

    final sectionsData = await supabase
        .from('exam_sections')
        .select()
        .eq('exam_id', attempt.examId)
        .order('order_index');

    final sections = (sectionsData as List)
        .map((s) => SectionMeta.fromJson(_mapSectionJson(s as Map<String, dynamic>)))
        .toList();

    final meta = ExamMeta.fromJson({
      ..._mapExamJson(examData),
      'sections': sections.map((s) => s.toJson()).toList(),
    });

    // Restore buffered answers from prefs (offline fallback).
    // If prefs are empty (new install / cleared), fall back to DB-stored answers.
    final buffered = _loadBufferedAnswers(attemptId);
    final currentAnswers = buffered.isNotEmpty
        ? buffered
        : attempt.answers.map((k, v) => MapEntry(k, v.toString()));

    return ExamSessionState(
      attempt: attempt,
      meta: meta,
      currentAnswers: currentAnswers,
    );
  }

  // ── Answer ────────────────────────────────────────────────────────────────

  void answer(String questionId, String value) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = Map<String, String>.from(current.currentAnswers)
      ..[questionId] = value;

    state = AsyncData(current.copyWith(currentAnswers: updated));
    _scheduleAutosave(current.attempt.id, updated, current.attempt.remainingSeconds);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goToQuestion(int sectionIndex, int questionIndex) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      currentSectionIndex: sectionIndex,
      currentQuestionIndex: questionIndex,
      showSectionTransition: false,
    ));
  }

  void nextQuestion() {
    final current = state.valueOrNull;
    if (current == null) return;

    final section = current.currentSection;
    final isLastInSection =
        current.currentQuestionIndex >= section.questionCount - 1;
    final isLastSection =
        current.currentSectionIndex >= current.meta.sections.length - 1;

    if (!isLastInSection) {
      state = AsyncData(current.copyWith(
        currentQuestionIndex: current.currentQuestionIndex + 1,
      ));
    } else if (!isLastSection) {
      // Show section transition card
      state = AsyncData(current.copyWith(showSectionTransition: true));
    }
  }

  void advanceSection() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      currentSectionIndex: current.currentSectionIndex + 1,
      currentQuestionIndex: 0,
      showSectionTransition: false,
    ));
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<String?> submit() async {
    final current = state.valueOrNull;
    if (current == null) return null;

    state = AsyncData(current.copyWith(status: ExamSessionStatus.submitting));

    try {
      // 1. Mark attempt as submitted
      await supabase.from('exam_attempts').update({
        'status': 'submitted',
        'answers': current.currentAnswers,
        'submitted_at': DateTime.now().toIso8601String(),
        'remaining_seconds': 0,
      }).eq('id', current.attempt.id);

      // 2. Grade exam via edge function (computes scores + inserts exam_results row)
      try {
        await supabase.functions.invoke(
          'grade-exam',
          body: {'attempt_id': current.attempt.id},
        );
      } catch (_) {
        // Non-fatal: result screen will show loading state until function is live
      }

      // 3. Clear offline buffer
      _clearBufferedAnswers(current.attempt.id);

      state = AsyncData(current.copyWith(status: ExamSessionStatus.submitted));
      return current.attempt.id;
    } catch (e) {
      state = AsyncData(current.copyWith(
        status: ExamSessionStatus.ready,
        errorMessage: 'Nộp bài thất bại. Vui lòng thử lại.',
      ));
      return null;
    }
  }

  // ── Timer sync ────────────────────────────────────────────────────────────

  void updateRemainingSeconds(int seconds) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      attempt: current.attempt.copyWith(remainingSeconds: seconds),
    ));
  }

  // ── Autosave ──────────────────────────────────────────────────────────────

  void _scheduleAutosave(
    String attemptId,
    Map<String, String> answers,
    int? remainingSeconds,
  ) {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDebounce, () {
      _doAutosave(attemptId, answers, remainingSeconds);
    });
  }

  Future<void> _doAutosave(
    String attemptId,
    Map<String, String> answers,
    int? remainingSeconds,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(autosaveStatus: AutosaveStatus.saving));
    try {
      await supabase.from('exam_attempts').update({
        'answers': answers,
        if (remainingSeconds != null)
          'remaining_seconds': remainingSeconds,
      }).eq('id', attemptId);

      _clearBufferedAnswers(attemptId);

      state = AsyncData(
        (state.valueOrNull ?? current).copyWith(
            autosaveStatus: AutosaveStatus.saved),
      );
      // Reset to idle after 2s
      await Future.delayed(const Duration(seconds: 2));
      state = AsyncData(
        (state.valueOrNull ?? current).copyWith(
            autosaveStatus: AutosaveStatus.idle),
      );
    } catch (_) {
      // Buffer to prefs for offline resilience
      _bufferAnswers(attemptId, answers);
      state = AsyncData(
        (state.valueOrNull ?? current).copyWith(
            autosaveStatus: AutosaveStatus.failed),
      );
    }
  }

  // ── Prefs buffer ──────────────────────────────────────────────────────────

  Map<String, String> _loadBufferedAnswers(String attemptId) {
    try {
      final raw = PrefsStorage.instance.prefs
          .getString('$_prefsPrefix$attemptId');
      if (raw == null) return {};
      return Map<String, String>.from(
          Uri.splitQueryString(raw).map((k, v) => MapEntry(k, v)));
    } catch (_) {
      return {};
    }
  }

  void _bufferAnswers(String attemptId, Map<String, String> answers) {
    try {
      final encoded =
          answers.entries.map((e) => '${e.key}=${e.value}').join('&');
      PrefsStorage.instance.prefs
          .setString('$_prefsPrefix$attemptId', encoded);
    } catch (_) {}
  }

  void _clearBufferedAnswers(String attemptId) {
    try {
      PrefsStorage.instance.prefs.remove('$_prefsPrefix$attemptId');
    } catch (_) {}
  }
}

// ── Timer notifier ────────────────────────────────────────────────────────────

@riverpod
class ExamTimerNotifier extends _$ExamTimerNotifier {
  Timer? _ticker;

  @override
  int build(int initialSeconds) {
    ref.onDispose(() => _ticker?.cancel());
    return initialSeconds;
  }

  void start(void Function() onExpired) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state > 0) {
        state = state - 1;
      } else {
        _ticker?.cancel();
        onExpired();
      }
    });
  }

  void pause() => _ticker?.cancel();

  void updateFromServer(int seconds) => state = seconds;
}
