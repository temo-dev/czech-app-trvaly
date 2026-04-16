import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/chat/providers/chat_providers.dart';
import 'package:app_czech/features/chat/providers/friend_providers.dart';
import '../../helpers/provider_factory.dart';

// ── Fake ChatNotifier — bypasses Supabase calls ────────────────────────────────

class _FakeChatNotifier extends ChatNotifier {
  final bool shouldThrow;
  final List<String> sentMessages = [];
  bool markedRead = false;

  _FakeChatNotifier({this.shouldThrow = false});

  @override
  AsyncValue<void> build(String roomId) => const AsyncData(null);

  @override
  Future<void> sendMessage(String body) async {
    state = const AsyncLoading();
    if (shouldThrow) {
      state = AsyncError(Exception('network error'), StackTrace.empty);
    } else {
      sentMessages.add(body);
      state = const AsyncData(null);
    }
  }

  @override
  Future<void> markRead() async {
    markedRead = true;
  }
}

// ── Fake FriendshipNotifier ────────────────────────────────────────────────────

class _FakeFriendshipNotifier extends FriendshipNotifier {
  final bool shouldThrow;
  final List<String> sentRequests = [];
  final List<String> accepted = [];
  final List<String> declined = [];
  final List<String> unfriended = [];

  _FakeFriendshipNotifier({this.shouldThrow = false});

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> _act(void Function() onSuccess) async {
    state = const AsyncLoading();
    if (shouldThrow) {
      state = AsyncError(Exception('supabase error'), StackTrace.empty);
    } else {
      onSuccess();
      state = const AsyncData(null);
    }
  }

  @override
  Future<void> sendRequest(String addresseeId) =>
      _act(() => sentRequests.add(addresseeId));

  @override
  Future<void> accept(String friendshipId) =>
      _act(() => accepted.add(friendshipId));

  @override
  Future<void> decline(String friendshipId) =>
      _act(() => declined.add(friendshipId));

  @override
  Future<void> unfriend(String friendshipId) =>
      _act(() => unfriended.add(friendshipId));

  @override
  Future<void> cancelRequest(String friendshipId) =>
      _act(() => unfriended.add(friendshipId));
}

// ── Fake OpenDmNotifier ────────────────────────────────────────────────────────

class _FakeOpenDmNotifier extends OpenDmNotifier {
  final String? roomId;
  final bool shouldThrow;

  _FakeOpenDmNotifier({this.roomId, this.shouldThrow = false});

  @override
  AsyncValue<String?> build() => const AsyncData(null);

