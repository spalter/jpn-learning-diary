/// Theme configuration for the Japanese Learning Diary application.
///
/// This class centralizes all theme-related constants including:
/// - Tokyo Night Storm color palette (dark mode)
/// - Tokyo Day color palette (light mode)
/// - Common styling values (alpha transparency, etc.)
library;

import 'package:flutter/material.dart';

/// Centralized theme configuration containing all app colors and styling constants.
///
/// Uses Tokyo Night theme variants for a modern, cohesive design language.
class AppTheme {
  /// The display name of the application.
  static const String appTitle = 'Japanese Learning Diary';

  /// Returns the scaffold background color with semi-transparency applied.
  ///
  /// This creates a modern, translucent effect allowing content behind
  /// the scaffold to show through subtly in dark mode, while keeping
  /// the light mode fully opaque.
  ///
  /// [context] The build context to access the current theme.
  /// Returns a Color with the configured alpha transparency applied.
  static Color scaffoldBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final alpha = brightness == Brightness.dark ? 150 : 255;
    return Theme.of(context).colorScheme.surface.withAlpha(alpha);
  }

  /// Returns the light theme configuration using Tokyo Day colors.
  ///
  /// Configures primary, secondary, tertiary, error, surface, and text colors.
  /// Uses Material 3 design language.
  static ThemeData getTokyoDayTheme() {
    return ThemeData(
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFe1e2e7),
        primary: const Color(0xFF2e7de9),
        surfaceTint: const Color(0xFF6172b0),
        secondary: const Color(0xFF9854f1),
        tertiary: const Color(0xFF007197),
        error: const Color(0xFFf52a65),
        onSurface: const Color(0xFF6172b0),
        onPrimary: const Color(0xFFd5d6db),
        onSecondary: const Color(0xFFd5d6db),
      ),
      useMaterial3: true,
    );
  }

  /// Returns the dark theme configuration using Tokyo Night Storm colors.
  ///
  /// Configures primary, secondary, tertiary, error, surface, and text colors.
  /// Uses Material 3 design language.
  static ThemeData getTokyoNightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF1f2335),
        primary: const Color(0xFF7aa2f7),
        secondary: const Color(0xFFbb9af7),
        tertiary: const Color(0xFF7dcfff),
        error: const Color(0xFFf7768e),
        onSurface: const Color(0xFFa9b1d6),
        onPrimary: const Color(0xFF24283b),
        onSecondary: const Color(0xFF24283b),
      ),
      useMaterial3: true,
    );
  }
}
