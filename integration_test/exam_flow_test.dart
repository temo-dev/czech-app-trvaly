import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/bootstrap.dart';
import 'helpers/test_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Exam flow — staging', () {
    testWidgets(
      'guest exam saves question-centric answers, grades result, and links rows after signup',
      (tester) async {
        await pumpRealApp(tester);
        final robot = AppRobot(tester);
        final preferredExam = await _pickPreferredExam();

        if (preferredExam != null) {
          await robot.goToPath('${AppRoutes.mockTestIntro}?examId=$preferredExam');
        }

        await robot.tapStartExam();

        final attemptId = (await _waitForLatestAnonymousAttemptId())!;
        final orderedQuestions = await _loadAttemptQuestions(attemptId);
        final firstObjectiveIndex = orderedQuestions.indexWhere(
          (question) => question.type == 'mcq' || question.type == 'fill_blank',
        );
        final firstWritingIndex = orderedQuestions.indexWhere(
          (question) => question.type == 'writing',
        );
        final firstSpeakingQuestionId = _firstQuestionIdForType(
          orderedQuestions,
          'speaking',
        );
        final hasWriting = firstWritingIndex >= 0;
        final lastQuestionIndex =
            orderedQuestions.isEmpty ? 0 : orderedQuestions.length - 1;

        expect(firstObjectiveIndex, isNonNegative);

        for (var i = 0; i < firstObjectiveIndex; i++) {
          await robot.tapNextQuestion();
        }

        await robot.selectFirstOption();

        final navigationTarget = hasWriting ? firstWritingIndex : lastQuestionIndex;
        for (var i = firstObjectiveIndex; i < navigationTarget; i++) {
          await robot.tapNextQuestion();
        }

        if (hasWriting) {
          await robot.enterWritingAnswer(
            'Dobry den, sousede. Zveme vas na oslavu v sobotu v 18 hodin u nas doma. '
            'Bude pizza, dort a caj. Prosim, prineste si dobrou naladu.',
          );
        }

        if (firstSpeakingQuestionId != null) {
          await supabase.from('ai_speaking_attempts').insert({
            'question_id': firstSpeakingQuestionId,
            'exam_attempt_id': attemptId,
            'audio_key': 'e2e/mock-speaking.m4a',
            'status': 'ready',
            'overall_score': 82,
            'metrics': {
              'pronunciation': 80,
              'pronunciation_feedback': 'Mock pronunciation feedback',
              'fluency': 82,
              'fluency_feedback': 'Mock fluency feedback',
              'vocabulary': 83,
              'vocabulary_feedback': 'Mock vocabulary feedback',
              'task_achievement': 84,
              'content_feedback': 'Mock content feedback',
              'overall_feedback': 'Mock overall feedback',
              'short_tips': ['Mock tip'],
            },
            'transcript': 'Mock transcript',
            'corrected_answer': 'Mock corrected answer',
          });
        }

        await robot.tapSubmitExam();
        await robot.confirmSubmit();

        expect(
            find.byKey(const Key('mock_exam_result_screen')), findsOneWidget);

        final attemptRow = await supabase
            .from('exam_attempts')
            .select('status, answers')
            .eq('id', attemptId)
            .single();
        final answers = Map<String, dynamic>.from(attemptRow['answers'] as Map);
        expect(attemptRow['status'], 'submitted');
        expect(answers.keys.any((key) => key.startsWith('q_')), isFalse);
        expect(
          answers.values.any(
            (value) => value is Map && value.containsKey('selected_option_id'),
          ),
          isTrue,
        );
        expect(
          answers.values.any(
            (value) => value is Map && value.containsKey('written_answer'),
          ),
          hasWriting,
        );
        if (hasWriting) {
          expect(
            answers.values.any(
              (value) => value is Map && value.containsKey('ai_attempt_id'),
            ),
            isTrue,
          );
        }

        final resultRow = await supabase
            .from('exam_results')
            .select('attempt_id, total_score, section_scores')
            .eq('attempt_id', attemptId)
            .single();
        final sectionScores =
            Map<String, dynamic>.from(resultRow['section_scores'] as Map);
        expect(resultRow['attempt_id'], attemptId);
        expect(resultRow['total_score'], isA<int>());
        expect(sectionScores.containsKey('writing'), hasWriting);
        if (firstSpeakingQuestionId != null) {
          expect(sectionScores.containsKey('speaking'), isTrue);
        }

        final email =
            'e2e.exam.${DateTime.now().millisecondsSinceEpoch}@staging.test';
        const password = 'Test1234!';

        await robot.tapResultSignup();
        await robot.fillSignupForm(
          email: email,
          password: password,
          displayName: 'Exam E2E',
        );
        await robot.agreeToTerms();
        await robot.tapSignupButton();
        await robot.expectOnDashboard();

        final linkedAttempt = await _waitForAttemptOwner(attemptId);
        final linkedResult = await _waitForResultOwner(attemptId);
        final linkedWritingAttempt = hasWriting
            ? await _waitForWritingAttempt(attemptId, requireUserId: true)
            : null;
        final linkedSpeakingAttempt = firstSpeakingQuestionId == null
            ? null
            : await _waitForSpeakingAttempt(attemptId, requireUserId: true);

        expect(linkedAttempt?['user_id'], isNotNull);
        expect(linkedResult?['user_id'], isNotNull);
        if (hasWriting) {
          expect(linkedWritingAttempt?['user_id'], isNotNull);
        }
        if (firstSpeakingQuestionId != null) {
          expect(linkedSpeakingAttempt?['user_id'], isNotNull);
        }
      },
    );
  });
}

