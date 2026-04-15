import 'package:go_router/go_router.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/shared/providers/subscription_provider.dart';

/// Redirects free-tier users to paywall.
/// Applied to: /app/simulator/**, /app/speaking/**, /app/writing/**
String? subscriptionGuard(GoRouterState state, SubscriptionStatus status) {
  if (status == SubscriptionStatus.active) return null;
  final from = Uri.encodeComponent(state.uri.toString());
  return '${AppRoutes.subscribe}?from=$from';
}
