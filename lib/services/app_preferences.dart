// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing persistent application preferences via SharedPreferences.
///
/// This convenience wrapper handles the storage and retrieval of user settings
/// such as the custom database path, view modes, and quiz configurations. It
/// abstracts the underlying key-value store implementation and provides tailored
/// methods for each application setting to ensure type safety and consistency.
class AppPreferences {
  static const String _keyCustomDbPath = 'custom_db_path';
  static const String _keyViewMode = 'view_mode';
  static const String _keyShowRomaji = 'show_romaji';
  static const String _keyShowFurigana = 'show_furigana';
  static const String _keyQuizQuestionCount = 'quiz_question_count';

  /// Available quiz question count options.
  static const List<int> quizQuestionCountOptions = [5, 10, 15, 20, 30, 50];

  /// Default quiz question count.
  static const int defaultQuizQuestionCount = 10;

  /// Gets the custom database path if set by the user.
  ///
  /// Returns null if no custom path has been set.
  static Future<String?> getCustomDatabasePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomDbPath);
  }

  /// Sets a custom database path.
  ///
  /// The app will need to restart for this change to take effect.
  /// Pass null to reset to the default path.
  static Future<void> setCustomDatabasePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyCustomDbPath);
    } else {
      await prefs.setString(_keyCustomDbPath, path);
    }
  }

  /// Clears the custom database path, reverting to default.
  static Future<void> clearCustomDatabasePath() async {
    await setCustomDatabasePath(null);
  }

  /// Checks if a custom database path is currently set.
  static Future<bool> hasCustomDatabasePath() async {
    final path = await getCustomDatabasePath();
    return path != null && path.isNotEmpty;
  }

  /// Gets the preferred view mode (grid or list).
  ///
  /// Returns 'grid' or 'list'. Defaults to 'list' if not set.
  static Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyViewMode) ?? 'list';
  }

  /// Sets the preferred view mode.
  ///
  /// [mode] should be either 'grid' or 'list'.
  static Future<void> setViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyViewMode, mode);
  }

  /// Gets whether to show romaji in diary entries.
  ///
  /// Returns true by default if not set.
  static Future<bool> getShowRomaji() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowRomaji) ?? true;
  }

  /// Sets whether to show romaji in diary entries.
  static Future<void> setShowRomaji(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowRomaji, show);
  }

  /// Gets whether to show furigana in diary entries.
  ///
  /// Returns true by default if not set.
  static Future<bool> getShowFurigana() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowFurigana) ?? true;
  }

  /// Sets whether to show furigana in diary entries.
  static Future<void> setShowFurigana(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowFurigana, show);
  }

  /// Gets the current theme style index.
  ///
  /// Returns 0 for Tokyo, 1 for Mono, 2 for Pink, 3 for Orange, 4 for Green.
  static Future<int> getThemeStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('theme_mode_index') ?? 0;
  }

  /// Sets the current theme style index.
  ///
  /// [index] 0 for Tokyo, 1 for Mono, 2 for Pink, 3 for Orange, 4 for Green.
  static Future<void> setThemeStyle(int index) async {
    if (index < 0) return;
    if (index > 4) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode_index', index);
  }

  /// Gets the number of questions to show in quizzes.
  ///
  /// Returns the default (10) if not set.
  static Future<int> getQuizQuestionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQuizQuestionCount) ?? defaultQuizQuestionCount;
  }

  /// Sets the number of questions to show in quizzes.
  static Future<void> setQuizQuestionCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyQuizQuestionCount, count);
  }
}
