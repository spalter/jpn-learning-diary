// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

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

    /// Semi-transparent in dark mode for darker background, opaque in light mode for lighter background
    final alpha = brightness == Brightness.dark ? 150 : 255;
    return Theme.of(context).colorScheme.surface.withAlpha(alpha);
  }

  /// Returns a black-and-white theme based on the current brightness.
  ///
  /// [context] The build context to access the current theme.
  /// Returns a ThemeData object configured for black (dark) or white (light) theme.
  static ThemeData getBlackWhiteTheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? getBlackTheme() : getWhiteTheme();
  }

  /// Returns the appropriate Tokyo-themed configuration based on system brightness.
  ///
  /// [context] The build context to access the current theme.
  /// Returns a ThemeData object configured for Tokyo Day (light) or Tokyo Night (dark).
  static ThemeData getTokyoStyledTheme(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return getTokyoNightTheme();
    } else {
      return getTokyoDayTheme();
    }
  }

  /// Returns the light theme configuration using Tokyo Day colors.
  ///
  /// Configures primary, secondary, tertiary, error, surface, and text colors.
  /// Uses Material 3 design language.
  static ThemeData getTokyoDayTheme() {
    const primary = Color(0xFF2e7de9);
    return ThemeData(
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFe1e2e7),
        primary: primary,
        surfaceTint: const Color(0xFF6172b0),
        secondary: const Color(0xFF9854f1),
        tertiary: const Color(0xFF007197),
        error: const Color(0xFFf52a65),
        onSurface: const Color(0xFF6172b0),
        onPrimary: const Color(0xFFd5d6db),
        onSecondary: const Color(0xFFd5d6db),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }

  /// Returns the dark theme configuration using Tokyo Night Storm colors.
  ///
  /// Configures primary, secondary, tertiary, error, surface, and text colors.
  /// Uses Material 3 design language.
  static ThemeData getTokyoNightTheme() {
    const primary = Color(0xFF7aa2f7);
    return ThemeData(
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF1f2335),
        primary: primary,
        secondary: const Color(0xFFbb9af7),
        tertiary: const Color(0xFF7dcfff),
        error: const Color(0xFFf7768e),
        onSurface: const Color(0xFFa9b1d6),
        onPrimary: const Color(0xFF24283b),
        onSecondary: const Color(0xFF24283b),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }

  /// Returns a refined dark theme with subtle warm undertones.
  ///
  /// Uses off-black surfaces and warm grays for a sophisticated,
  /// easier-on-the-eyes dark mode experience.
  static ThemeData getBlackTheme() {
    const primary = Color(0xFFF5F5F5);
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF121212), // Soft black
        onSurface: const Color(0xFFB0B0B0), // Muted gray text
        primary: primary, // Off-white
        onPrimary: const Color(0xFF1A1A1A), // Near black
        secondary: const Color(0xFF9E9E9E), // Medium gray
        onSecondary: const Color(0xFF1A1A1A),
        tertiary: const Color(0xFF757575), // Muted gray accent
        error: const Color(0xFFCF6679), // Soft red
        surfaceTint: const Color(0xFF2C2C2C), // Subtle surface tint
      ),
      splashColor: primary.withAlpha(20),
      highlightColor: primary.withAlpha(15),
      useMaterial3: true,
    );
  }

  /// Returns a refined light theme with subtle warm undertones.
  ///
  /// Uses off-white surfaces and warm grays for a softer,
  /// more comfortable light mode experience.
  static ThemeData getWhiteTheme() {
    const primary = Color(0xFF1A1A1A);
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFFAFAFA), // Warm off-white
        onSurface: const Color(0xFF525252), // Muted dark gray text
        primary: primary, // Near black
        onPrimary: const Color(0xFFF5F5F5), // Off-white
        secondary: const Color(0xFF616161), // Medium gray
        onSecondary: const Color(0xFFF5F5F5),
        tertiary: const Color(0xFF9E9E9E), // Muted gray accent
        error: const Color(0xFFB00020), // Material red
        surfaceTint: const Color(0xFFE0E0E0), // Subtle surface tint
      ),
      splashColor: primary.withAlpha(20),
      highlightColor: primary.withAlpha(15),
      useMaterial3: true,
    );
  }

  /// Returns a pink-tinted dark mono theme.
  static ThemeData getPinkDarkTheme() {
    const primary = Color(0xFFE91E63);
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF1A1218), // Dark pink-black
        onSurface: const Color(0xFFD6A9C4), // Muted pink
        primary: primary, // Pink
        onPrimary: const Color(0xFF1A1218),
        secondary: const Color(0xFFF48FB1), // Light pink
        onSecondary: const Color(0xFF1A1218),
        tertiary: const Color(0xFFAD1457), // Dark pink
        error: const Color(0xFFCF6679),
        surfaceTint: const Color(0xFF2D1F28),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }

  /// Returns a pink-tinted light mono theme.
  static ThemeData getPinkLightTheme() {
    const primary = Color(0xFFC2185B);
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFFCF4F7), // Light pink-white
        onSurface: const Color(0xFF9B6180), // Muted dark pink
        primary: primary, // Pink
        onPrimary: const Color(0xFFFCF4F7),
        secondary: const Color(0xFF880E4F), // Dark pink
        onSecondary: const Color(0xFFFCF4F7),
        tertiary: const Color(0xFFE91E63), // Medium pink
        error: const Color(0xFFB00020),
        surfaceTint: const Color(0xFFF8E1EA),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }

  /// Returns an orange-tinted dark mono theme.
  static ThemeData getOrangeDarkTheme() {
    const primary = Color(0xFFFF9800);
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF1A1510), // Dark orange-black
        onSurface: const Color(0xFFD6B9A9), // Muted orange
        primary: primary, // Orange
        onPrimary: const Color(0xFF1A1510),
        secondary: const Color(0xFFFFCC80), // Light orange
        onSecondary: const Color(0xFF1A1510),
        tertiary: const Color(0xFFE65100), // Dark orange
        error: const Color(0xFFCF6679),
        surfaceTint: const Color(0xFF2D261D),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }

  /// Returns an orange-tinted light mono theme.
  static ThemeData getOrangeLightTheme() {
    const primary = Color(0xFFE65100);
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFFFFAF5), // Light orange-white
        onSurface: const Color(0xFF8B6B52), // Muted dark orange
        primary: primary, // Orange
        onPrimary: const Color(0xFFFFFAF5),
        secondary: const Color(0xFFBF360C), // Dark orange
        onSecondary: const Color(0xFFFFFAF5),
        tertiary: const Color(0xFFFF9800), // Medium orange
        error: const Color(0xFFB00020),
        surfaceTint: const Color(0xFFFFF0E0),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }

  /// Returns a green-tinted dark mono theme.
  static ThemeData getGreenDarkTheme() {
    const primary = Color(0xFF4CAF50);
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF101A14), // Dark green-black
        onSurface: const Color(0xFFA9D6B1), // Muted green
        primary: primary, // Green
        onPrimary: const Color(0xFF101A14),
        secondary: const Color(0xFFA5D6A7), // Light green
        onSecondary: const Color(0xFF101A14),
        tertiary: const Color(0xFF2E7D32), // Dark green
        error: const Color(0xFFCF6679),
        surfaceTint: const Color(0xFF1D2D22),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }

  /// Returns a green-tinted light mono theme.
  static ThemeData getGreenLightTheme() {
    const primary = Color(0xFF2E7D32);
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFF5FCF6), // Light green-white
        onSurface: const Color(0xFF527258), // Muted dark green
        primary: primary, // Green
        onPrimary: const Color(0xFFF5FCF6),
        secondary: const Color(0xFF1B5E20), // Dark green
        onSecondary: const Color(0xFFF5FCF6),
        tertiary: const Color(0xFF4CAF50), // Medium green
        error: const Color(0xFFB00020),
        surfaceTint: const Color(0xFFE0F2E1),
      ),
      splashColor: primary.withAlpha(30),
      highlightColor: primary.withAlpha(20),
      useMaterial3: true,
    );
  }
}
