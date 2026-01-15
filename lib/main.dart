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
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/screens/splash_screen.dart';

/// Main entry point of the application.
///
/// Initializes the Flutter app with platform-specific window effects:
/// - Sets up Mica effect for modern Windows appearance
/// - Configures transparent titlebar
/// - Hides default window controls for custom UI
/// - Sets minimum window size to 700x300
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  if (Platform.isWindows) {
    await Window.setEffect(effect: WindowEffect.mica);
  }

  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(700, 300));
  await windowManager.center();

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
/// Configures the Material app with:
/// - Tokyo Night theme for dark mode
/// - Tokyo Day theme for light mode
/// - Material 3 design language
/// - System-based theme switching
/// - App lifecycle observer for cloud sync on Android
class JapaneseLearningDiary extends StatefulWidget {
  const JapaneseLearningDiary({super.key});

  @override
  State<JapaneseLearningDiary> createState() => _JapaneseLearningDiaryState();
}

class _JapaneseLearningDiaryState extends State<JapaneseLearningDiary>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // On Android, sync to cloud when app goes to background (as a backup)
    // Primary sync happens after each write operation in DatabaseHelper
    if (Platform.isAndroid) {
      if (state == AppLifecycleState.paused) {
        // Fire and forget - best effort sync when going to background
        DatabaseHelper.instance.syncToCloud();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.appTitle,
      theme: AppTheme.getTokyoDayTheme(),
      darkTheme: AppTheme.getTokyoNightTheme(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
