import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum WritingFeedbackStatus { idle, submitting, pending, scoring, completed, error }

class WritingMetric {
  const WritingMetric({
    required this.label,
    required this.score,
    required this.maxScore,
    this.feedback,
  });

  final String label;
  final double score;
  final double maxScore;
  final String? feedback;

  double get fraction => maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0;
}

/// A span of annotated text — either clean or marked with an issue.
class AnnotatedSpan {
  const AnnotatedSpan({
    required this.text,
    this.issueType,
    this.correction,
    this.explanation,
  });

  final String text;
  final String? issueType; // 'grammar' | 'vocabulary' | 'spelling' | null
  final String? correction;
  final String? explanation;

  bool get hasIssue => issueType != null;
}

class WritingFeedbackResult {
  const WritingFeedbackResult({
    required this.attemptId,
    required this.totalScore,
    required this.maxScore,
    required this.metrics,
    required this.originalText,
    required this.annotatedSpans,
    required this.correctedVersion,
    required this.overallFeedback,
  });

  final String attemptId;
  final double totalScore;
  final double maxScore;
  final List<WritingMetric> metrics;
  final String originalText;
  final List<AnnotatedSpan> annotatedSpans;
  final String correctedVersion;
  final String overallFeedback;

  double get fraction =>
      maxScore > 0 ? (totalScore / maxScore).clamp(0.0, 1.0) : 0;
}

class WritingSessionState {
  const WritingSessionState({
    this.status = WritingFeedbackStatus.idle,
    this.attemptId,
    this.result,
    this.errorMessage,
    this.pollCount = 0,
  });

  final WritingFeedbackStatus status;
  final String? attemptId;
  final WritingFeedbackResult? result;
  final String? errorMessage;
  final int pollCount;

