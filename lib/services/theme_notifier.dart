// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';

/// A notifier that manages the app's theme state and notifies listeners on changes.
///
/// This allows live theme switching without requiring an app restart.
class ThemeNotifier extends ChangeNotifier {
  /// Singleton instance for global access.
  static final ThemeNotifier instance = ThemeNotifier._();

  ThemeNotifier._();

  int _themeStyleIndex = 0;

  /// The current theme style index.
  int get themeStyleIndex => _themeStyleIndex;

  /// Initializes the notifier by loading the saved theme preference.
  Future<void> initialize() async {
    _themeStyleIndex = await AppPreferences.getThemeStyle();
    notifyListeners();
  }

  /// Sets the theme style and notifies listeners.
  ///
  /// [index] 0 for Tokyo, 1 for Mono, 2 for Pink, 3 for Orange, 4 for Green.
  Future<void> setThemeStyle(int index) async {
    if (index < 0 || index > 4) return;
    await AppPreferences.setThemeStyle(index);
    _themeStyleIndex = index;
    notifyListeners();
  }

  /// Returns the light theme based on the current style.
  ThemeData getLightTheme() {
    switch (_themeStyleIndex) {
      case 1:
        return AppTheme.getWhiteTheme();
      case 2:
        return AppTheme.getPinkLightTheme();
      case 3:
        return AppTheme.getOrangeLightTheme();
      case 4:
        return AppTheme.getGreenLightTheme();
      default:
        return AppTheme.getTokyoDayTheme();
    }
  }

  /// Returns the dark theme based on the current style.
  ThemeData getDarkTheme() {
    switch (_themeStyleIndex) {
      case 1:
        return AppTheme.getBlackTheme();
      case 2:
        return AppTheme.getPinkDarkTheme();
      case 3:
        return AppTheme.getOrangeDarkTheme();
      case 4:
        return AppTheme.getGreenDarkTheme();
      default:
        return AppTheme.getTokyoNightTheme();
    }
  }
}
