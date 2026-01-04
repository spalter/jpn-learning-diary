/// Retro CRT-style theme configuration for the Japanese Learning Diary application.
///
/// Provides old-school terminal aesthetic with:
/// - Sharp edges (no rounded corners)
/// - Monochrome color schemes (phosphor green, amber, cyan, white)
/// - CRT-style visual effects
library;

import 'package:flutter/material.dart';

/// Available retro color schemes inspired by classic CRT monitors.
enum RetroColorScheme {
  /// Classic green phosphor (P1) - typical of early terminals
  phosphorGreen,

  /// Amber phosphor (P3) - common in IBM terminals
  amber,

  /// Cyan/blue-white - reminiscent of early vector displays
  cyan,

  /// White phosphor - like early Apple/Macintosh displays
  white,

  /// Blue terminal style
  blue,
}

/// Configuration for retro visual effects.
class RetroEffectsConfig {
  /// Whether scanlines are enabled.
  final bool scanlinesEnabled;

  /// Opacity of the scanline effect (0.0 - 1.0).
  final double scanlineOpacity;

  /// Spacing between scanlines in pixels.
  final double scanlineSpacing;

  /// Whether to show a subtle CRT curvature vignette effect.
  final bool vignetteEnabled;

  /// Whether to show a subtle screen flicker effect.
  final bool flickerEnabled;

  /// Whether to show a glow effect on text/UI elements.
  final bool glowEnabled;

  const RetroEffectsConfig({
    this.scanlinesEnabled = true,
    this.scanlineOpacity = 0.08,
    this.scanlineSpacing = 3.0,
    this.vignetteEnabled = true,
    this.flickerEnabled = false,
    this.glowEnabled = true,
  });

  /// Default configuration with all effects enabled at subtle levels.
  static const RetroEffectsConfig defaultConfig = RetroEffectsConfig();

  /// Minimal configuration with only essential effects.
  static const RetroEffectsConfig minimal = RetroEffectsConfig(
    scanlinesEnabled: true,
    scanlineOpacity: 0.05,
    vignetteEnabled: false,
    flickerEnabled: false,
    glowEnabled: false,
  );

  /// No effects - just the color scheme.
  static const RetroEffectsConfig none = RetroEffectsConfig(
    scanlinesEnabled: false,
    vignetteEnabled: false,
    flickerEnabled: false,
    glowEnabled: false,
  );

  RetroEffectsConfig copyWith({
    bool? scanlinesEnabled,
    double? scanlineOpacity,
    double? scanlineSpacing,
    bool? vignetteEnabled,
    bool? flickerEnabled,
    bool? glowEnabled,
  }) {
    return RetroEffectsConfig(
      scanlinesEnabled: scanlinesEnabled ?? this.scanlinesEnabled,
      scanlineOpacity: scanlineOpacity ?? this.scanlineOpacity,
      scanlineSpacing: scanlineSpacing ?? this.scanlineSpacing,
      vignetteEnabled: vignetteEnabled ?? this.vignetteEnabled,
      flickerEnabled: flickerEnabled ?? this.flickerEnabled,
      glowEnabled: glowEnabled ?? this.glowEnabled,
    );
  }
}

/// Color palette for a specific retro color scheme.
class RetroColorPalette {
  /// The main foreground/text color (bright).
  final Color primary;

  /// Secondary foreground color (medium brightness).
  final Color secondary;

  /// Dim/muted foreground color.
  final Color dim;

  /// Background color (dark).
  final Color background;

  /// Surface color (slightly lighter than background).
  final Color surface;

  /// Border/outline color.
  final Color border;

  /// Highlight/selection color.
  final Color highlight;

  /// Error/warning color.
  final Color error;

  /// Glow color for effects.
  final Color glow;

  const RetroColorPalette({
    required this.primary,
    required this.secondary,
    required this.dim,
    required this.background,
    required this.surface,
    required this.border,
    required this.highlight,
    required this.error,
    required this.glow,
  });
}

/// Centralized retro theme configuration.
class RetroTheme {
  /// Returns the color palette for a given color scheme.
  static RetroColorPalette getPalette(RetroColorScheme scheme) {
    switch (scheme) {
      case RetroColorScheme.phosphorGreen:
        return const RetroColorPalette(
          primary: Color(0xFF33FF33),
          secondary: Color(0xFF22CC22),
          dim: Color(0xFF116611),
          background: Color(0xFF0A0A0A),
          surface: Color(0xFF111611),
          border: Color(0xFF22AA22),
          highlight: Color(0xFF44FF44),
          error: Color(0xFFFF3333),
          glow: Color(0xFF33FF33),
        );

      case RetroColorScheme.amber:
        return const RetroColorPalette(
          primary: Color(0xFFFFB833),
          secondary: Color(0xFFCC9922),
          dim: Color(0xFF665511),
          background: Color(0xFF0A0800),
          surface: Color(0xFF151208),
          border: Color(0xFFAA8822),
          highlight: Color(0xFFFFCC44),
          error: Color(0xFFFF4444),
          glow: Color(0xFFFFB833),
        );

      case RetroColorScheme.cyan:
        return const RetroColorPalette(
          primary: Color(0xFF33FFFF),
          secondary: Color(0xFF22CCCC),
          dim: Color(0xFF116666),
          background: Color(0xFF0A0A0D),
          surface: Color(0xFF0F1115),
          border: Color(0xFF22AAAA),
          highlight: Color(0xFF44FFFF),
          error: Color(0xFFFF3366),
          glow: Color(0xFF33FFFF),
        );

      case RetroColorScheme.white:
        return const RetroColorPalette(
          primary: Color(0xFFEEEEEE),
          secondary: Color(0xFFBBBBBB),
          dim: Color(0xFF666666),
          background: Color(0xFF0A0A0A),
          surface: Color(0xFF141414),
          border: Color(0xFF888888),
          highlight: Color(0xFFFFFFFF),
          error: Color(0xFFFF4444),
          glow: Color(0xFFFFFFFF),
        );

      case RetroColorScheme.blue:
        return const RetroColorPalette(
          primary: Color(0xFF3388FF),
          secondary: Color(0xFF2266CC),
          dim: Color(0xFF113366),
          background: Color(0xFF080810),
          surface: Color(0xFF0D0D18),
          border: Color(0xFF2255AA),
          highlight: Color(0xFF44AAFF),
          error: Color(0xFFFF4466),
          glow: Color(0xFF3388FF),
        );
    }
  }

