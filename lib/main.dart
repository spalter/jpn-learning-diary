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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/services/theme_notifier.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/screens/splash_screen.dart';

/// Main entry point of the application.
///
/// On desktop platforms, this configures a modern translucent window appearance
/// using the Windows Mica effect or macOS transparency. The titlebar is hidden
/// to allow for a custom UI implementation, and a minimum window size of 700x300
/// ensures the layout remains usable. Mobile platforms skip these effects and
/// launch directly.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme notifier
  await ThemeNotifier.instance.initialize();

  // Mobile platforms: run app directly
  if (Platform.isAndroid || Platform.isIOS) {
    runApp(const JapaneseLearningDiary());
    return;
  }

  // Clear shared preferences if requested
  if (args.contains('--reset-prefs')) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Skip window effects if specified
  if (args.contains('--no-effects')) {
    runApp(const JapaneseLearningDiary());
    return;
  }

  // Initialize window effects and settings
  await Window.initialize();
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(700, 300));
  await windowManager.center();

  // Hide titlebar for custom implementation
  if (Platform.isWindows || Platform.isLinux) {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  } else if (Platform.isMacOS) {
    await Window.hideTitle();
    await Window.makeTitlebarTransparent();
    await Window.enableFullSizeContentView();
    await Window.hideWindowControls();
  }

  runApp(const JapaneseLearningDiary());
}

/// Root widget of the Japanese Learning Diary application.
///
/// The app uses a custom Tokyo-inspired color scheme with Tokyo Day for light
/// mode and Tokyo Night for dark mode, following Material 3 design guidelines.
/// Theme switching is automatic based on the system preference. On Android,
/// a lifecycle observer triggers cloud sync when the app goes to background
/// to ensure diary entries are backed up.
class JapaneseLearningDiary extends StatefulWidget {
  const JapaneseLearningDiary({super.key});

  @override
  State<JapaneseLearningDiary> createState() => _JapaneseLearningDiaryState();
}

/// Internal state for [JapaneseLearningDiary].
class _JapaneseLearningDiaryState extends State<JapaneseLearningDiary> {
  /// Builds the MaterialApp with Tokyo-themed light and dark modes.
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
