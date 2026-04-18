import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/shared/models/question_model.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class QuestionAiFeedback {
  const QuestionAiFeedback({
    required this.errorAnalysis,
    required this.correctExplanation,
    required this.shortTip,
    required this.keyConceptLabel,
  });

  final String errorAnalysis;
  final String correctExplanation;
  final String shortTip;
  final String keyConceptLabel;
}

class QuestionFeedbackParams {
  const QuestionFeedbackParams({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswerText,
    required this.userAnswerText,
    required this.sectionSkill,
  });

  final String questionId;
  final String questionText;
  final List<QuestionOption> options;
  final String correctAnswerText;
  final String userAnswerText;
  final String sectionSkill;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionFeedbackParams &&
          questionId == other.questionId &&
          userAnswerText == other.userAnswerText;

  @override
  int get hashCode => Object.hash(questionId, userAnswerText);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class QuestionFeedbackNotifier
    extends AutoDisposeFamilyAsyncNotifier<QuestionAiFeedback?, QuestionFeedbackParams> {
  @override
  Future<QuestionAiFeedback?> build(QuestionFeedbackParams arg) async {
    return null; // lazy — only fetch when explicitly called
  }

  Future<void> fetchFeedback() async {
    if (state is AsyncLoading) return;
    state = const AsyncLoading();

    try {
      final params = arg;
      final optionsList = params.options
          .map((o) => {'id': o.id, 'text': o.text})
          .toList();

      final response = await supabase.functions.invoke(
        'question-feedback',
        body: {
          'question_text': params.questionText,
          'options': optionsList,
          'correct_answer_text': params.correctAnswerText,
          'user_answer_text': params.userAnswerText,
          'section_skill': params.sectionSkill,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        state = AsyncData(null);
        return;
      }

      state = AsyncData(QuestionAiFeedback(
        errorAnalysis: data['error_analysis'] as String? ?? '',
        correctExplanation: data['correct_explanation'] as String? ?? '',
        shortTip: data['short_tip'] as String? ?? '',
        keyConceptLabel: data['key_concept'] as String? ?? '',
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final questionFeedbackProvider = AsyncNotifierProvider.autoDispose
    .family<QuestionFeedbackNotifier, QuestionAiFeedback?, QuestionFeedbackParams>(
  QuestionFeedbackNotifier.new,
);