  /// Returns the display name for a color scheme.
  static String getSchemeName(RetroColorScheme scheme) {
    switch (scheme) {
      case RetroColorScheme.phosphorGreen:
        return 'Phosphor Green';
      case RetroColorScheme.amber:
        return 'Amber';
      case RetroColorScheme.cyan:
        return 'Cyan';
      case RetroColorScheme.white:
        return 'White';
      case RetroColorScheme.blue:
        return 'Blue';
    }
  }

  /// Returns a Flutter ThemeData configured for the retro style.
  static ThemeData getThemeData(RetroColorScheme scheme) {
    final palette = getPalette(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,

      // Color scheme
      colorScheme: ColorScheme.dark(
        surface: palette.surface,
        primary: palette.primary,
        secondary: palette.secondary,
        tertiary: palette.dim,
        error: palette.error,
        onSurface: palette.primary,
        onPrimary: palette.background,
        onSecondary: palette.background,
        outline: palette.border,
        inversePrimary: palette.surface,
      ),

      // AppBar theme - sharp edges
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.primary,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1),
        ),
        titleTextStyle: TextStyle(
          color: palette.primary,
          fontSize: 16,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: palette.primary),
      ),

      // Card theme - sharp edges
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: palette.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button themes - sharp edges
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.surface,
          foregroundColor: palette.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: palette.border, width: 1),
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: palette.border, width: 1),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.primary,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),

      // Input decoration - sharp edges
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.background,
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: palette.error, width: 1),
        ),
        labelStyle: TextStyle(color: palette.secondary, fontFamily: 'monospace'),
        hintStyle: TextStyle(color: palette.dim, fontFamily: 'monospace'),
        prefixIconColor: palette.secondary,
        suffixIconColor: palette.secondary,
      ),

      // Dialog theme - sharp edges
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: palette.border, width: 2),
        ),
        titleTextStyle: TextStyle(
          color: palette.primary,
          fontSize: 18,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),

      // Popup menu theme - sharp edges
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: palette.border, width: 1),
        ),
        textStyle: TextStyle(color: palette.primary, fontFamily: 'monospace'),
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border, width: 1),
        ),
        textStyle: TextStyle(color: palette.primary, fontFamily: 'monospace'),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(palette.background),
        side: BorderSide(color: palette.border, width: 2),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.dim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary.withOpacity(0.3);
          }
          return palette.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(palette.border),
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.primary,
        inactiveTrackColor: palette.border,
        thumbColor: palette.primary,
        overlayColor: palette.primary.withOpacity(0.2),
        trackShape: const RectangularSliderTrackShape(),
        thumbShape: const RectSliderThumbShape(),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.border,
        circularTrackColor: palette.border,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface,
        contentTextStyle: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: palette.primary,
        unselectedLabelColor: palette.dim,
        indicatorColor: palette.primary,
        dividerColor: palette.border,
        labelStyle: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontFamily: 'monospace'),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.surface,
        foregroundColor: palette.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: palette.border, width: 2),
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        labelStyle: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        side: BorderSide(color: palette.border, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.primary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: palette.primary, fontFamily: 'monospace', fontSize: 12),
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        textColor: palette.primary,
        iconColor: palette.secondary,
        tileColor: Colors.transparent,
        selectedTileColor: palette.primary.withOpacity(0.1),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        displayMedium: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        displaySmall: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        headlineLarge: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        headlineMedium: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        headlineSmall: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        titleLarge: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        titleMedium: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        titleSmall: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        bodyLarge: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        bodyMedium: TextStyle(color: palette.secondary, fontFamily: 'monospace'),
        bodySmall: TextStyle(color: palette.dim, fontFamily: 'monospace'),
        labelLarge: TextStyle(color: palette.primary, fontFamily: 'monospace'),
        labelMedium: TextStyle(color: palette.secondary, fontFamily: 'monospace'),
        labelSmall: TextStyle(color: palette.dim, fontFamily: 'monospace'),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: palette.primary),
    );
  }
}

/// Custom rectangular slider thumb shape.
class RectSliderThumbShape extends SliderComponentShape {
  const RectSliderThumbShape({this.enabledThumbRadius = 6.0});

  final double enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: enabledThumbRadius * 2,
        height: enabledThumbRadius * 2,
      ),
      paint,
    );
  }
}
