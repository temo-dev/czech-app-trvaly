import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_spacing.dart';
import 'package:app_czech/shared/widgets/offline_banner.dart';
import 'package:app_czech/shared/widgets/bottom_nav_bar.dart';
import 'widgets/side_rail_nav.dart';

/// Root authenticated scaffold.
/// Mobile/tablet  → custom AppBottomNavBar (rounded-t-2xl, backdrop blur)
/// Web (≥ 900px) → persistent left NavigationRail + content maxWidth 1200
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    ShellTab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
      route: AppRoutes.dashboard,
    ),
    ShellTab(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Học',
      route: AppRoutes.courses,
    ),
    ShellTab(
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
      label: 'Luyện đề',
      route: AppRoutes.practiceIntro,
    ),
    ShellTab(
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
      label: 'Xếp hạng',
      route: AppRoutes.leaderboard,
    ),
    ShellTab(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Cá nhân',
      route: AppRoutes.profile,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    context.go(_tabs[index].route);
  }

  List<BottomNavItem> get _navItems => _tabs
      .map((t) => BottomNavItem(
            icon: t.icon,
            activeIcon: t.activeIcon,
            label: t.label,
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final selectedIndex = _selectedIndex(context);

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Row(
                children: [
                  SideRailNav(
                    tabs: _tabs,
                    selectedIndex: selectedIndex,
                    onTap: (i) => _onTabTap(context, i),
                  ),
                  Container(
                    width: 1,
                    color: AppColors.outlineVariant,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: _navItems,
        currentIndex: selectedIndex,
        onTap: (i) => _onTabTap(context, i),
      ),
    );
  }
}

class ShellTab {
  const ShellTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}
