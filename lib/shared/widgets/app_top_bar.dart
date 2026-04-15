import 'package:flutter/material.dart';
import 'package:app_czech/core/theme/app_typography.dart';

/// Standard inner-screen AppBar.
/// Pass [showBack] = true (default) to render a back chevron.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.bottom,
  });

  final String title;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTypography.titleMedium),
      centerTitle: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: false,
      actions: actions,
      bottom: bottom,
    );
  }
}
