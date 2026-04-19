import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/bootstrap.dart';
import 'helpers/test_robot.dart';

/// End-to-end: log in with staging credentials → land on dashboard → sign out.
///
/// Requires staging Supabase project.
/// Set env via --dart-define-from-file=env.staging.json.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = String.fromEnvironment('TEST_USER_EMAIL',
      defaultValue: 'e2e@staging.test');
  const testPassword =
      String.fromEnvironment('TEST_USER_PASSWORD', defaultValue: 'Test1234!');

  group('Auth flow', () {
    testWidgets('login → dashboard → logout', (tester) async {
      await pumpRealApp(tester);

      final robot = AppRobot(tester);

      // Navigate to login
      final loginLink = find.text('Đăng nhập');
      if (loginLink.evaluate().isNotEmpty) {
        await tester.tap(loginLink);
        await tester.pumpAndSettle();
      }

      await robot.fillLoginForm(testEmail, testPassword);
      await robot.tapLoginButton();

      // Should be on dashboard
      await robot.expectOnDashboard();

      // Sign out
      await robot.signOut();

      // Should be back at landing
      expect(find.text('Đăng nhập'), findsAtLeastNWidgets(1));
    });
  });
}
