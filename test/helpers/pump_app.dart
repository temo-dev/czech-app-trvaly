import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

/// Extension that wraps [widget] in a [ProviderScope] + [MaterialApp] for
/// widget tests. Always call this instead of bare [pumpWidget].
///
/// Usage:
/// ```dart
/// await tester.pumpApp(const LoginScreen(), overrides: [
///   authNotifierProvider.overrideWith(FakeAuthNotifier.new),
/// ]);
/// ```
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await mockNetworkImagesFor(() async {
      await pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            home: widget,
            // Suppress GoRouter "no location" errors in unit widget tests
            // by providing a simple Navigator-based host.
          ),
        ),
      );
      await pumpAndSettle();
    });
  }

  /// Pump without settling — use when you want to inspect loading states.
  Future<void> pumpAppNoSettle(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await mockNetworkImagesFor(() async {
      await pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(home: widget),
        ),
      );
    });
  }
}
