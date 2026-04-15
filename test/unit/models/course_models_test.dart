import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/course/models/course_models.dart';

void main() {
  group('ModuleSummary.progressFraction', () {
    ModuleSummary makeModule({
      required int completed,
      required int total,
    }) =>
        ModuleSummary(
          id: 'm1',
          courseId: 'c1',
          title: 'Test Module',
          orderIndex: 0,
          lessonCount: total,
          completedCount: completed,
        );

    test('100% when all lessons completed', () {
      expect(makeModule(completed: 5, total: 5).progressFraction, 1.0);
    });

    test('0% when no lessons completed', () {
      expect(makeModule(completed: 0, total: 5).progressFraction, 0.0);
    });

    test('0% when total is 0 (no division error)', () {
      expect(makeModule(completed: 0, total: 0).progressFraction, 0.0);
    });

    test('50% progress', () {
      expect(
        makeModule(completed: 3, total: 6).progressFraction,
        closeTo(0.5, 0.001),
      );
    });
  });

  group('LessonStatus', () {
    test('all enum values exist', () {
      expect(LessonStatus.values, containsAll([
        LessonStatus.locked,
        LessonStatus.available,
        LessonStatus.inProgress,
        LessonStatus.completed,
      ]));
    });
  });

  group('LessonSummary', () {
    test('can construct and access fields', () {
      const lesson = LessonSummary(
        id: 'l1',
        moduleId: 'm1',
        title: 'Lesson One',
        orderIndex: 0,
        status: LessonStatus.available,
      );

      expect(lesson.id, 'l1');
      expect(lesson.status, LessonStatus.available);
      expect(lesson.orderIndex, 0);
    });
  });

  group('BlockType', () {
    test('all skill block types exist', () {
      expect(BlockType.values, containsAll([
        BlockType.vocab,
        BlockType.grammar,
        BlockType.reading,
        BlockType.listening,
        BlockType.speaking,
        BlockType.writing,
      ]));
    });
  });
}
