import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_czech/features/dashboard/models/dashboard_models.dart';
import 'package:app_czech/features/dashboard/providers/dashboard_provider.dart';
import 'package:app_czech/features/dashboard/screens/dashboard_screen.dart';
import 'package:app_czech/shared/models/user_model.dart';
import 'package:app_czech/shared/widgets/error_state.dart';
import 'package:app_czech/shared/widgets/loading_shimmer.dart';
import '../../helpers/pump_app.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _fakeUser = AppUser.fromJson({
  'id': 'user-001',
  'email': 'test@example.com',
  'displayName': 'Minh Tú',
  'currentStreakDays': 7,
  'totalXp': 1240,
});

final _fakeDashboardData = DashboardData(
  user: _fakeUser,
  latestResult: null,
  recommendation: null,
  leaderboardPreview: const [],
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DashboardScreen — loading state', () {
    testWidgets('shows shimmer skeleton while loading', (tester) async {
      // Use a never-completing Completer — avoids pending-timer assertion
      // while keeping the provider in AsyncLoading state.
      final completer = Completer<DashboardData>();
      await tester.pumpAppNoSettle(
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((_) => completer.future),
        ],
      );
      await tester.pump();
      expect(find.byType(LoadingShimmer), findsAtLeastNWidgets(1));
    });
  });

  group('DashboardScreen — error state', () {
    testWidgets('shows ErrorState with retry on failure', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith(
            (_) => throw Exception('Network error'),
          ),
        ],
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });

  group('DashboardScreen — data state', () {
    testWidgets('renders user greeting when data loads', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((_) async => _fakeDashboardData),
        ],
      );

      // Dashboard shows greeting with first name
      expect(find.textContaining('Minh'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show shimmer after data loads', (tester) async {
      await tester.pumpApp(
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((_) async => _fakeDashboardData),
        ],
      );

      expect(find.byType(LoadingShimmer), findsNothing);
    });
  });
}
