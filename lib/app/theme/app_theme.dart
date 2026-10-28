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

/// Brand accent and semantic colours, shared by both themes. Surface and
/// text colours differ per theme; read those from [AppPalette].
abstract final class AppColors {
  static const Color amber = Color(0xFFFFB224);
  static const Color amberDeep = Color(0xFFF08C00);
  static const Color amberSoft = Color(0xFFFFD27A);
  static const Color onAmber = Color(0xFF1A1A1D);

  // Accent aliases used by screens for per-item variety.
  static const Color seed = amber;
  static const Color brand = amber;
  static const Color brandDeep = amberDeep;
  static const Color violet = Color(0xFFF5A524);
  static const Color teal = Color(0xFFFF8A3D);

  // Mid-tones that stay legible on both charcoal and white.
  static const Color success = Color(0xFF22A55A);
  static const Color warning = Color(0xFFE08A00);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF2E90D9);
  static const Color neutral = Color(0xFF8A8A93);

  /// Amber gradient for primary orbs, avatars and key accents.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFCB5C), amber, amberDeep],
  );
}

/// Theme-dependent surface, text and depth colours.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.text,
    required this.textMuted,
    required this.accentText,
    required this.dialLight,
    required this.dialDark,
    required this.edge,
    required this.shadow,
    required this.glowStrength,
  });

  /// Charcoal instrument panel.
  static const dark = AppPalette(
    background: Color(0xFF151518),
    surface: Color(0xFF212126),
    surfaceHigh: Color(0xFF2A2A30),
    outline: Color(0xFF34343C),
    text: Color(0xFFF4F4F5),
    textMuted: Color(0xFFA1A1AA),
    accentText: AppColors.amber,
    dialLight: Color(0xFF3A3A42),
    dialDark: Color(0xFF1B1B20),
    edge: Color(0x12FFFFFF),
    shadow: Color(0x8C000000),
    glowStrength: 1,
  );

  /// Warm off-white panel with the same amber accents.
  static const light = AppPalette(
    background: Color(0xFFF4F2EE),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFFBF8F3),
    outline: Color(0xFFE6E1D8),
    text: Color(0xFF1C1B1F),
    textMuted: Color(0xFF6B6872),
    accentText: Color(0xFFB45F00),
    dialLight: Color(0xFFFFFFFF),
    dialDark: Color(0xFFEDE8DF),
    edge: Color(0xFFFFFFFF),
    shadow: Color(0x2E5A4630),
    glowStrength: 0.7,
  );

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color text;
  final Color textMuted;

  /// Amber tuned for text contrast on [surface].
  final Color accentText;

  /// Highlight and base of the domed icon dials and gauge faces.
  final Color dialLight;
  final Color dialDark;

  /// Lit top edge of raised surfaces.
  final Color edge;

  /// Ambient shadow under raised surfaces.
  final Color shadow;

  /// Multiplier for coloured glows (softer on light backgrounds).
  final double glowStrength;

  bool get isDark => background.computeLuminance() < 0.2;

  LinearGradient get surfaceGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceHigh, surface],
  );

  LinearGradient get panelGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? const [Color(0xFF2E2E35), Color(0xFF1C1C21)]
        : const [Color(0xFFFFFFFF), Color(0xFFFAF4EA)],
  );

  /// Layered shadow for raised cards.
  List<BoxShadow> get raised => [
    BoxShadow(
      color: shadow,
      blurRadius: 26,
      spreadRadius: -6,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: shadow.a * 0.6),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

abstract final class AppShadows {
  static List<BoxShadow> glow(Color color, [double strength = 1]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35 * strength),
      blurRadius: 18,
      spreadRadius: -4,
      offset: const Offset(0, 6),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.amber,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.amber,
          onPrimary: AppColors.onAmber,
          primaryContainer: AppColors.amber.withValues(alpha: 0.18),
          onPrimaryContainer: p.accentText,
          secondary: p.accentText,
          onSecondary: AppColors.onAmber,
          secondaryContainer: p.surfaceHigh,
          onSecondaryContainer: p.text,
          tertiaryContainer: p.surfaceHigh,
          onTertiaryContainer: p.text,
          surface: p.background,
          onSurface: p.text,
          onSurfaceVariant: p.textMuted,
          surfaceContainerLowest: p.surface,
          surfaceContainerLow: p.surface,
          surfaceContainer: p.surfaceHigh,
          surfaceContainerHigh: p.surfaceHigh,
          surfaceContainerHighest: p.outline,
          outline: p.textMuted.withValues(alpha: 0.6),
          outlineVariant: p.outline,
          error: AppColors.danger,
        );
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
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
        centerTitle: true,
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.text,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: p.isDark ? 8 : 4,
        margin: EdgeInsets.zero,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: p.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: p.isDark ? p.edge : p.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: p.textMuted),
        floatingLabelStyle: TextStyle(color: p.accentText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.outline),
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
          disabledBackgroundColor: p.surfaceHigh,
          elevation: 6,
          shadowColor: AppColors.amber.withValues(alpha: 0.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: p.accentText,
          side: const BorderSide(color: AppColors.amber, width: 1.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentText,
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
        style: IconButton.styleFrom(foregroundColor: p.text),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: p.textMuted,
        subtitleTextStyle: TextStyle(color: p.textMuted, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: p.outline),
        backgroundColor: p.surface,
        selectedColor: AppColors.amber.withValues(alpha: 0.2),
        checkmarkColor: p.accentText,
        labelStyle: TextStyle(color: p.text),
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.amber.withValues(alpha: 0.18),
        indicatorShape: pill,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? p.accentText
                : p.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.accentText
                : p.textMuted,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.accentText,
        unselectedLabelColor: p.textMuted,
        indicatorColor: AppColors.amber,
        dividerColor: p.outline,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amber,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.onAmber
              : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.amber
              : p.surfaceHigh,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: p.surface),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceHigh,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.surfaceHigh : const Color(0xFF2A2A30),
        contentTextStyle: const TextStyle(color: Color(0xFFF4F4F5)),
        actionTextColor: AppColors.amber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.textMuted,
          selectedBackgroundColor: AppColors.amber,
          selectedForegroundColor: AppColors.onAmber,
          side: BorderSide(color: p.outline),
          shape: pill,
        ),
      ),
      dividerTheme: DividerThemeData(color: p.outline, space: 1),
    );
  }
}
