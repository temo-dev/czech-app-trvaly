import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:app_czech/features/chat/models/friend_models.dart';
import 'package:app_czech/features/chat/widgets/friend_tile.dart';
import 'package:app_czech/features/chat/widgets/friend_request_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: ProviderScope(child: child),
      ),
    );

UserProfile _makeProfile({
  String id = 'user-001',
  String name = 'Nguyễn Văn A',
  int xp = 1200,
  FriendshipStatus? status = FriendshipStatus.accepted,
  String? friendshipId = 'fs-001',
}) =>
    UserProfile(
      id: id,
      displayName: name,
      totalXp: xp,
      friendshipStatus: status,
      friendshipId: friendshipId,
    );

void main() {
  // ── FriendTile ──────────────────────────────────────────────────────────────

  group('FriendTile', () {
    testWidgets('shows display name', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(FriendTile(
          profile: _makeProfile(name: 'Trần B'),
          onMessage: () {},
          onUnfriend: () {},
        )));

        expect(find.text('Trần B'), findsOneWidget);
      });
    });

    testWidgets('shows XP', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(FriendTile(
          profile: _makeProfile(xp: 2500),
          onMessage: () {},
          onUnfriend: () {},
        )));

        expect(find.textContaining('2500'), findsOneWidget);
      });
    });

    testWidgets('calls onMessage when Nhắn tin tapped', (tester) async {
      await mockNetworkImagesFor(() async {
        var called = false;
        await tester.pumpWidget(_wrap(FriendTile(
          profile: _makeProfile(),
          onMessage: () => called = true,
          onUnfriend: () {},
        )));

        await tester.tap(find.text('Nhắn tin'));
        expect(called, isTrue);
      });
    });

    testWidgets('shows avatar initial when no URL', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(FriendTile(
          profile: _makeProfile(name: 'Lê C'),
          onMessage: () {},
          onUnfriend: () {},
        )));

        expect(find.text('L'), findsOneWidget);
      });
    });

    testWidgets('shows more options button', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(FriendTile(
          profile: _makeProfile(),
          onMessage: () {},
          onUnfriend: () {},
        )));

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });
    });

    testWidgets('calls onUnfriend from popup menu', (tester) async {
      await mockNetworkImagesFor(() async {
        var unfriendCalled = false;
        await tester.pumpWidget(_wrap(FriendTile(
          profile: _makeProfile(),
          onMessage: () {},
          onUnfriend: () => unfriendCalled = true,
        )));

        // Open popup menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Tap "Xóa bạn"
        await tester.tap(find.text('Xóa bạn'));
        await tester.pumpAndSettle();

        expect(unfriendCalled, isTrue);
      });
    });
  });

  // ── FriendRequestTile ───────────────────────────────────────────────────────

  group('FriendRequestTile', () {
    testWidgets('shows requester name', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(FriendRequestTile(
          profile: _makeProfile(name: 'Phạm D'),
          onAccept: () {},
          onDecline: () {},
        )));

        expect(find.text('Phạm D'), findsOneWidget);
      });
    });

    testWidgets('shows Chấp nhận and Từ chối buttons', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(FriendRequestTile(
          profile: _makeProfile(),
          onAccept: () {},
          onDecline: () {},
        )));

        expect(find.text('Chấp nhận'), findsOneWidget);
        expect(find.text('Từ chối'), findsOneWidget);
      });
    });

    testWidgets('calls onAccept when Chấp nhận tapped', (tester) async {
      await mockNetworkImagesFor(() async {
        var accepted = false;
        await tester.pumpWidget(_wrap(FriendRequestTile(
          profile: _makeProfile(),
          onAccept: () => accepted = true,
          onDecline: () {},
        )));

        await tester.tap(find.text('Chấp nhận'));
        expect(accepted, isTrue);
      });
    });

    testWidgets('calls onDecline when Từ chối tapped', (tester) async {
      await mockNetworkImagesFor(() async {
        var declined = false;
        await tester.pumpWidget(_wrap(FriendRequestTile(
          profile: _makeProfile(),
          onAccept: () {},
          onDecline: () => declined = true,
        )));

        await tester.tap(find.text('Từ chối'));
        expect(declined, isTrue);
      });
    });

    testWidgets('shows XP badge', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(FriendRequestTile(
          profile: _makeProfile(xp: 800),
          onAccept: () {},
          onDecline: () {},
        )));

        expect(find.textContaining('800'), findsOneWidget);
      });
    });
  });
}
