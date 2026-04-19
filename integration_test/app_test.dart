import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/bootstrap.dart';

/// Smoke test: the app boots without crashing and renders something.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to landing or dashboard without crash',
      (tester) async {
    await pumpRealApp(tester);

    // App rendered without throwing
    expect(tester.takeException(), isNull);
  });
}
