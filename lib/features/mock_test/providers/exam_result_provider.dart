import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/core/storage/prefs_storage.dart';
import 'package:app_czech/shared/models/question_model.dart';
import '../models/mock_test_result.dart';
import 'exam_questions_provider.dart';

part 'exam_result_provider.g.dart';

@riverpod
Future<MockTestResult> examResult(ExamResultRef ref, String attemptId) async {
  final data = await supabase
      .from('exam_results')
      .select()
      .eq('attempt_id', attemptId)
      .order('created_at', ascending: false)
      .limit(1)
      .single();

  final raw = Map<String, dynamic>.from(data as Map);

  // Parse section_scores: { skill: { score, total } }
  final rawSections =
      (raw['section_scores'] as Map<String, dynamic>?) ?? {};
  final sectionScores = rawSections.map(
    (k, v) => MapEntry(
      k,
      SectionResult.fromJson(Map<String, dynamic>.from(v as Map)),
    ),
  );

  // Parse weak_skills: stored as List in Postgres
  final rawWeak = raw['weak_skills'];
  final weakSkills = rawWeak is List
      ? List<String>.from(rawWeak)
      : <String>[];

  return MockTestResult(
    id: raw['id'] as String,
    attemptId: raw['attempt_id'] as String,
    userId: raw['user_id'] as String?,
    totalScore: raw['total_score'] as int? ?? 0,
    passThreshold: raw['pass_threshold'] as int? ?? 60,
    sectionScores: sectionScores,
    weakSkills: weakSkills,
    aiGradingPending: raw['ai_grading_pending'] as bool? ?? false,
    createdAt: DateTime.parse(raw['created_at'] as String),
  );
}

/// Links an anonymous attempt to the newly authenticated user.
/// Called right after a successful signup if a pendingAttemptId exists.
Future<void> linkPendingAttempt(String userId) async {
  final pendingId = PrefsStorage.instance.pendingAttemptId;
  if (pendingId == null) return;

  try {
    await supabase
        .from('exam_attempts')
        .update({'user_id': userId})
        .eq('id', pendingId)
        .isFilter('user_id', null); // only link if still anonymous

    await supabase
        .from('exam_results')
        .update({'user_id': userId})
        .eq('attempt_id', pendingId)
        .isFilter('user_id', null);

    await PrefsStorage.instance.clearPendingAttemptId();
  } catch (_) {
    // Non-fatal: attempt stays anonymous, user can still see result
  }
}

/// Fetches the examId for a given attemptId from exam_attempts.
/// No codegen needed — uses classic Riverpod family API.
final attemptExamIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, attemptId) async {
  try {
    final row = await supabase
        .from('exam_attempts')
        .select('exam_id')
        .eq('id', attemptId)
        .single();
    return row['exam_id'] as String?;
  } catch (_) {
    return null;
  }
});

// ── Review ─────────────────────────────────────────────────────────────────────

class QuestionReviewItem {
  const QuestionReviewItem({
    required this.number,
    required this.globalIndex,
    required this.question,
    required this.sectionSkill,
    required this.sectionLabel,
    this.userAnswer,
    required this.isCorrect,
    required this.isAnswered,
    this.selectedOption,
    this.correctOption,
  });

  final int number;
  final int globalIndex;
  final Question question;
  final String sectionSkill;   // 'reading' | 'listening' | 'writing' | 'speaking'
  final String sectionLabel;
  final String? userAnswer;    // optionId for MCQ, free text for writing/speaking/fillBlank
  final bool isCorrect;
  final bool isAnswered;
  final QuestionOption? selectedOption;
  final QuestionOption? correctOption;
}

@riverpod
Future<List<QuestionReviewItem>> examReview(
    ExamReviewRef ref, String attemptId) async {
  // 1. Fetch attempt answers + examId
  final attemptRow = await supabase
      .from('exam_attempts')
      .select('exam_id, answers')
      .eq('id', attemptId)
      .single();

  final examId = attemptRow['exam_id'] as String;
  final rawAnswers =
      (attemptRow['answers'] as Map<String, dynamic>?) ?? {};
  // Answers are keyed as 'q_0', 'q_1', ... (global index during exam session)
  final answers = rawAnswers.map((k, v) => MapEntry(k, v.toString()));

  // 2. Fetch sections to know skill per question (sections are ordered by order_index)
  final sectionsData = await supabase
      .from('exam_sections')
      .select('id, skill, label, question_count')
      .eq('exam_id', examId)
      .order('order_index');

  final sections = (sectionsData as List).map((s) => (
        id: s['id'] as String,
        skill: s['skill'] as String? ?? 'reading',
        label: s['label'] as String? ?? '',
        count: (s['question_count'] as num?)?.toInt() ?? 0,
      )).toList();

  // Build section boundary map: globalIndex → (skill, label)
  final sectionForIndex = <int, ({String skill, String label})>{};
  var offset = 0;
  for (final sec in sections) {
    for (var j = 0; j < sec.count; j++) {
      sectionForIndex[offset + j] = (skill: sec.skill, label: sec.label);
    }
    offset += sec.count;
  }

  // 3. Fetch questions (flat, in section order)
  final questions = await ref.watch(examQuestionsProvider(examId).future);

  // 4. Build review items
  return questions.asMap().entries.map((entry) {
    final i = entry.key;
    final q = entry.value;
    // Answer key matches ExamSessionNotifier.answer() which uses 'q_$globalIdx'
    final userAnswer = answers['q_$i'];
    final isAnswered = userAnswer != null && userAnswer.isNotEmpty;
    final sec = sectionForIndex[i] ?? (skill: q.skill.name, label: '');

    QuestionOption? selectedOption;
    QuestionOption? correctOption;
    bool isCorrect = false;

    if (q.options.isNotEmpty) {
      correctOption = q.options.where((o) => o.isCorrect).firstOrNull;
    }

    if (q.type == QuestionType.mcq) {
      if (isAnswered) {
        selectedOption =
            q.options.where((o) => o.id == userAnswer).firstOrNull;
      }
      isCorrect = selectedOption?.isCorrect ?? false;
    } else if (q.type == QuestionType.fillBlank) {
      isCorrect = isAnswered &&
          userAnswer.toLowerCase().trim() ==
              (q.correctAnswer ?? '').toLowerCase().trim();
    }
    // writing/speaking: no objective correctness — isCorrect stays false

    return QuestionReviewItem(
      number: i + 1,
      globalIndex: i,
      question: q,
      sectionSkill: sec.skill,
      sectionLabel: sec.label,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      isAnswered: isAnswered,
      selectedOption: selectedOption,
      correctOption: correctOption,
    );
  }).toList();
}
