import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/mock_test/models/mock_test_result.dart';

void main() {
  group('MockTestResult.fromJson', () {
    late Map<String, dynamic> validJson;

    setUpAll(() {
      validJson = jsonDecode(
        File('test/helpers/fixtures/exam_result.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('parses fields correctly', () {
      final result = MockTestResult.fromJson(validJson);

      expect(result.id, 'result-001');
      expect(result.attemptId, 'attempt-001');
      expect(result.userId, 'user-001');
      expect(result.totalScore, 75);
      expect(result.passThreshold, 60);
      expect(result.weakSkills, contains('listening'));
    });

    test('parses sectionScores map', () {
      final result = MockTestResult.fromJson(validJson);

      expect(result.sectionScores, hasLength(3));
      expect(result.sectionScores['reading']?.score, 80);
      expect(result.sectionScores['reading']?.total, 100);
    });

    test('parses createdAt as DateTime', () {
      final result = MockTestResult.fromJson(validJson);
      expect(result.createdAt, isA<DateTime>());
      expect(result.createdAt.year, 2024);
    });

    test('userId is optional', () {
      final json = Map<String, dynamic>.from(validJson)..remove('userId');
      final result = MockTestResult.fromJson(json);
      expect(result.userId, isNull);
    });
  });

  group('MockTestResult.passed', () {
    MockTestResult makeResult(int score, int threshold) =>
        MockTestResult.fromJson({
          'id': 'r',
          'attemptId': 'a',
          'totalScore': score,
          'passThreshold': threshold,
          'createdAt': '2024-01-01T00:00:00.000Z',
        });

    test('passes when score >= threshold', () {
      expect(makeResult(60, 60).passed, isTrue);
      expect(makeResult(85, 60).passed, isTrue);
      expect(makeResult(100, 60).passed, isTrue);
    });

    test('fails when score < threshold', () {
      expect(makeResult(59, 60).passed, isFalse);
      expect(makeResult(0, 60).passed, isFalse);
    });
  });

  group('MockTestResult.band', () {
    MockTestResult makeResult(int score) => MockTestResult.fromJson({
          'id': 'r',
          'attemptId': 'a',
          'totalScore': score,
          'passThreshold': 60,
          'createdAt': '2024-01-01T00:00:00.000Z',
        });

    test('excellent at 85+', () => expect(makeResult(85).band, ScoreBand.excellent));
    test('excellent at 100', () => expect(makeResult(100).band, ScoreBand.excellent));
    test('good at 70-84', () {
      expect(makeResult(70).band, ScoreBand.good);
      expect(makeResult(84).band, ScoreBand.good);
    });
    test('fair at 50-69', () {
      expect(makeResult(50).band, ScoreBand.fair);
      expect(makeResult(69).band, ScoreBand.fair);
    });
    test('poor below 50', () {
      expect(makeResult(49).band, ScoreBand.poor);
      expect(makeResult(0).band, ScoreBand.poor);
    });
  });

  group('SectionResult', () {
    test('percentage calculates correctly', () {
      const sr = SectionResult(score: 80, total: 100);
      expect(sr.percentage, closeTo(0.80, 0.001));
    });

    test('percentage is 0 when total is 0', () {
      const sr = SectionResult(score: 0, total: 0);
      expect(sr.percentage, 0);
    });
  });
}
