import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_czech/app.dart';

/// Smoke test: the app boots without crashing and renders something.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to landing or dashboard without crash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // App rendered without throwing
    expect(tester.takeException(), isNull);
  });
}
