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

  /// Alpha transparency value for scaffold backgrounds (0-255).
  ///
  /// Higher values are more opaque. Currently set to 200 for a semi-transparent effect.
  static const int scaffoldBackgroundAlpha = 200;

  // Tokyo Night Storm colors (Dark Mode)
  
  /// Background color for dark mode (Tokyo Night Storm).
  static const tokyoNightBackground = Color(0xFF24283b);
  
  /// Surface color for dark mode (Tokyo Night Storm).
  static const tokyoNightSurface = Color(0xFF1f2335);
  
  /// Primary accent color for dark mode - Blue.
  static const tokyoNightPrimary = Color(0xFF7aa2f7);
  
  /// Secondary accent color for dark mode - Purple.
  static const tokyoNightSecondary = Color(0xFFbb9af7);
  
  /// Tertiary accent color for dark mode - Cyan.
  static const tokyoNightTertiary = Color(0xFF7dcfff);
  
  /// Error color for dark mode - Red.
  static const tokyoNightError = Color(0xFFf7768e);
  
  /// Text color on background for dark mode.
  static const tokyoNightOnBackground = Color(0xFFc0caf5);
  
  /// Text color on surface for dark mode.
  static const tokyoNightOnSurface = Color(0xFFa9b1d6);

  // Tokyo Day colors (Light Mode)
  
  /// Background color for light mode (Tokyo Day).
  static const tokyoDayBackground = Color(0xFFd5d6db);
  
  /// Surface color for light mode (Tokyo Day).
  static const tokyoDaySurface = Color(0xFFe1e2e7);
  
  /// Primary accent color for light mode - Blue.
  static const tokyoDayPrimary = Color(0xFF2e7de9);
  
  /// Secondary accent color for light mode - Purple.
  static const tokyoDaySecondary = Color(0xFF9854f1);
  
  /// Tertiary accent color for light mode - Teal.
  static const tokyoDayTertiary = Color(0xFF007197);
  
  /// Error color for light mode - Pink/Red.
  static const tokyoDayError = Color(0xFFf52a65);
  
  /// Text color on background for light mode.
  static const tokyoDayOnBackground = Color(0xFF3760bf);
  
  /// Text color on surface for light mode.
  static const tokyoDayOnSurface = Color(0xFF6172b0);

  /// Returns the scaffold background color with semi-transparency applied.
  ///
  /// This creates a modern, translucent effect allowing content behind
  /// the scaffold to show through subtly.
  ///
  /// [context] The build context to access the current theme.
  /// Returns a Color with the configured alpha transparency applied.
  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface.withAlpha(scaffoldBackgroundAlpha);
  }
}
