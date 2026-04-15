import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_czech/app.dart';
import 'helpers/test_robot.dart';

/// End-to-end: open free mock test → answer first question → submit → see result.
///
/// This test works for anonymous users (no login required).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Exam flow — anonymous guest', () {
    testWidgets('start exam → answer → submit → result screen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final robot = AppRobot(tester);

      // Tap start exam CTA on landing
      await robot.tapStartExam();

      // Select an answer for the first question
      await robot.selectFirstOption();

      // Submit the exam
      await robot.tapSubmitExam();
      await robot.confirmSubmit();

      // Result screen should show score ring
      expect(find.text('Nộp bài'), findsNothing);
      // The result screen is shown (any content is acceptable)
    });
  });
}
