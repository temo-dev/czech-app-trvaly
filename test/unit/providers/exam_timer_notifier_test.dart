import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/mock_test/providers/exam_session_notifier.dart';
import '../../helpers/provider_factory.dart';

void main() {
  group('ExamTimerNotifier', () {
    test('initial state equals initialSeconds', () {
      final container = createContainer();
      // listen keeps the autoDispose provider alive
      final sub = container.listen(examTimerNotifierProvider(60), (_, __) {});
      addTearDown(sub.close);

      expect(container.read(examTimerNotifierProvider(60)), 60);
    });

    test('start() decrements every second', () {
      fakeAsync((fake) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(examTimerNotifierProvider(10), (_, __) {});
        addTearDown(sub.close);

        container.read(examTimerNotifierProvider(10).notifier).start(() {});
        fake.elapse(const Duration(seconds: 5));

        expect(container.read(examTimerNotifierProvider(10)), 5);
      });
    });

    test('fires onExpired callback when reaching zero', () {
      fakeAsync((fake) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        var expired = false;
        final sub = container.listen(examTimerNotifierProvider(3), (_, __) {});
        addTearDown(sub.close);

        container
            .read(examTimerNotifierProvider(3).notifier)
            .start(() => expired = true);

        // Timer decrements on each tick; onExpired fires on the tick after
        // state reaches 0 (tick 1→2, 2→1, 3→0, then 4th tick fires onExpired).
        fake.elapse(const Duration(seconds: 4));

        expect(expired, isTrue);
        expect(container.read(examTimerNotifierProvider(3)), 0);
      });
    });

    test('does not go below zero', () {
      fakeAsync((fake) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(examTimerNotifierProvider(2), (_, __) {});
        addTearDown(sub.close);

        container.read(examTimerNotifierProvider(2).notifier).start(() {});
        fake.elapse(const Duration(seconds: 10));

        expect(container.read(examTimerNotifierProvider(2)), 0);
      });
    });

    test('pause() stops countdown', () {
      fakeAsync((fake) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(examTimerNotifierProvider(60), (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(examTimerNotifierProvider(60).notifier);
        notifier.start(() {});

        fake.elapse(const Duration(seconds: 5));
        expect(container.read(examTimerNotifierProvider(60)), 55);

        notifier.pause();
        fake.elapse(const Duration(seconds: 10));

        // Should still be 55, not 45
        expect(container.read(examTimerNotifierProvider(60)), 55);
      });
    });

    test('updateFromServer overrides current value', () {
      fakeAsync((fake) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(examTimerNotifierProvider(60), (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(examTimerNotifierProvider(60).notifier);
        notifier.start(() {});

        fake.elapse(const Duration(seconds: 10));
        expect(container.read(examTimerNotifierProvider(60)), 50);

        notifier.updateFromServer(3600);
        expect(container.read(examTimerNotifierProvider(60)), 3600);
      });
    });
  });
}
