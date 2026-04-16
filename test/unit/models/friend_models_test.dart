import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/chat/models/friend_models.dart';

void main() {
  // ── UserProfile.fromMap ──────────────────────────────────────────────────────

  group('UserProfile.fromMap', () {
    test('parses all fields', () {
      final profile = UserProfile.fromMap({
        'id': 'user-001',
        'display_name': 'Nguyễn Văn A',
        'avatar_url': 'https://example.com/avatar.jpg',
        'total_xp': 1500,
      });

      expect(profile.id, 'user-001');
      expect(profile.displayName, 'Nguyễn Văn A');
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(profile.totalXp, 1500);
      expect(profile.friendshipStatus, isNull);
    });

    test('defaults to "Người dùng" when display_name null', () {
      final profile = UserProfile.fromMap({
        'id': 'user-002',
        'display_name': null,
        'avatar_url': null,
        'total_xp': null,
      });

      expect(profile.displayName, 'Người dùng');
      expect(profile.totalXp, 0);
      expect(profile.avatarUrl, isNull);
    });

    test('passes through friendship metadata', () {
      final profile = UserProfile.fromMap(
        {'id': 'user-003', 'display_name': 'B', 'total_xp': 0},
        friendshipStatus: FriendshipStatus.accepted,
        friendshipId: 'fs-001',
        isRequester: true,
      );

      expect(profile.friendshipStatus, FriendshipStatus.accepted);
      expect(profile.friendshipId, 'fs-001');
      expect(profile.isRequester, isTrue);
    });
  });

  group('UserProfile helpers', () {
    UserProfile makeProfile(FriendshipStatus? status) => UserProfile(
          id: 'u',
          displayName: 'A',
          totalXp: 0,
          friendshipStatus: status,
        );

    test('isFriend true when accepted', () {
      expect(makeProfile(FriendshipStatus.accepted).isFriend, isTrue);
    });

    test('isFriend false when pending', () {
      expect(makeProfile(FriendshipStatus.pending).isFriend, isFalse);
    });

    test('isPending true when pending', () {
      expect(makeProfile(FriendshipStatus.pending).isPending, isTrue);
    });

    test('isPending false when accepted', () {
      expect(makeProfile(FriendshipStatus.accepted).isPending, isFalse);
    });

    test('isFriend false when no relationship', () {
      expect(makeProfile(null).isFriend, isFalse);
    });
  });

  // ── Friendship.fromMap ───────────────────────────────────────────────────────

  group('Friendship.fromMap', () {
    test('parses pending status', () {
      final f = Friendship.fromMap({
        'id': 'fs-001',
        'requester_id': 'user-A',
        'addressee_id': 'user-B',
        'status': 'pending',
        'created_at': '2026-04-16T10:00:00.000Z',
      });

      expect(f.id, 'fs-001');
      expect(f.requesterId, 'user-A');
      expect(f.addresseeId, 'user-B');
      expect(f.status, FriendshipStatus.pending);
      expect(f.createdAt, DateTime.utc(2026, 4, 16, 10));
    });

    test('parses accepted status', () {
      final f = Friendship.fromMap({
        'id': 'fs-002',
        'requester_id': 'user-A',
        'addressee_id': 'user-B',
        'status': 'accepted',
        'created_at': '2026-04-16T11:00:00.000Z',
      });

      expect(f.status, FriendshipStatus.accepted);
    });

    test('parses declined status', () {
      final f = Friendship.fromMap({
        'id': 'fs-003',
        'requester_id': 'user-A',
        'addressee_id': 'user-B',
        'status': 'declined',
        'created_at': '2026-04-16T12:00:00.000Z',
      });

      expect(f.status, FriendshipStatus.declined);
    });

    test('unknown status defaults to pending', () {
      final f = Friendship.fromMap({
        'id': 'fs-004',
        'requester_id': 'user-A',
        'addressee_id': 'user-B',
        'status': 'blocked', // unknown
        'created_at': '2026-04-16T13:00:00.000Z',
      });

      expect(f.status, FriendshipStatus.pending);
    });
  });
}
