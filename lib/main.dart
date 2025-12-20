/// Japanese Learning Diary - Main application entry point.
///
/// This Flutter application helps track Japanese language learning progress,
/// including hiragana, katakana, phrases, and words.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_shell.dart';

/// Main entry point of the application.
///
/// Initializes the Flutter app with platform-specific window effects:
/// - Sets up Mica effect for modern Windows appearance
/// - Configures transparent titlebar
/// - Hides default window controls for custom UI
/// - Sets minimum window size to 700x300
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  await Window.setEffect(effect: WindowEffect.mica);
  await Window.hideTitle();
  await Window.makeTitlebarTransparent();
  await Window.enableFullSizeContentView();
  await Window.hideWindowControls();

  // Initialize window manager and set minimum size
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(700, 300));

  // Don't hide on MacOS, it will show the titlebar again for some reason
  if (!Platform.isMacOS) {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
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
class JapaneseLearningDiary extends StatelessWidget {
  const JapaneseLearningDiary({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.appTitle,
      theme: AppTheme.getTokyoDayTheme(),
      darkTheme: AppTheme.getTokyoNightTheme(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
