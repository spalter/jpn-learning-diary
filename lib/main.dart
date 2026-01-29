// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

/// Japanese Learning Diary - Main application entry point.
///
/// This Flutter application helps track Japanese language learning progress,
/// including hiragana, katakana, phrases, and words.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jpn_learning_diary/services/theme_notifier.dart';
import 'package:jpn_learning_diary/services/window_manager_service.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/screens/splash_screen.dart';
import 'package:jpn_learning_diary/widgets/app_about_dialog.dart';

/// Main entry point of the application.
///
/// On desktop platforms, the titlebar is hidden to allow for a custom UI
/// implementation, and a minimum window size of 700x300 ensures the
/// layout remains usable. Mobile platforms skip these effects and
/// launch directly.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register custom licenses for third-party data sources (JMdict, etc.)
  registerCustomLicenses();

  // Initialize theme notifier
  await ThemeNotifier.instance.initialize();

  // Clear shared preferences if requested
  if (args.contains('--reset-prefs')) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  await WindowManagerService.instance.initialize();
  runApp(const JapaneseLearningDiary());
}

/// Root widget of the Japanese Learning Diary application.
class JapaneseLearningDiary extends StatefulWidget {
  const JapaneseLearningDiary({super.key});

  @override
  State<JapaneseLearningDiary> createState() => _JapaneseLearningDiaryState();
}

/// Internal state for [JapaneseLearningDiary].
class _JapaneseLearningDiaryState extends State<JapaneseLearningDiary> {
  /// Builds the MaterialApp with light and dark modes.
  ///
  /// The app starts with [SplashScreen] which handles initial loading and
  /// navigation to the main content. Uses [ListenableBuilder] to rebuild
  /// when theme changes via [ThemeNotifier].
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, child) {
        return MaterialApp(
          title: AppTheme.appTitle,
          theme: ThemeNotifier.instance.getLightTheme(),
          darkTheme: ThemeNotifier.instance.getDarkTheme(),
          themeMode: ThemeMode.system,
          home: const SplashScreen(),
        );
      },
    );
  }
}
