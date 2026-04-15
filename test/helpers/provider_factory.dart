import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a [ProviderContainer] with [overrides] and registers [dispose]
/// via [addTearDown] so tests don't need to manage lifecycle manually.
///
/// Usage:
/// ```dart
/// final container = createContainer(overrides: [
///   myProvider.overrideWith(() => FakeNotifier()),
/// ]);
/// ```
ProviderContainer createContainer({
  List<Override> overrides = const [],
  ProviderContainer? parent,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides,
  );
  addTearDown(container.dispose);
  return container;
}
