import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:app_czech/features/chat/models/chat_models.dart';
import 'package:app_czech/features/chat/widgets/conversation_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ConversationCard — text message', () {
    testWidgets('shows peer name and message body', (tester) async {
      await mockNetworkImagesFor(() async {
        final msg = ChatMessage(
          id: 'm1',
          roomId: 'room-1',
          senderId: 'peer-1',
          messageType: MessageType.text,
          body: 'Bạn ơi học được chưa?',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          lastMessage: msg,
          unreadCount: 0,
          onTap: () {},
        )));

        expect(find.text('Nguyễn A'), findsOneWidget);
        expect(find.text('Bạn ơi học được chưa?'), findsOneWidget);
      });
    });

    testWidgets('shows unread badge when unreadCount > 0', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          unreadCount: 3,
          onTap: () {},
        )));

        expect(find.text('3'), findsOneWidget);
      });
    });

    testWidgets('no badge when unreadCount is 0', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          unreadCount: 0,
          onTap: () {},
        )));

        // Badge numbers should not appear
        expect(find.text('0'), findsNothing);
      });
    });

    testWidgets('shows avatar initial when no avatarUrl', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          peerAvatarUrl: null,
          unreadCount: 0,
          onTap: () {},
        )));

        // First letter of peer name as avatar initial
        expect(find.text('N'), findsOneWidget);
      });
    });

    testWidgets('calls onTap when tapped', (tester) async {
      await mockNetworkImagesFor(() async {
        var tapped = false;
        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          unreadCount: 0,
          onTap: () => tapped = true,
        )));

        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      });
    });

    testWidgets('shows placeholder when no last message', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          lastMessage: null,
          unreadCount: 0,
          onTap: () {},
        )));

        expect(find.text('Bắt đầu trò chuyện'), findsOneWidget);
      });
    });

    testWidgets('badge caps at 99+', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          unreadCount: 150,
          onTap: () {},
        )));

        expect(find.text('99+'), findsOneWidget);
      });
    });
  });

  group('ConversationCard — image/file preview text', () {
    testWidgets('shows image icon for image message', (tester) async {
      await mockNetworkImagesFor(() async {
        final msg = ChatMessage(
          id: 'm2',
          roomId: 'room-1',
          senderId: 'peer-1',
          messageType: MessageType.image,
          attachmentUrl: 'https://example.com/img.jpg',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          lastMessage: msg,
          unreadCount: 0,
          onTap: () {},
        )));

        expect(find.textContaining('Hình ảnh'), findsOneWidget);
      });
    });

    testWidgets('shows file icon and name for file message', (tester) async {
      await mockNetworkImagesFor(() async {
        final msg = ChatMessage(
          id: 'm3',
          roomId: 'room-1',
          senderId: 'peer-1',
          messageType: MessageType.file,
          attachmentUrl: 'https://example.com/doc.pdf',
          attachmentName: 'bai_tap.pdf',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(_wrap(ConversationCard(
          roomId: 'room-1',
          peerName: 'Nguyễn A',
          lastMessage: msg,
          unreadCount: 0,
          onTap: () {},
        )));

        expect(find.textContaining('bai_tap.pdf'), findsOneWidget);
      });
    });
  });
}
