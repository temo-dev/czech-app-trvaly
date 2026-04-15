import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

/// Builds Material 3 ThemeData from Sahara design tokens.
///
/// Key Sahara rules (from HTML designs):
///   - Scaffold bg: #faf5ee (warm linen) — NEVER white
///   - AppBar: flat, surface bg, border-b outlineVariant/60
///   - Buttons: rounded-xl (12px), min height 52px
///   - Inputs: rounded-lg (8px), white fill, focus ring primary
///   - Cards: rounded-xl (12px), border outlineVariant/60, shadow card
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: isLight ? AppColors.surface : AppColors.surfaceDark,
      onSurface: isLight ? AppColors.onSurface : AppColors.onSurfaceDark,
      surfaceContainerHighest: isLight
          ? AppColors.surfaceContainerHighest
          : AppColors.surfaceVariantDark,
      surfaceContainerHigh: isLight
          ? AppColors.surfaceContainerHigh
          : AppColors.surfaceVariantDark,
      surfaceContainer: isLight
          ? AppColors.surfaceContainer
          : AppColors.surfaceVariantDark,
      surfaceContainerLow: isLight
          ? AppColors.surfaceContainerLow
          : AppColors.surfaceDark,
      surfaceContainerLowest: isLight
          ? AppColors.surfaceContainerLowest
          : AppColors.backgroundDark,
      onSurfaceVariant: isLight
          ? AppColors.onSurfaceVariant
          : AppColors.onSurfaceMutedDark,
      outline: isLight ? AppColors.outline : AppColors.outlineDark,
      outlineVariant: isLight ? AppColors.outlineVariant : AppColors.borderDark,
      inverseSurface: isLight
          ? AppColors.inverseSurfaceLight
          : AppColors.inverseSurfaceDark,
      onInverseSurface: isLight
          ? AppColors.inverseOnSurfaceLight
          : AppColors.inverseOnSurfaceDark,
      inversePrimary: AppColors.inversePrimary,
      scrim: AppColors.scrim,
      surfaceTint: AppColors.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      // KEY: warm linen bg — never white
      scaffoldBackgroundColor: isLight
          ? AppColors.surface
          : AppColors.backgroundDark,

      // ── AppBar — flat, warm, border-b ────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.surface : AppColors.surfaceDark,
        foregroundColor: isLight ? AppColors.onSurface : AppColors.onSurfaceDark,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: isLight ? AppColors.onSurface : AppColors.onSurfaceDark,
        ),
        iconTheme: IconThemeData(
          color: isLight ? AppColors.onSurface : AppColors.onSurfaceDark,
          size: 24,
        ),
        shape: isLight
            ? Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.6),
                  width: 1,
                ),
              )
            : null,
      ),

      // ── Cards — rounded-xl (12px), soft border, card shadow ──────────────
      cardTheme: CardThemeData(
        color: isLight
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md), // 12px
          side: BorderSide(
            color: isLight
                ? AppColors.outlineVariant.withOpacity(0.6)
                : AppColors.borderDark,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Filled buttons — primary, rounded-xl (12px), min 52px ────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md), // 12px
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),

      // ── Outlined buttons — warm border, primary text ──────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: AppTypography.labelLarge,
          side: BorderSide(
            color: AppColors.outlineVariant,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // ── Text buttons ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Inputs — rounded-lg (8px), white fill, primary focus ─────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm), // 8px
          borderSide: BorderSide(
            color: isLight ? AppColors.outlineVariant : AppColors.borderDark,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: isLight ? AppColors.outlineVariant : AppColors.borderDark,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14, // py-3.5
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isLight
              ? AppColors.onSurfaceVariant
              : AppColors.onSurfaceMutedDark,
        ),
        labelStyle: AppTypography.bodyMedium,
        floatingLabelStyle:
            AppTypography.labelMedium.copyWith(color: AppColors.primary),
      ),

      // ── Dividers ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isLight
            ? AppColors.outlineVariant.withOpacity(0.4)
            : AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      // ── Navigation bar (fallback — we use custom BottomNavBar widget) ─────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isLight ? AppColors.surface : AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(
            color: isLight
                ? AppColors.onSurfaceVariant
                : AppColors.onSurfaceMutedDark,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: isLight
                ? AppColors.onSurfaceVariant
                : AppColors.onSurfaceMutedDark,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Navigation rail (web sidebar) ────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isLight ? AppColors.surface : AppColors.surfaceDark,
        selectedIconTheme:
            const IconThemeData(color: AppColors.primary, size: 24),
        unselectedIconTheme: IconThemeData(
          color: isLight
              ? AppColors.onSurfaceVariant
              : AppColors.onSurfaceMutedDark,
          size: 24,
        ),
        indicatorColor: AppColors.primary.withOpacity(0.12),
        selectedLabelTextStyle: AppTypography.labelSmall
            .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: AppTypography.labelSmall.copyWith(
          color: isLight
              ? AppColors.onSurfaceVariant
              : AppColors.onSurfaceMutedDark,
        ),
        elevation: 0,
      ),

      // ── Snackbars ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppColors.inverseSurfaceLight
            : AppColors.inverseSurfaceDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isLight
              ? AppColors.inverseOnSurfaceLight
              : AppColors.inverseOnSurfaceDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        elevation: 4,
      ),

      // ── Chips — rounded-full pills ────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainer
            : AppColors.surfaceVariantDark,
        selectedColor: AppColors.primaryFixed,
        labelStyle: AppTypography.labelMedium,
        side: BorderSide(
          color: isLight ? AppColors.outlineVariant : AppColors.borderDark,
          width: 1,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.full)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── List tiles ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 0,
        style: ListTileStyle.list,
        titleTextStyle: AppTypography.bodyMedium.copyWith(
          color: isLight ? AppColors.onSurface : AppColors.onSurfaceDark,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: isLight
              ? AppColors.onSurfaceVariant
              : AppColors.onSurfaceMutedDark,
        ),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        elevation: 8,
        shadowColor: const Color(0x1A3A302A),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        elevation: 8,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isLight ? AppColors.onSurface : AppColors.onSurfaceDark,
        ),
      ),

      // ── Page transitions — smooth Cupertino on all platforms ─────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
