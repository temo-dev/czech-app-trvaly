import 'package:app_czech/core/storage/prefs_storage.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/features/mock_test/models/exam_question_answer.dart';
import 'package:app_czech/features/mock_test/models/mock_test_result.dart';
import 'package:app_czech/shared/models/question_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'exam_questions_provider.dart';

part 'exam_result_provider.g.dart';

const _resultPollRetries = 15;
const _resultPollInterval = Duration(seconds: 1);

@riverpod
Future<MockTestResult> examResult(ExamResultRef ref, String attemptId) async {
  Map<String, dynamic>? raw;

  for (var i = 0; i < _resultPollRetries; i++) {
    final data = await supabase
        .from('exam_results')
        .select()
        .eq('attempt_id', attemptId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data != null) {
      raw = Map<String, dynamic>.from(data as Map);
      break;
    }

    if (i < _resultPollRetries - 1) {
      await Future.delayed(_resultPollInterval);
    }
  }

  if (raw == null) {
    throw StateError('Exam result not ready yet.');
  }

  final rawSections = (raw['section_scores'] as Map<String, dynamic>?) ?? {};
  final sectionScores = rawSections.map(
    (key, value) => MapEntry(
      key,
      SectionResult.fromJson(Map<String, dynamic>.from(value as Map)),
    ),
  );

  final rawWeak = raw['weak_skills'];
  final weakSkills = rawWeak is List ? List<String>.from(rawWeak) : <String>[];

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

Future<void> linkPendingAttempt(String userId) async {
  final pendingId = PrefsStorage.instance.pendingAttemptId;
  if (pendingId == null) return;

  try {
    await supabase
        .from('exam_attempts')
        .update({'user_id': userId, 'guest_token': null})
        .eq('id', pendingId)
        .isFilter('user_id', null);

    await supabase
        .from('exam_results')
        .update({'user_id': userId, 'guest_token': null})
        .eq('attempt_id', pendingId)
        .isFilter('user_id', null);

    await supabase
        .from('ai_speaking_attempts')
        .update({'user_id': userId, 'guest_token': null})
        .eq('exam_attempt_id', pendingId)
        .isFilter('user_id', null);

    await supabase
        .from('ai_writing_attempts')
        .update({'user_id': userId, 'guest_token': null})
        .eq('exam_attempt_id', pendingId)
        .isFilter('user_id', null);

    await supabase
        .from('ai_teacher_reviews')
        .update({'user_id': userId, 'guest_token': null})
        .eq('exam_attempt_id', pendingId)
        .isFilter('user_id', null);

    await supabase
        .from('exam_analysis')
        .update({'user_id': userId, 'guest_token': null})
        .eq('attempt_id', pendingId)
        .isFilter('user_id', null);

    await PrefsStorage.instance.clearPendingAttemptId();
  } catch (_) {
    // Non-fatal: attempt stays anonymous, user can still see result.
  }
}

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

class QuestionReviewItem {
  const QuestionReviewItem({
    required this.attemptId,
    required this.number,
    required this.globalIndex,
    required this.question,
    required this.sectionSkill,
    required this.sectionLabel,
    this.userAnswer,
    this.aiAttemptId,
    required this.isCorrect,
    required this.isAnswered,
    this.selectedOption,
    this.correctOption,
  });

  final String attemptId;
  final int number;
  final int globalIndex;
  final Question question;
  final String sectionSkill;
  final String sectionLabel;
  final String? userAnswer;
  final String? aiAttemptId;
  final bool isCorrect;
  final bool isAnswered;
  final QuestionOption? selectedOption;
  final QuestionOption? correctOption;
}

@riverpod
Future<List<QuestionReviewItem>> examReview(
  ExamReviewRef ref,
  String attemptId,
) async {
  final attemptRow = await supabase
      .from('exam_attempts')
      .select('exam_id, answers')
      .eq('id', attemptId)
      .single();

  final examId = attemptRow['exam_id'] as String;
  final rawAnswers = (attemptRow['answers'] as Map<String, dynamic>?) ?? {};

  final sectionsData = await supabase
      .from('exam_sections')
      .select('id, skill, label, question_count')
      .eq('exam_id', examId)
      .order('order_index');

  final sections = (sectionsData as List)
      .map(
        (section) => (
          id: section['id'] as String,
          skill: section['skill'] as String? ?? 'reading',
          label: section['label'] as String? ?? '',
          count: (section['question_count'] as num?)?.toInt() ?? 0,
        ),
      )
      .toList();

  final sectionForIndex = <int, ({String skill, String label})>{};
  var offset = 0;
  for (final section in sections) {
    for (var j = 0; j < section.count; j++) {
      sectionForIndex[offset + j] = (
        skill: section.skill,
        label: section.label,
      );
    }
    offset += section.count;
  }

  final questions = await ref.watch(examQuestionsProvider(examId).future);
  final answers = _restoreReviewAnswers(rawAnswers, questions);

  return questions.asMap().entries.map((entry) {
    final index = entry.key;
    final question = entry.value;
    final storedAnswer = answers[question.id];
    final userAnswer = switch (question.type) {
      QuestionType.mcq => storedAnswer?.selectedOptionId,
      QuestionType.writing ||
      QuestionType.fillBlank =>
        storedAnswer?.writtenAnswer,
      QuestionType.speaking => storedAnswer?.writtenAnswer,
      QuestionType.matching ||
      QuestionType.ordering =>
        storedAnswer?.writtenAnswer,
    };
    final isAnswered = storedAnswer?.isAnswered ?? false;
    final section = sectionForIndex[index] ??
        (
          skill: question.skill.name,
          label: '',
        );

    QuestionOption? selectedOption;
    QuestionOption? correctOption;
    var isCorrect = false;

    if (question.options.isNotEmpty) {
      correctOption =
          question.options.where((option) => option.isCorrect).firstOrNull;
    }

    if (question.type == QuestionType.mcq) {
      if (userAnswer != null) {
        selectedOption = question.options
            .where((option) => option.id == userAnswer)
            .firstOrNull;
      }
      isCorrect = selectedOption?.isCorrect ?? false;
    } else if (question.type == QuestionType.fillBlank) {
      isCorrect = userAnswer != null &&
          userAnswer.toLowerCase().trim() ==
              (question.correctAnswer ?? '').toLowerCase().trim();
    }

    return QuestionReviewItem(
      attemptId: attemptId,
      number: index + 1,
      globalIndex: index,
      question: question,
      sectionSkill: section.skill,
      sectionLabel: section.label,
      userAnswer: userAnswer,
      aiAttemptId: storedAnswer?.aiAttemptId,
      isCorrect: isCorrect,
      isAnswered: isAnswered,
      selectedOption: selectedOption,
      correctOption: correctOption,
    );
  }).toList();
}

Map<String, ExamQuestionAnswer> _restoreReviewAnswers(
  Map<String, dynamic> rawAnswers,
  List<Question> questions,
) {
  if (rawAnswers.isEmpty) return {};

  final restored = <String, ExamQuestionAnswer>{};
  final isLegacy = rawAnswers.keys.any((key) => key.startsWith('q_'));

  if (isLegacy) {
    for (final entry in questions.asMap().entries) {
      final raw = rawAnswers['q_${entry.key}'];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isEmpty) continue;

      final question = entry.value;
      restored[question.id] = switch (question.type) {
        QuestionType.mcq => ExamQuestionAnswer(
            questionId: question.id,
            selectedOptionId: value,
          ),
        QuestionType.speaking => ExamQuestionAnswer(
            questionId: question.id,
            aiAttemptId: value,
          ),
        _ => ExamQuestionAnswer(
            questionId: question.id,
            writtenAnswer: value,
          ),
      };
    }
    return restored;
  }

  for (final entry in rawAnswers.entries) {
    final answer = ExamQuestionAnswer.fromStoredJson(entry.key, entry.value);
    if (answer.isAnswered) {
      restored[entry.key] = answer;
    }
  }

  return restored;
}