  WritingSessionState copyWith({
    WritingFeedbackStatus? status,
    String? attemptId,
    WritingFeedbackResult? result,
    String? errorMessage,
    int? pollCount,
  }) =>
      WritingSessionState(
        status: status ?? this.status,
        attemptId: attemptId ?? this.attemptId,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
        pollCount: pollCount ?? this.pollCount,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class WritingSessionNotifier extends StateNotifier<WritingSessionState> {
  WritingSessionNotifier() : super(const WritingSessionState());

  static const _maxRetries = 10;
  static const _pollInterval = Duration(seconds: 3);

  Future<void> submitWriting({
    required String text,
    required String questionId,
    required String lessonId,
  }) async {
    if (state.status == WritingFeedbackStatus.submitting) return;
    state = state.copyWith(status: WritingFeedbackStatus.submitting);

    try {
      String? attemptId;

      // Try edge function
      try {
        final response = await supabase.functions.invoke(
          'writing-submit',
          body: {
            'text': text,
            'question_id': questionId,
            'lesson_id': lessonId,
          },
        );
        final data = response.data as Map<String, dynamic>?;
        attemptId = data?['attempt_id'] as String?;
      } catch (_) {
        // Edge function not deployed — insert directly
      }

      if (attemptId == null) {
        final userId = supabase.auth.currentUser?.id;
        final row = await supabase
            .from('writing_attempts')
            .insert({
              'question_id': questionId,
              'lesson_id': lessonId,
              if (userId != null) 'user_id': userId,
              'original_text': text,
              'status': 'pending',
            })
            .select()
            .maybeSingle();
        if (row != null) attemptId = (row as Map)['id'] as String;
      }

      state = state.copyWith(
        status: WritingFeedbackStatus.pending,
        attemptId: attemptId,
      );

      if (attemptId != null) {
        _startPolling(attemptId, originalText: text);
      } else {
        state = state.copyWith(
          status: WritingFeedbackStatus.error,
          errorMessage: 'Không thể tạo bài nộp.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: WritingFeedbackStatus.error,
        errorMessage: 'Không thể nộp bài viết. Vui lòng thử lại.',
      );
    }
  }

  void _startPolling(String attemptId, {required String originalText}) async {
    int count = 0;
    while (mounted && count < _maxRetries) {
      await Future.delayed(_pollInterval);
      if (!mounted) return;
      count++;

      state = state.copyWith(
        status: WritingFeedbackStatus.scoring,
        pollCount: count,
      );

      final result = await _poll(attemptId, originalText: originalText);
      if (result != null) {
        state = state.copyWith(
          status: WritingFeedbackStatus.completed,
          result: result,
        );
        return;
      }
    }

    if (mounted && state.status != WritingFeedbackStatus.completed) {
      state = state.copyWith(
        status: WritingFeedbackStatus.error,
        errorMessage: 'Hết thời gian chờ chấm điểm. Vui lòng thử lại.',
      );
    }
  }

  Future<WritingFeedbackResult?> _poll(String attemptId,
      {required String originalText}) async {
    // Try edge function
    try {
      final response = await supabase.functions
          .invoke('writing-result', body: {'attempt_id': attemptId});
      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['status'] == 'pending') return null;
      if (data['status'] == 'error') {
        state = state.copyWith(
          status: WritingFeedbackStatus.error,
          errorMessage: data['message'] as String? ?? 'Lỗi chấm điểm.',
        );
        return null;
      }
      return _parseEdgeResponse(attemptId, data, originalText);
    } catch (_) {}

    // Fallback: check writing_attempts table
    try {
      final row = await supabase
          .from('writing_attempts')
          .select()
          .eq('id', attemptId)
          .maybeSingle();
      if (row == null) return null;
      final rm = Map<String, dynamic>.from(row as Map);
      final status = rm['status'] as String? ?? 'pending';
      if (status == 'completed') return _parseRow(attemptId, rm, originalText);
      if (status == 'error') {
        state = state.copyWith(
          status: WritingFeedbackStatus.error,
          errorMessage: 'Không thể chấm điểm bài viết.',
        );
      }
    } catch (_) {}
    return null;
  }

  WritingFeedbackResult _parseEdgeResponse(
      String attemptId, Map<String, dynamic> data, String originalText) {
    final metricsRaw = data['metrics'] as List<dynamic>? ?? [];
    final metrics = metricsRaw.map((m) {
      final mm = Map<String, dynamic>.from(m as Map);
      return WritingMetric(
        label: mm['label'] as String? ?? '',
        score: (mm['score'] as num?)?.toDouble() ?? 0,
        maxScore: (mm['max_score'] as num?)?.toDouble() ?? 10,
        feedback: mm['feedback'] as String?,
      );
    }).toList();

    final spansRaw = data['annotated_spans'] as List<dynamic>? ?? [];
    final spans = spansRaw.isEmpty
        ? [AnnotatedSpan(text: originalText)]
        : spansRaw.map((s) {
            final sm = Map<String, dynamic>.from(s as Map);
            return AnnotatedSpan(
              text: sm['text'] as String? ?? '',
              issueType: sm['issue_type'] as String?,
              correction: sm['correction'] as String?,
              explanation: sm['explanation'] as String?,
            );
          }).toList();

    return WritingFeedbackResult(
      attemptId: attemptId,
      totalScore: (data['total_score'] as num?)?.toDouble() ?? 0,
      maxScore: (data['max_score'] as num?)?.toDouble() ?? 100,
      metrics: metrics,
      originalText: originalText,
      annotatedSpans: spans,
      correctedVersion: data['corrected_version'] as String? ?? '',
      overallFeedback: data['overall_feedback'] as String? ?? '',
    );
  }

  WritingFeedbackResult _parseRow(
      String attemptId, Map<String, dynamic> row, String originalText) {
    final scoreRaw = row['score'] as num?;
    final corrected = row['corrected_text'] as String? ?? '';
    final feedback = row['feedback'] as String? ?? '';

    return WritingFeedbackResult(
      attemptId: attemptId,
      totalScore: scoreRaw?.toDouble() ?? 0,
      maxScore: 100,
      metrics: [],
      originalText: originalText,
      annotatedSpans: [AnnotatedSpan(text: originalText)],
      correctedVersion: corrected,
      overallFeedback: feedback,
    );
  }

  void retry() => state = const WritingSessionState();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final writingSessionProvider = StateNotifierProvider.autoDispose<
    WritingSessionNotifier, WritingSessionState>(
  (_) => WritingSessionNotifier(),
);
