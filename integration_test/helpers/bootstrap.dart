import 'package:app_czech/app.dart';
import 'package:app_czech/core/env/app_env.dart';
import 'package:app_czech/core/storage/prefs_storage.dart';
import 'package:app_czech/core/supabase/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

bool _didInitializeApp = false;

Future<void> pumpRealApp(WidgetTester tester) async {
  if (!_didInitializeApp) {
    AppEnv.validate();
    await PrefsStorage.init();
    await initSupabase();
    _didInitializeApp = true;
  }

  await tester.pumpWidget(const ProviderScope(child: App()));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}
