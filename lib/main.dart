/// Japanese Learning Diary - Main application entry point.
///
/// This Flutter application helps track Japanese language learning progress,
/// including hiragana, katakana, phrases, and words.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/theme/retro_theme.dart';
import 'package:jpn_learning_diary/theme/retro_theme_provider.dart';
import 'package:jpn_learning_diary/screens/splash_screen.dart';
import 'package:jpn_learning_diary/widgets/scanline_overlay.dart';

/// Main entry point of the application.
///
/// Initializes the Flutter app with platform-specific window effects:
/// - Sets up Mica effect for modern Windows appearance
/// - Configures transparent titlebar
/// - Hides default window controls for custom UI
/// - Sets minimum window size to 700x300
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

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
  await Window.setEffect(effect: WindowEffect.mica);
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(700, 300));
  await windowManager.center();

  if (Platform.isWindows) {
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
/// - Retro CRT-style theme with customizable color schemes
/// - Scanline and visual effects overlay
/// - Sharp-edged UI components
class JapaneseLearningDiary extends StatefulWidget {
  const JapaneseLearningDiary({super.key});

  @override
  State<JapaneseLearningDiary> createState() => _JapaneseLearningDiaryState();
}

class _JapaneseLearningDiaryState extends State<JapaneseLearningDiary> {
  final RetroThemeProvider _themeProvider = RetroThemeProvider();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await _themeProvider.loadPreferences();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show a simple loading screen while theme loads
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: RetroTheme.getThemeData(RetroColorScheme.phosphorGreen),
        home: const Scaffold(
          body: Center(
            child: Text(
              'INITIALIZING...',
              style: TextStyle(
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _themeProvider,
      child: Consumer<RetroThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Japanese Learning Diary',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            // Wrap ALL routes with the scanline overlay for retro CRT effect
            builder: (context, child) {
              return ScanlineOverlay(
                config: themeProvider.effectsConfig,
                colorScheme: themeProvider.colorScheme,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

