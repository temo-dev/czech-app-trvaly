import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/auth/providers/auth_notifier.dart';
import 'package:app_czech/shared/providers/auth_provider.dart';
import 'package:app_czech/shared/models/user_model.dart';
import '../../helpers/provider_factory.dart';

// ── Fake CurrentUser notifier ─────────────────────────────────────────────────

class _FakeCurrentUser extends AutoDisposeAsyncNotifier<AppUser?> implements CurrentUser {
  final bool shouldThrow;
  final String? errorMessage;
  _FakeCurrentUser({this.shouldThrow = false, this.errorMessage});

  @override
  Future<AppUser?> build() async => null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'invalid login credentials');
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'error');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'error');
  }

  @override
  Future<void> updateProfile(AppUser updated) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({bool shouldThrow = false, String? errorMessage}) {
  return createContainer(overrides: [
    currentUserProvider.overrideWith(() =>
        _FakeCurrentUser(shouldThrow: shouldThrow, errorMessage: errorMessage)),
  ]);
}

void main() {
  group('AuthNotifier — signIn validation', () {
    test('empty email → validationError', () async {
      final container = _makeContainer();
      await container.read(authNotifierProvider.notifier).signIn(
            email: '',
            password: 'password123',
          );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthFormStatus.validationError);
      expect(state.errorMessage, isNotNull);
    });

    test('empty password → validationError', () async {
      final container = _makeContainer();
      await container.read(authNotifierProvider.notifier).signIn(
            email: 'user@test.com',
            password: '',
          );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthFormStatus.validationError);
    });

    test('whitespace-only email → validationError', () async {
      final container = _makeContainer();
      await container.read(authNotifierProvider.notifier).signIn(
            email: '   ',
            password: 'password123',
          );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthFormStatus.validationError);
    });

    test('valid credentials → success', () async {
      final container = _makeContainer(shouldThrow: false);
      await container.read(authNotifierProvider.notifier).signIn(
            email: 'user@test.com',
            password: 'password123',
          );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthFormStatus.success);
      expect(state.errorMessage, isNull);
    });

    test('auth failure → authError with mapped message', () async {
      final container = _makeContainer(
        shouldThrow: true,
        errorMessage: 'invalid login credentials',
      );
      await container.read(authNotifierProvider.notifier).signIn(
            email: 'user@test.com',
            password: 'wrongpass',
          );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthFormStatus.authError);
      expect(state.errorMessage, contains('mật khẩu'));
    });

    test('network error → authError', () async {
      final container = _makeContainer(
        shouldThrow: true,
        errorMessage: 'network timeout',
      );
      await container.read(authNotifierProvider.notifier).signIn(
            email: 'user@test.com',
            password: 'pass',
          );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthFormStatus.authError);
      expect(state.errorMessage, contains('kết nối'));
    });
  });

  group('AuthNotifier — signUp validation', () {
    test('empty email → validationError', () async {
      final container = _makeContainer();
      await container.read(authNotifierProvider.notifier).signUp(
            email: '',
            password: 'password123',
          );
      expect(
        container.read(authNotifierProvider).status,
        AuthFormStatus.validationError,
      );
    });

    test('password shorter than 8 chars → validationError', () async {
      final container = _makeContainer();
      await container.read(authNotifierProvider.notifier).signUp(
            email: 'user@test.com',
            password: 'short',
          );
      expect(
        container.read(authNotifierProvider).status,
        AuthFormStatus.validationError,
      );
    });

    test('valid signup → success', () async {
      final container = _makeContainer(shouldThrow: false);
      await container.read(authNotifierProvider.notifier).signUp(
            email: 'newuser@test.com',
            password: 'StrongPass1',
            displayName: 'New User',
          );
      expect(
        container.read(authNotifierProvider).status,
        AuthFormStatus.success,
      );
    });
  });

  group('AuthNotifier — sendPasswordReset', () {
    test('empty email → validationError', () async {
      final container = _makeContainer();
      await container
          .read(authNotifierProvider.notifier)
          .sendPasswordReset('');
      expect(
        container.read(authNotifierProvider).status,
        AuthFormStatus.validationError,
      );
    });

    test('valid email → success', () async {
      final container = _makeContainer(shouldThrow: false);
      await container
          .read(authNotifierProvider.notifier)
          .sendPasswordReset('user@test.com');
      expect(
        container.read(authNotifierProvider).status,
        AuthFormStatus.success,
      );
    });
  });

  group('AuthNotifier — reset', () {
    test('reset clears state back to idle', () async {
      final container = _makeContainer();
      await container.read(authNotifierProvider.notifier).signIn(
            email: '',
            password: '',
          );
      expect(
        container.read(authNotifierProvider).status,
        AuthFormStatus.validationError,
      );

      container.read(authNotifierProvider.notifier).reset();
      expect(
        container.read(authNotifierProvider).status,
        AuthFormStatus.idle,
      );
      expect(container.read(authNotifierProvider).errorMessage, isNull);
    });
  });
}