Future<String?> _pickPreferredExam() async {
  final examsData = await supabase.from('exams').select('id').order('created_at');
  String? writingOnlyExamId;

  for (final raw in examsData as List) {
    final examId = (raw as Map)['id'] as String?;
    if (examId == null) continue;

    final questions = await _loadQuestionsForExam(examId);
    final hasWriting =
        questions.any((question) => question.type == 'writing');
    final hasSpeaking =
        questions.any((question) => question.type == 'speaking');

    if (hasWriting && hasSpeaking) {
      return examId;
    }
    if (hasWriting && writingOnlyExamId == null) {
      writingOnlyExamId = examId;
    }
  }

  return writingOnlyExamId;
}

Future<String?> _waitForLatestAnonymousAttemptId() async {
  for (var i = 0; i < 10; i++) {
    final row = await supabase
        .from('exam_attempts')
        .select('id')
        .isFilter('user_id', null)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row != null) {
      return row['id'] as String;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  return null;
}

class _ExamQuestionRow {
  const _ExamQuestionRow({
    required this.id,
    required this.type,
  });

  final String id;
  final String type;
}

String? _firstQuestionIdForType(
  List<_ExamQuestionRow> questions,
  String type,
) {
  for (final question in questions) {
    if (question.type == type) {
      return question.id;
    }
  }
  return null;
}

Future<List<_ExamQuestionRow>> _loadAttemptQuestions(String attemptId) async {
  final attempt = await supabase
      .from('exam_attempts')
      .select('exam_id')
      .eq('id', attemptId)
      .single();
  final examId = attempt['exam_id'] as String;
  return _loadQuestionsForExam(examId);
}

Future<List<_ExamQuestionRow>> _loadQuestionsForExam(String examId) async {
  final sectionsData = await supabase
      .from('exam_sections')
      .select('id')
      .eq('exam_id', examId)
      .order('order_index');
  final sectionIds =
      (sectionsData as List).map((row) => row['id'] as String).toList();
  if (sectionIds.isEmpty) {
    return const [];
  }

  final questionsData = await supabase
      .from('questions')
      .select('id, type, section_id, order_index')
      .inFilter('section_id', sectionIds)
      .order('order_index');

  final bySection = <String, List<Map<String, dynamic>>>{};
  for (final raw in questionsData as List) {
    final row = Map<String, dynamic>.from(raw as Map);
    final sectionId = row['section_id'] as String;
    bySection.putIfAbsent(sectionId, () => []).add(row);
  }

  final ordered = <_ExamQuestionRow>[];
  for (final sectionId in sectionIds) {
    final rows = List<Map<String, dynamic>>.from(
      bySection[sectionId] ?? const <Map<String, dynamic>>[],
    );
    rows.sort(
      (a, b) => ((a['order_index'] as num?)?.toInt() ?? 0)
          .compareTo((b['order_index'] as num?)?.toInt() ?? 0),
    );
    ordered.addAll(
      rows.map(
        (row) => _ExamQuestionRow(
          id: row['id'] as String,
          type: row['type'] as String? ?? 'mcq',
        ),
      ),
    );
  }

  return ordered;
}

Future<Map<String, dynamic>?> _waitForWritingAttempt(
  String attemptId, {
  bool requireUserId = false,
}) async {
  for (var i = 0; i < 10; i++) {
    final row = await supabase
        .from('ai_writing_attempts')
        .select('id, user_id, exam_attempt_id')
        .eq('exam_attempt_id', attemptId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row != null) {
      final mapped = Map<String, dynamic>.from(row as Map);
      if (!requireUserId || mapped['user_id'] != null) {
        return mapped;
      }
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  return null;
}

Future<Map<String, dynamic>?> _waitForSpeakingAttempt(
  String attemptId, {
  bool requireUserId = false,
}) async {
  for (var i = 0; i < 10; i++) {
    final row = await supabase
        .from('ai_speaking_attempts')
        .select('id, user_id, exam_attempt_id')
        .eq('exam_attempt_id', attemptId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row != null) {
      final mapped = Map<String, dynamic>.from(row as Map);
      if (!requireUserId || mapped['user_id'] != null) {
        return mapped;
      }
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  return null;
}

Future<Map<String, dynamic>?> _waitForAttemptOwner(String attemptId) async {
  for (var i = 0; i < 10; i++) {
    final row = await supabase
        .from('exam_attempts')
        .select('id, user_id')
        .eq('id', attemptId)
        .maybeSingle();
    if (row != null) {
      final mapped = Map<String, dynamic>.from(row as Map);
      if (mapped['user_id'] != null) {
        return mapped;
      }
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  return null;
}

Future<Map<String, dynamic>?> _waitForResultOwner(String attemptId) async {
  for (var i = 0; i < 10; i++) {
    final row = await supabase
        .from('exam_results')
        .select('attempt_id, user_id')
        .eq('attempt_id', attemptId)
        .maybeSingle();
    if (row != null) {
      final mapped = Map<String, dynamic>.from(row as Map);
      if (mapped['user_id'] != null) {
        return mapped;
      }
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  return null;
}
