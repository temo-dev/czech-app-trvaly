import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/chat/models/chat_models.dart';

void main() {
  // ── ChatMessage.fromMap ──────────────────────────────────────────────────────

  group('ChatMessage.fromMap — text message', () {
    late Map<String, dynamic> map;

    setUp(() {
      map = {
        'id': 'msg-001',
        'room_id': 'room-abc',
        'sender_id': 'user-001',
        'message_type': 'text',
        'body': 'Xin chào!',
        'attachment_url': null,
        'attachment_name': null,
        'attachment_size': null,
        'attachment_mime': null,
        'created_at': '2026-04-16T10:00:00.000Z',
      };
    });

    test('parses required fields', () {
      final msg = ChatMessage.fromMap(map);

      expect(msg.id, 'msg-001');
      expect(msg.roomId, 'room-abc');
      expect(msg.senderId, 'user-001');
      expect(msg.messageType, MessageType.text);
      expect(msg.body, 'Xin chào!');
      expect(msg.createdAt, DateTime.utc(2026, 4, 16, 10));
    });

    test('isText true, isImage/isFile false', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.isText, isTrue);
      expect(msg.isImage, isFalse);
      expect(msg.isFile, isFalse);
    });

    test('previewText returns body for text messages', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.previewText, 'Xin chào!');
    });

    test('parses sender profile when present', () {
      map['sender'] = {'display_name': 'Nguyễn A', 'avatar_url': 'https://example.com/a.jpg'};
      final msg = ChatMessage.fromMap(map);
      expect(msg.senderName, 'Nguyễn A');
      expect(msg.senderAvatarUrl, 'https://example.com/a.jpg');
    });

    test('senderName/avatarUrl null when sender key absent', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.senderName, isNull);
      expect(msg.senderAvatarUrl, isNull);
    });
  });

  group('ChatMessage.fromMap — image message', () {
    late Map<String, dynamic> map;

    setUp(() {
      map = {
        'id': 'msg-002',
        'room_id': 'room-abc',
        'sender_id': 'user-001',
        'message_type': 'image',
        'body': null,
        'attachment_url': 'https://storage.example.com/img.jpg',
        'attachment_name': 'photo.jpg',
        'attachment_size': 204800,
        'attachment_mime': 'image/jpeg',
        'created_at': '2026-04-16T10:01:00.000Z',
      };
    });

    test('messageType is image', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.messageType, MessageType.image);
      expect(msg.isImage, isTrue);
    });

    test('previewText shows image icon', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.previewText, contains('Hình ảnh'));
    });

    test('attachment fields parsed', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.attachmentUrl, 'https://storage.example.com/img.jpg');
      expect(msg.attachmentName, 'photo.jpg');
      expect(msg.attachmentSize, 204800);
      expect(msg.attachmentMime, 'image/jpeg');
    });
  });

  group('ChatMessage.fromMap — file message', () {
    late Map<String, dynamic> map;

    setUp(() {
      map = {
        'id': 'msg-003',
        'room_id': 'room-abc',
        'sender_id': 'user-001',
        'message_type': 'file',
        'body': null,
        'attachment_url': 'https://storage.example.com/doc.pdf',
        'attachment_name': 'bai_tap.pdf',
        'attachment_size': 1048576,
        'attachment_mime': 'application/pdf',
        'created_at': '2026-04-16T10:02:00.000Z',
      };
    });

    test('messageType is file', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.messageType, MessageType.file);
      expect(msg.isFile, isTrue);
    });

    test('previewText shows file name', () {
      final msg = ChatMessage.fromMap(map);
      expect(msg.previewText, contains('bai_tap.pdf'));
    });

    test('previewText fallback when name is null', () {
      map['attachment_name'] = null;
      final msg = ChatMessage.fromMap(map);
      expect(msg.previewText, contains('Tệp đính kèm'));
    });
  });

  group('ChatMessage.fromMap — unknown message_type falls back to text', () {
    test('unknown type → MessageType.text', () {
      final map = {
        'id': 'msg-x',
        'room_id': 'room-abc',
        'sender_id': 'user-001',
        'message_type': 'video', // not in enum
        'body': 'hello',
        'created_at': '2026-04-16T10:00:00.000Z',
      };
      final msg = ChatMessage.fromMap(map);
      expect(msg.messageType, MessageType.text);
    });
  });

  // ── DmConversation ───────────────────────────────────────────────────────────

  group('DmConversation.copyWith', () {
    final base = DmConversation(
      roomId: 'room-001',
      peerId: 'peer-001',
      peerName: 'Bạn A',
      unreadCount: 0,
    );

    test('updates unreadCount without changing other fields', () {
      final updated = base.copyWith(unreadCount: 5);
      expect(updated.unreadCount, 5);
      expect(updated.roomId, 'room-001');
      expect(updated.peerName, 'Bạn A');
    });

    test('updates lastMessage', () {
      final msg = ChatMessage(
        id: 'm1',
        roomId: 'room-001',
        senderId: 'peer-001',
        messageType: MessageType.text,
        body: 'Hi',
        createdAt: DateTime(2026, 4, 16),
      );
      final updated = base.copyWith(lastMessage: msg);
      expect(updated.lastMessage?.body, 'Hi');
      expect(updated.unreadCount, 0); // unchanged
    });
  });
}
