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

/// Charcoal-and-amber palette. Accent colours stay in the amber family so
/// the app reads as one instrument panel; red/green are kept for meaning.
abstract final class AppColors {
  static const Color amber = Color(0xFFFFB224);
  static const Color amberDeep = Color(0xFFF08C00);
  static const Color amberSoft = Color(0xFFFFD27A);
  static const Color onAmber = Color(0xFF1A1A1D);

  // Accent aliases used by screens for per-item variety.
  static const Color seed = amber;
  static const Color brand = amber;
  static const Color brandDeep = amberDeep;
  static const Color violet = amberSoft;
  static const Color teal = Color(0xFFFF8A3D);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF7DD3FC);
  static const Color neutral = Color(0xFFA1A1AA);

  static const Color background = Color(0xFF151518);
  static const Color surface = Color(0xFF212126);
  static const Color surfaceHigh = Color(0xFF2A2A30);
  static const Color outline = Color(0xFF34343C);
  static const Color text = Color(0xFFF4F4F5);
  static const Color textMuted = Color(0xFFA1A1AA);

  /// Amber gradient for primary orbs, avatars and key accents.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFCB5C), amber, amberDeep],
  );

  /// Dark panel gradient used by hero panels.
  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E2E35), Color(0xFF1C1C21)],
  );
}

/// Layered shadows that give surfaces a raised, physical feel.
abstract final class AppShadows {
  static List<BoxShadow> raised(Color tint, {bool dark = true}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.55),
      blurRadius: 26,
      spreadRadius: -6,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 18,
      spreadRadius: -4,
      offset: const Offset(0, 6),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.amber,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.amber,
          onPrimary: AppColors.onAmber,
          primaryContainer: AppColors.amber.withValues(alpha: 0.18),
          onPrimaryContainer: AppColors.amberSoft,
          secondary: AppColors.amberSoft,
          onSecondary: AppColors.onAmber,
          secondaryContainer: AppColors.surfaceHigh,
          onSecondaryContainer: AppColors.text,
          tertiaryContainer: AppColors.surfaceHigh,
          onTertiaryContainer: AppColors.text,
          surface: AppColors.background,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.textMuted,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.surface,
          surfaceContainer: AppColors.surfaceHigh,
          surfaceContainerHigh: AppColors.surfaceHigh,
          surfaceContainerHighest: const Color(0xFF34343B),
          outline: const Color(0xFF55555E),
          outlineVariant: AppColors.outline,
          error: AppColors.danger,
        );
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
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
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.amber),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.onAmber,
          disabledBackgroundColor: AppColors.surfaceHigh,
          elevation: 6,
          shadowColor: AppColors.amber.withValues(alpha: 0.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: AppColors.amber,
          side: const BorderSide(color: AppColors.amber, width: 1.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amber,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        highlightElevation: 12,
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.onAmber,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: pill,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.text),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.textMuted,
        subtitleTextStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: AppColors.outline),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.amber.withValues(alpha: 0.2),
        checkmarkColor: AppColors.amber,
        labelStyle: const TextStyle(color: AppColors.text),
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.amber.withValues(alpha: 0.16),
        indicatorShape: pill,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.amber
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.amber
                : AppColors.textMuted,
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.amber,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.amber,
        dividerColor: AppColors.outline,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amber,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.onAmber
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.amber
              : AppColors.surfaceHigh,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.surface,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.text),
        actionTextColor: AppColors.amber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textMuted,
          selectedBackgroundColor: AppColors.amber,
          selectedForegroundColor: AppColors.onAmber,
          side: const BorderSide(color: AppColors.outline),
          shape: pill,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outline, space: 1),
    );
  }
}
