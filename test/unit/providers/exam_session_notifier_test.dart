import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/shared/models/question_model.dart';
import 'package:app_czech/features/mock_test/models/exam_question_answer.dart';
import 'package:app_czech/features/mock_test/providers/exam_session_notifier.dart';
import 'package:app_czech/features/mock_test/models/exam_meta.dart';
import 'package:app_czech/features/mock_test/models/exam_attempt.dart';
import '../../helpers/provider_factory.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _fakeAttempt = ExamAttempt.fromJson({
  'id': 'attempt-001',
  'examId': 'exam-001',
  'userId': 'user-001',
  'status': 'in_progress',
  'answers': <String, dynamic>{},
  'remainingSeconds': 3600,
});

final _fakeSection1 = SectionMeta.fromJson({
  'id': 'sec-reading',
  'skill': 'reading',
  'label': 'Đọc hiểu',
  'questionCount': 3,
  'orderIndex': 0,
});

final _fakeSection2 = SectionMeta.fromJson({
  'id': 'sec-listening',
  'skill': 'listening',
  'label': 'Nghe hiểu',
  'questionCount': 2,
  'orderIndex': 1,
});

final _fakeMeta = ExamMeta.fromJson({
  'id': 'exam-001',
  'title': 'Bài thi thử',
  'durationMinutes': 60,
  'sections': [
    _fakeSection1.toJson(),
    _fakeSection2.toJson(),
  ],
});

final _fakeInitialState = ExamSessionState(
  attempt: _fakeAttempt,
  meta: _fakeMeta,
);

const _readingQuestion = Question(
  id: 'question-reading-1',
  type: QuestionType.mcq,
  skill: SkillArea.reading,
  difficulty: Difficulty.intermediate,
  prompt: 'Prompt 1',
  explanation: 'Explanation 1',
  points: 1,
);

const _listeningQuestion = Question(
  id: 'question-listening-1',
  type: QuestionType.mcq,
  skill: SkillArea.listening,
  difficulty: Difficulty.intermediate,
  prompt: 'Prompt 2',
  explanation: 'Explanation 2',
  points: 1,
);

// ── Fake notifier — bypasses Supabase build() ─────────────────────────────────

class _FakeExamSessionNotifier extends ExamSessionNotifier {
  final ExamSessionState _initial;
  _FakeExamSessionNotifier(this._initial);

  @override
  Future<ExamSessionState> build(String attemptId) async => _initial;
}

ProviderContainer _makeContainer([ExamSessionState? initial]) {
  final state = initial ?? _fakeInitialState;
  return createContainer(overrides: [
    examSessionNotifierProvider('attempt-001').overrideWith(
      () => _FakeExamSessionNotifier(state),
    ),
  ]);
}

