import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Robot pattern — high-level test actions that abstract away raw [find] calls.
/// Integration test bodies use only robot methods, never raw finders.
class AppRobot {
  const AppRobot(this.tester);
  final WidgetTester tester;

  Future<void> _tapFirst(Finder finder) async {
    final hitTestable = finder.hitTestable();
    final target =
        hitTestable.evaluate().isNotEmpty ? hitTestable.first : finder.first;
    await tester.ensureVisible(target);
    await tester.tap(target, warnIfMissed: false);
  }

  Future<void> goToPath(String path) async {
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go(path);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

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
    final loginButton = find.byKey(const Key('login_button'));
    await _tapFirst(
      loginButton.evaluate().isNotEmpty ? loginButton : find.text('Đăng nhập'),
    );
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  Future<void> tapSignupButton() async {
    final signupButton = find.byKey(const Key('signup_button'));
    await _tapFirst(
      signupButton.evaluate().isNotEmpty ? signupButton : find.text('Đăng ký'),
    );
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

  Future<void> agreeToTerms() async {
    await _tapFirst(find.byKey(const Key('terms_checkbox')));
    await tester.pumpAndSettle();
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<void> expectOnDashboard() async {
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byKey(const Key('dashboard_screen')), findsOneWidget);
  }

  // ── Exam flow ─────────────────────────────────────────────────────────────

  Future<void> tapStartExam() async {
    final landingCta = find.byKey(const Key('landing_start_exam_button'));
    if (landingCta.evaluate().isNotEmpty) {
      await _tapFirst(landingCta);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } else {
      final landingText = find.text('Thi thử miễn phí ngay');
      if (landingText.evaluate().isNotEmpty) {
        await _tapFirst(landingText);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      } else {
        final altLandingText = find.text('Thi thử ngay');
        if (altLandingText.evaluate().isNotEmpty) {
          await _tapFirst(altLandingText);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }
      }
    }

    final introCta = find.byKey(const Key('mock_exam_start_button'));
    if (introCta.evaluate().isNotEmpty) {
      await _tapFirst(introCta);
    } else {
      final introText = find.text('Bắt đầu thi thử ngay');
      if (introText.evaluate().isNotEmpty) {
        await _tapFirst(introText);
      } else {
        final startText = find.text('Bắt đầu');
        await _tapFirst(startText);
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> selectFirstOption() async {
    final options = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith('mcq_option_'),
    );
    if (options.evaluate().isNotEmpty) {
      await _tapFirst(options);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapNextQuestion() async {
    final transition =
        find.byKey(const Key('section_transition_continue_button'));
    if (transition.evaluate().isNotEmpty) {
      await _tapFirst(transition);
    } else {
      final nextButton = find.byKey(const Key('mock_exam_next_button'));
      await _tapFirst(nextButton);
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmitExam() async {
    final submitButton = find.byKey(const Key('mock_exam_submit_button'));
    await _tapFirst(submitButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> confirmSubmit() async {
    final confirm = find.byKey(const Key('confirm_submit_button'));
    if (confirm.evaluate().isNotEmpty) {
      await _tapFirst(confirm);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    }
  }

  Future<void> tapResultSignup() async {
    final signupButton = find.byKey(const Key('result_signup_button'));
    await _tapFirst(signupButton);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  Future<void> enterWritingAnswer(String text) async {
    await tester.enterText(find.byType(TextFormField).last, text);
    await tester.pumpAndSettle();
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _tapFirst(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();
    await _tapFirst(find.text('Đăng xuất'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
