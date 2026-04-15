import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

enum QuestionType { mcq, fillBlank, matching, ordering, speaking, writing }

enum SkillArea { reading, listening, writing, speaking, vocabulary, grammar }

enum Difficulty { beginner, intermediate, advanced }

@freezed
class Question with _$Question {
  const factory Question({
    required String id,
    required QuestionType type,
    required SkillArea skill,
    required Difficulty difficulty,
    required String prompt,               // question text (may contain {blank})
    String? audioUrl,                     // for listening questions
    String? imageUrl,                     // for reading exhibit questions
    @Default([]) List<QuestionOption> options,   // MCQ options
    @Default([]) List<MatchPair> matchPairs,     // matching pairs
    @Default([]) List<String> orderItems,        // ordering items
    String? correctAnswer,                // fill-blank / speaking rubric
    required String explanation,          // shown post-answer
    @Default(0) int points,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}

@freezed
class QuestionOption with _$QuestionOption {
  const factory QuestionOption({
    required String id,
    required String text,
    String? imageUrl,
    @Default(false) bool isCorrect,
  }) = _QuestionOption;

  factory QuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionFromJson(json);
}

@freezed
class MatchPair with _$MatchPair {
  const factory MatchPair({
    required String leftId,
    required String leftText,
    required String rightId,
    required String rightText,
  }) = _MatchPair;

  factory MatchPair.fromJson(Map<String, dynamic> json) =>
      _$MatchPairFromJson(json);
}

/// User's answer for a single question in a session
@freezed
class QuestionAnswer with _$QuestionAnswer {
  const factory QuestionAnswer({
    required String questionId,
    String? selectedOptionId,
    String? writtenAnswer,
    @Default([]) List<String> selectedOptionIds,
    @Default([]) List<String> orderedIds,
    @Default({}) Map<String, String> matchedPairs, // leftId → rightId
    @Default(false) bool isFlagged,
    int? timeSpentSeconds,
  }) = _QuestionAnswer;

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnswerFromJson(json);
}