void main() {
  group('ExamSessionNotifier — answer()', () {
    test('records answer for question', () async {
      final container = _makeContainer();
      await container.read(examSessionNotifierProvider('attempt-001').future);

      container
          .read(examSessionNotifierProvider('attempt-001').notifier)
          .answerQuestion(
            question: _readingQuestion,
            answer: const QuestionAnswer(
              questionId: 'question-reading-1',
              selectedOptionId: 'opt-b',
            ),
          );

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(
        state.currentAnswers['question-reading-1']?.selectedOptionId,
        'opt-b',
      );
    });

    test('overrides previous answer for same question', () async {
      final container = _makeContainer();
      await container.read(examSessionNotifierProvider('attempt-001').future);

      final notifier =
          container.read(examSessionNotifierProvider('attempt-001').notifier);
      notifier.answerQuestion(
        question: _readingQuestion,
        answer: const QuestionAnswer(
          questionId: 'question-reading-1',
          selectedOptionId: 'opt-a',
        ),
      );
      notifier.answerQuestion(
        question: _readingQuestion,
        answer: const QuestionAnswer(
          questionId: 'question-reading-1',
          selectedOptionId: 'opt-c',
        ),
      );

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(
        state.currentAnswers['question-reading-1']?.selectedOptionId,
        'opt-c',
      );
      expect(state.currentAnswers.length, 1);
    });

    test('answeredCount increments with new questions', () async {
      final container = _makeContainer();
      await container.read(examSessionNotifierProvider('attempt-001').future);

      final notifier =
          container.read(examSessionNotifierProvider('attempt-001').notifier);
      notifier.answerQuestion(
        question: _readingQuestion,
        answer: const QuestionAnswer(
          questionId: 'question-reading-1',
          selectedOptionId: 'opt-a',
        ),
      );
      notifier.answerQuestion(
        question: _listeningQuestion,
        answer: const QuestionAnswer(
          questionId: 'question-listening-1',
          selectedOptionId: 'opt-b',
        ),
      );

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(state.answeredCount, 2);
    });
  });

  group('ExamSessionNotifier — navigation', () {
    test('nextQuestion advances within section', () async {
      final container = _makeContainer();
      await container.read(examSessionNotifierProvider('attempt-001').future);

      container
          .read(examSessionNotifierProvider('attempt-001').notifier)
          .nextQuestion();

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(state.currentQuestionIndex, 1);
      expect(state.currentSectionIndex, 0);
    });

    test('nextQuestion at last question in section shows transition', () async {
      // Start at last question of section 1 (index 2 of 3)
      final initial = _fakeInitialState.copyWith(currentQuestionIndex: 2);
      final container = _makeContainer(initial);
      await container.read(examSessionNotifierProvider('attempt-001').future);

      container
          .read(examSessionNotifierProvider('attempt-001').notifier)
          .nextQuestion();

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(state.showSectionTransition, isTrue);
    });

    test('advanceSection moves to next section, resets question index',
        () async {
      final container = _makeContainer();
      await container.read(examSessionNotifierProvider('attempt-001').future);

      container
          .read(examSessionNotifierProvider('attempt-001').notifier)
          .advanceSection();

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(state.currentSectionIndex, 1);
      expect(state.currentQuestionIndex, 0);
      expect(state.showSectionTransition, isFalse);
    });

    test('goToQuestion jumps to arbitrary position', () async {
      final container = _makeContainer();
      await container.read(examSessionNotifierProvider('attempt-001').future);

      container
          .read(examSessionNotifierProvider('attempt-001').notifier)
          .goToQuestion(1, 1);

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(state.currentSectionIndex, 1);
      expect(state.currentQuestionIndex, 1);
    });
  });

  group('ExamSessionState extensions', () {
    test('totalQuestions sums all sections', () {
      // section1 has 3, section2 has 2 → total 5
      expect(_fakeInitialState.totalQuestions, 5);
    });

    test('unansweredCount = total - answered', () {
      final state = _fakeInitialState.copyWith(
        currentAnswers: {
          'question-reading-1': const ExamQuestionAnswer(
            questionId: 'question-reading-1',
            selectedOptionId: 'a',
          ),
          'question-listening-1': const ExamQuestionAnswer(
            questionId: 'question-listening-1',
            selectedOptionId: 'b',
          ),
        },
      );
      expect(state.unansweredCount, 3);
    });

    test('globalQuestionIndex accounts for previous sections', () {
      final state = _fakeInitialState.copyWith(
        currentSectionIndex: 1,
        currentQuestionIndex: 1,
      );
      // section1 has 3 questions → offset 3, + index 1 = 4
      expect(state.globalQuestionIndex, 4);
    });
  });

  group('ExamSessionNotifier — updateRemainingSeconds', () {
    test('updates remainingSeconds in attempt', () async {
      final container = _makeContainer();
      await container.read(examSessionNotifierProvider('attempt-001').future);

      container
          .read(examSessionNotifierProvider('attempt-001').notifier)
          .updateRemainingSeconds(1800);

      final state = container
          .read(examSessionNotifierProvider('attempt-001'))
          .requireValue;
      expect(state.attempt.remainingSeconds, 1800);
    });
  });
}
