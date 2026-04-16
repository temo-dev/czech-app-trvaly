import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:app_czech/features/chat/models/chat_models.dart';
import 'package:app_czech/features/chat/widgets/message_bubble.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

ChatMessage _makeText({required bool isMine}) => ChatMessage(
      id: 'msg-text',
      roomId: 'room-1',
      senderId: isMine ? 'me' : 'peer',
      messageType: MessageType.text,
      body: 'Xin chào!',
      createdAt: DateTime(2026, 4, 16),
    );

ChatMessage _makeImage() => ChatMessage(
      id: 'msg-img',
      roomId: 'room-1',
      senderId: 'peer',
      messageType: MessageType.image,
      attachmentUrl: 'https://example.com/photo.jpg',
      createdAt: DateTime(2026, 4, 16),
    );

ChatMessage _makeFile() => ChatMessage(
      id: 'msg-file',
      roomId: 'room-1',
      senderId: 'peer',
      messageType: MessageType.file,
      attachmentUrl: 'https://example.com/doc.pdf',
      attachmentName: 'tai_lieu.pdf',
      attachmentSize: 512000,
      createdAt: DateTime(2026, 4, 16),
    );

void main() {
  group('MessageBubble — text', () {
    testWidgets('renders body text', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeText(isMine: false),
          isMine: false,
        )));

        expect(find.text('Xin chào!'), findsOneWidget);
      });
    });

    testWidgets('mine message: no peer avatar shown', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeText(isMine: true),
          isMine: true,
          peerName: 'B',
          peerAvatarUrl: null,
        )));

        // No avatar initial for own message
        expect(find.text('B'), findsNothing);
      });
    });

    testWidgets('received message with null avatarUrl shows initial', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeText(isMine: false),
          isMine: false,
          peerName: 'Nguyễn B',
          peerAvatarUrl: null,
        )));

        expect(find.text('N'), findsOneWidget);
      });
    });
  });

  group('MessageBubble — image', () {
    testWidgets('renders network image', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeImage(),
          isMine: false,
        )));

        // Image.network should be present
        expect(find.byType(Image), findsOneWidget);
      });
    });

    testWidgets('wraps image in GestureDetector for full-screen tap', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeImage(),
          isMine: false,
        )));

        expect(find.byType(GestureDetector), findsWidgets);
      });
    });
  });

  group('MessageBubble — file', () {
    testWidgets('shows file name', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeFile(),
          isMine: false,
        )));

        expect(find.text('tai_lieu.pdf'), findsOneWidget);
      });
    });

    testWidgets('shows file icon', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeFile(),
          isMine: false,
        )));

        expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
      });
    });

    testWidgets('shows download icon when attachmentUrl present', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeFile(),
          isMine: false,
        )));

        expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      });
    });

    testWidgets('shows formatted file size', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(MessageBubble(
          message: _makeFile(),
          isMine: false,
        )));

        // 512000 bytes → 500.0 KB
        expect(find.textContaining('KB'), findsOneWidget);
      });
    });
  });
}
