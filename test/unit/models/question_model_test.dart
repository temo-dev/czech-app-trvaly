import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/shared/models/question_model.dart';

void main() {
  group('Question.fromJson', () {
    late Map<String, dynamic> validJson;

    setUpAll(() {
      validJson = jsonDecode(
        File('test/helpers/fixtures/question.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('parses MCQ with 4 options', () {
      final q = Question.fromJson(validJson);

      expect(q.id, 'q-001');
      expect(q.type, QuestionType.mcq);
      expect(q.skill, SkillArea.grammar);
      expect(q.difficulty, Difficulty.beginner);
      expect(q.options, hasLength(4));
      expect(q.points, 10);
    });

    test('exactly one correct option', () {
      final q = Question.fromJson(validJson);
      final correct = q.options.where((o) => o.isCorrect).toList();

      expect(correct, hasLength(1));
      expect(correct.first.id, 'opt-a');
    });

    test('explanation is non-empty', () {
      final q = Question.fromJson(validJson);
      expect(q.explanation, isNotEmpty);
    });

    test('optional fields default to null/empty', () {
      final q = Question.fromJson({
        'id': 'q-minimal',
        'type': 'mcq',
        'skill': 'vocabulary',
        'difficulty': 'beginner',
        'prompt': 'Q?',
        'explanation': '',
      });

      expect(q.audioUrl, isNull);
      expect(q.imageUrl, isNull);
      expect(q.correctAnswer, isNull);
      expect(q.options, isEmpty);
      expect(q.matchPairs, isEmpty);
      expect(q.orderItems, isEmpty);
      expect(q.points, 0);
    });

    test('parses all QuestionType variants', () {
      for (final type in ['mcq', 'fillBlank', 'matching', 'ordering', 'speaking', 'writing']) {
        final q = Question.fromJson({
          'id': 'q-$type',
          'type': type,
          'skill': 'grammar',
          'difficulty': 'beginner',
          'prompt': 'Q?',
          'explanation': '',
        });
        expect(q.type, isNotNull, reason: 'Type $type should parse');
      }
    });

    test('parses all SkillArea variants', () {
      for (final skill in ['reading', 'listening', 'writing', 'speaking', 'vocabulary', 'grammar']) {
        final q = Question.fromJson({
          'id': 'q-$skill',
          'type': 'mcq',
          'skill': skill,
          'difficulty': 'beginner',
          'prompt': 'Q?',
          'explanation': '',
        });
        expect(q.skill, isNotNull, reason: 'Skill $skill should parse');
      }
    });
  });

  group('QuestionOption', () {
    test('isCorrect defaults to false', () {
      final opt = QuestionOption.fromJson({'id': 'o1', 'text': 'Answer'});
      expect(opt.isCorrect, isFalse);
    });

    test('imageUrl is optional', () {
      final opt = QuestionOption.fromJson({
        'id': 'o1',
        'text': 'Answer',
        'isCorrect': true,
      });
      expect(opt.imageUrl, isNull);
      expect(opt.isCorrect, isTrue);
    });
  });

  group('QuestionAnswer', () {
    test('copyWith preserves unchanged fields', () {
      const original = QuestionAnswer(questionId: 'q1', selectedOptionId: 'opt-a');
      final updated = original.copyWith(isFlagged: true);

      expect(updated.questionId, 'q1');
      expect(updated.selectedOptionId, 'opt-a');
      expect(updated.isFlagged, isTrue);
    });

    test('defaults are empty collections', () {
      const answer = QuestionAnswer(questionId: 'q1');
      expect(answer.selectedOptionIds, isEmpty);
      expect(answer.orderedIds, isEmpty);
      expect(answer.matchedPairs, isEmpty);
      expect(answer.isFlagged, isFalse);
    });
  });
}
