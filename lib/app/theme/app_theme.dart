import 'package:flutter/material.dart';

/// Spacing scale shared by every screen.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.all(lg);
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

/// Brand and semantic colours used for statuses and alerts.
abstract final class AppColors {
  static const Color seed = Color(0xFF4458F0);
  static const Color brand = Color(0xFF4458F0);
  static const Color brandDeep = Color(0xFF2C2FB8);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color teal = Color(0xFF14B8A6);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
  static const Color neutral = Color(0xFF64748B);

  static const Color lightBackground = Color(0xFFF1F4FB);
  static const Color darkBackground = Color(0xFF0E1222);

  /// Hero gradient used on headers, the login screen and primary orbs.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B6CFF), Color(0xFF4338CA), Color(0xFF7C3AED)],
    stops: [0, 0.55, 1],
  );
}

/// Layered shadows that give surfaces a raised, physical feel.
abstract final class AppShadows {
  static List<BoxShadow> raised(Color tint, {bool dark = false}) => [
    BoxShadow(
      color: (dark ? Colors.black : tint).withValues(alpha: dark ? 0.45 : 0.16),
      blurRadius: 28,
      spreadRadius: -6,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: (dark ? Colors.black : const Color(0xFF1E2550)).withValues(
        alpha: dark ? 0.35 : 0.07,
      ),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.45),
      blurRadius: 18,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    final scheme = base.copyWith(
      primary: dark ? const Color(0xFF8E9BFF) : AppColors.brand,
      surface: dark ? AppColors.darkBackground : AppColors.lightBackground,
      surfaceContainerLowest: dark ? const Color(0xFF161B31) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF1A2038) : Colors.white,
      surfaceContainer: dark
          ? const Color(0xFF1E2540)
          : const Color(0xFFF7F8FD),
      outlineVariant: dark ? const Color(0xFF2B3354) : const Color(0xFFE2E6F3),
    );
    final shadowTint = dark ? Colors.black : AppColors.brandDeep;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      // Merged over the platform defaults by ThemeData.
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowTint.withValues(alpha: dark ? 0.6 : 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          elevation: 6,
          shadowColor: scheme.primary.withValues(alpha: 0.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          backgroundColor: scheme.surfaceContainerLowest,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        highlightElevation: 12,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        elevation: 2,
        pressElevation: 0,
        shadowColor: shadowTint.withValues(alpha: 0.25),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.25 : 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.7),
        space: 1,
      ),
    );
  }
}
