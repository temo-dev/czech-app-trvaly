import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/auth/providers/auth_notifier.dart';
import 'package:app_czech/features/auth/screens/login_screen.dart';
import 'package:app_czech/shared/providers/auth_provider.dart';
import 'package:app_czech/shared/models/user_model.dart';
import '../../helpers/pump_app.dart';

// ── Fake notifiers ────────────────────────────────────────────────────────────

class _IdleAuthNotifier extends AuthNotifier {
  @override
  AuthFormState build() => const AuthFormState(status: AuthFormStatus.idle);

  @override
  Future<void> signIn({required String email, required String password}) async {}
}

class _SubmittingAuthNotifier extends AuthNotifier {
  @override
  AuthFormState build() =>
      const AuthFormState(status: AuthFormStatus.submitting);

  @override
  Future<void> signIn({required String email, required String password}) async {}
}

class _ErrorAuthNotifier extends AuthNotifier {
  @override
  AuthFormState build() => const AuthFormState(
        status: AuthFormStatus.authError,
        errorMessage: 'Email hoặc mật khẩu không đúng',
      );

  @override
  Future<void> signIn({required String email, required String password}) async {}
}

class _FakeCurrentUser extends AutoDisposeAsyncNotifier<AppUser?> implements CurrentUser {
  @override
  Future<AppUser?> build() async => null;
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> signUp({required String email, required String password, String? displayName}) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> updateProfile(AppUser updated) async {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final baseOverrides = [
    currentUserProvider.overrideWith(() => _FakeCurrentUser()),
  ];

  group('LoginScreen — idle state', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          ...baseOverrides,
          authNotifierProvider.overrideWith(_IdleAuthNotifier.new),
        ],
      );

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('renders Đăng nhập button', (tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          ...baseOverrides,
          authNotifierProvider.overrideWith(_IdleAuthNotifier.new),
        ],
      );

      expect(find.text('Đăng nhập'), findsOneWidget);
    });
  });

  group('LoginScreen — submitting state', () {
    testWidgets('shows loading indicator while submitting', (tester) async {
      // pumpAndSettle times out with CircularProgressIndicator animating.
      // Use pumpAppNoSettle then pump once to render the frame.
      await tester.pumpAppNoSettle(
        const LoginScreen(),
        overrides: [
          ...baseOverrides,
          authNotifierProvider.overrideWith(_SubmittingAuthNotifier.new),
        ],
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoginScreen — error state', () {
    testWidgets('shows error message on auth failure', (tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          ...baseOverrides,
          authNotifierProvider.overrideWith(_ErrorAuthNotifier.new),
        ],
      );

      expect(
        find.text('Email hoặc mật khẩu không đúng'),
        findsOneWidget,
      );
    });
  });
}
