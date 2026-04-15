import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/shared/models/user_model.dart';

void main() {
  group('AppUser.fromJson', () {
    late Map<String, dynamic> validJson;

    setUpAll(() {
      validJson = jsonDecode(
        File('test/helpers/fixtures/user.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('parses all required fields', () {
      final user = AppUser.fromJson(validJson);

      expect(user.id, 'user-001');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.currentStreakDays, 7);
      expect(user.totalXp, 1240);
      expect(user.dailyGoalMinutes, 30);
    });

    test('parses subscription tier', () {
      final user = AppUser.fromJson(validJson);
      expect(user.subscriptionTier, SubscriptionTier.free);
      expect(user.isPremium, isFalse);
    });

    test('parses premium tier', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['subscriptionTier'] = 'premium';
      final user = AppUser.fromJson(json);
      expect(user.isPremium, isTrue);
    });

    test('optional fields default correctly', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
      });

      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.currentStreakDays, 0);
      expect(user.totalXp, 0);
      expect(user.subscriptionTier, SubscriptionTier.free);
    });

    test('examDate parses as DateTime', () {
      final user = AppUser.fromJson(validJson);
      expect(user.examDate, isNotNull);
      expect(user.examDate!.year, 2024);
      expect(user.hasExamDate, isTrue);
    });
  });

  group('AppUser.initials', () {
    AppUser makeUser({String? displayName, required String email}) =>
        AppUser.fromJson({'id': 'u', 'email': email, 'displayName': displayName});

    test('two-word name → first letter of each', () {
      final user = makeUser(displayName: 'Nguyen Van', email: 'n@v.com');
      expect(user.initials, 'NV');
    });

    test('single word name → first letter', () {
      final user = makeUser(displayName: 'Nguyen', email: 'n@v.com');
      expect(user.initials, 'N');
    });

    test('falls back to email when no display name', () {
      final user = makeUser(displayName: null, email: 'anna@test.com');
      expect(user.initials, 'A');
    });

    test('returns ? for empty email', () {
      final user = makeUser(displayName: null, email: '');
      expect(user.initials, '?');
    });
  });

  group('AppUser.copyWith', () {
    test('updates streak without changing other fields', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'currentStreakDays': 3,
        'totalXp': 500,
      });
      final updated = user.copyWith(currentStreakDays: 10);

      expect(updated.currentStreakDays, 10);
      expect(updated.totalXp, 500);
      expect(updated.email, 'a@b.com');
    });
  });
}
