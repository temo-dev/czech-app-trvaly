import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Robot pattern — high-level test actions that abstract away raw [find] calls.
/// Integration test bodies use only robot methods, never raw finders.
class AppRobot {
  const AppRobot(this.tester);
  final WidgetTester tester;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> fillLoginForm(String email, String password) async {
    await tester.enterText(
      find.byKey(const Key('email_field')),
      email,
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      password,
    );
  }

  Future<void> tapLoginButton() async {
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  Future<void> tapSignupButton() async {
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  Future<void> fillSignupForm({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (displayName != null) {
      await tester.enterText(
        find.byKey(const Key('name_field')),
        displayName,
      );
    }
    await tester.enterText(
      find.byKey(const Key('email_field')),
      email,
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      password,
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<void> expectOnDashboard() async {
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byKey(const Key('dashboard_screen')), findsOneWidget);
  }

  // ── Exam flow ─────────────────────────────────────────────────────────────

  Future<void> tapStartExam() async {
    await tester.tap(find.text('Bắt đầu thi thử ngay'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> selectFirstOption() async {
    final options = find.byKey(const Key('mcq_option'));
    if (options.evaluate().isNotEmpty) {
      await tester.tap(options.first);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapNextQuestion() async {
    await tester.tap(find.text('Câu tiếp theo'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmitExam() async {
    await tester.tap(find.text('Nộp bài'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> confirmSubmit() async {
    // Confirm dialog if shown
    final confirm = find.text('Nộp bài');
    if (confirm.evaluate().length > 1) {
      await tester.tap(confirm.last);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