  @override
  Future<String?> open(String peerId) async {
    state = const AsyncLoading();
    if (shouldThrow) {
      state = AsyncError(Exception('not_friends'), StackTrace.empty);
      return null;
    }
    state = AsyncData(roomId);
    return roomId;
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

const _roomId = 'room-test';

ProviderContainer _chatContainer({bool shouldThrow = false}) {
  return createContainer(overrides: [
    chatNotifierProvider(_roomId).overrideWith(
      () => _FakeChatNotifier(shouldThrow: shouldThrow),
    ),
  ]);
}

ProviderContainer _friendshipContainer({bool shouldThrow = false}) {
  return createContainer(overrides: [
    friendshipNotifierProvider.overrideWith(
      () => _FakeFriendshipNotifier(shouldThrow: shouldThrow),
    ),
  ]);
}

ProviderContainer _openDmContainer({String? roomId, bool shouldThrow = false}) {
  return createContainer(overrides: [
    openDmNotifierProvider.overrideWith(
      () => _FakeOpenDmNotifier(roomId: roomId, shouldThrow: shouldThrow),
    ),
  ]);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  // ── ChatNotifier ─────────────────────────────────────────────────────────────

  group('ChatNotifier — initial state', () {
    test('starts as AsyncData(null)', () {
      final container = _chatContainer();
      final state = container.read(chatNotifierProvider(_roomId));
      expect(state, isA<AsyncData<void>>());
    });
  });

  group('ChatNotifier — sendMessage', () {
    test('transitions to AsyncData on success', () async {
      final container = _chatContainer();
      final notifier = container.read(chatNotifierProvider(_roomId).notifier)
          as _FakeChatNotifier;

      await notifier.sendMessage('Xin chào!');

      expect(container.read(chatNotifierProvider(_roomId)), isA<AsyncData<void>>());
      expect(notifier.sentMessages, contains('Xin chào!'));
    });

    test('transitions to AsyncError on failure', () async {
      final container = _chatContainer(shouldThrow: true);
      final notifier = container.read(chatNotifierProvider(_roomId).notifier)
          as _FakeChatNotifier;

      await notifier.sendMessage('hello');

      expect(container.read(chatNotifierProvider(_roomId)), isA<AsyncError<void>>());
      expect(notifier.sentMessages, isEmpty);
    });

    test('records multiple messages in order', () async {
      final container = _chatContainer();
      final notifier = container.read(chatNotifierProvider(_roomId).notifier)
          as _FakeChatNotifier;

      await notifier.sendMessage('tin 1');
      await notifier.sendMessage('tin 2');
      await notifier.sendMessage('tin 3');

      expect(notifier.sentMessages, ['tin 1', 'tin 2', 'tin 3']);
    });
  });

  group('ChatNotifier — markRead', () {
    test('sets markedRead flag', () async {
      final container = _chatContainer();
      final notifier = container.read(chatNotifierProvider(_roomId).notifier)
          as _FakeChatNotifier;

      expect(notifier.markedRead, isFalse);
      await notifier.markRead();
      expect(notifier.markedRead, isTrue);
    });
  });

  // ── FriendshipNotifier ────────────────────────────────────────────────────────

  group('FriendshipNotifier — initial state', () {
    test('starts as AsyncData(null)', () {
      final container = _friendshipContainer();
      expect(
        container.read(friendshipNotifierProvider),
        isA<AsyncData<void>>(),
      );
    });
  });

  group('FriendshipNotifier — sendRequest', () {
    test('records addressee on success', () async {
      final container = _friendshipContainer();
      final notifier =
          container.read(friendshipNotifierProvider.notifier) as _FakeFriendshipNotifier;

      await notifier.sendRequest('user-B');

      expect(notifier.sentRequests, contains('user-B'));
      expect(container.read(friendshipNotifierProvider), isA<AsyncData<void>>());
    });

    test('AsyncError on failure', () async {
      final container = _friendshipContainer(shouldThrow: true);
      final notifier =
          container.read(friendshipNotifierProvider.notifier) as _FakeFriendshipNotifier;

      await notifier.sendRequest('user-B');

      expect(container.read(friendshipNotifierProvider), isA<AsyncError<void>>());
      expect(notifier.sentRequests, isEmpty);
    });
  });

  group('FriendshipNotifier — accept', () {
    test('records friendship id on success', () async {
      final container = _friendshipContainer();
      final notifier =
          container.read(friendshipNotifierProvider.notifier) as _FakeFriendshipNotifier;

      await notifier.accept('fs-001');

      expect(notifier.accepted, contains('fs-001'));
      expect(container.read(friendshipNotifierProvider), isA<AsyncData<void>>());
    });
  });

  group('FriendshipNotifier — decline', () {
    test('records friendship id on success', () async {
      final container = _friendshipContainer();
      final notifier =
          container.read(friendshipNotifierProvider.notifier) as _FakeFriendshipNotifier;

      await notifier.decline('fs-002');

      expect(notifier.declined, contains('fs-002'));
    });
  });

  group('FriendshipNotifier — unfriend', () {
    test('records friendship id on success', () async {
      final container = _friendshipContainer();
      final notifier =
          container.read(friendshipNotifierProvider.notifier) as _FakeFriendshipNotifier;

      await notifier.unfriend('fs-003');

      expect(notifier.unfriended, contains('fs-003'));
    });

    test('AsyncError on failure', () async {
      final container = _friendshipContainer(shouldThrow: true);
      final notifier =
          container.read(friendshipNotifierProvider.notifier) as _FakeFriendshipNotifier;

      await notifier.unfriend('fs-003');

      expect(container.read(friendshipNotifierProvider), isA<AsyncError<void>>());
    });
  });

  // ── OpenDmNotifier ────────────────────────────────────────────────────────────

  group('OpenDmNotifier — open', () {
    test('returns roomId on success', () async {
      final container = _openDmContainer(roomId: 'room-xyz');
      final notifier =
          container.read(openDmNotifierProvider.notifier) as _FakeOpenDmNotifier;

      final result = await notifier.open('peer-001');

      expect(result, 'room-xyz');
      expect(container.read(openDmNotifierProvider), isA<AsyncData<String?>>());
    });

    test('returns null and AsyncError when not friends', () async {
      final container = _openDmContainer(shouldThrow: true);
      final notifier =
          container.read(openDmNotifierProvider.notifier) as _FakeOpenDmNotifier;

      final result = await notifier.open('peer-stranger');

      expect(result, isNull);
      expect(container.read(openDmNotifierProvider), isA<AsyncError<String?>>());
    });

    test('initial state is AsyncData(null)', () {
      final container = _openDmContainer();
      expect(
        container.read(openDmNotifierProvider),
        isA<AsyncData<String?>>(),
      );
      expect(
        container.read(openDmNotifierProvider).valueOrNull,
        isNull,
      );
    });
  });
}
