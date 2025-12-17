/// Japanese Learning Diary - Main application entry point.
///
/// This Flutter application helps track Japanese language learning progress,
/// including hiragana, katakana, phrases, and words.
library;
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:jpn_learning_diary/screens/dashboard_page.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';

/// Main entry point of the application.
///
/// Initializes the Flutter app with platform-specific window effects:
/// - Sets up Mica effect for modern Windows appearance
/// - Configures transparent titlebar
/// - Hides default window controls for custom UI
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  await Window.setEffect(effect: WindowEffect.mica);
  await Window.hideTitle();
  await Window.makeTitlebarTransparent();
  await Window.enableFullSizeContentView();
  await Window.hideWindowControls();

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
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: AppTheme.tokyoDaySurface,
          primary: AppTheme.tokyoDayPrimary,
          secondary: AppTheme.tokyoDaySecondary,
          tertiary: AppTheme.tokyoDayTertiary,
          error: AppTheme.tokyoDayError,
          onSurface: AppTheme.tokyoDayOnSurface,
          onPrimary: AppTheme.tokyoDayBackground,
          onSecondary: AppTheme.tokyoDayBackground,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          surface: AppTheme.tokyoNightSurface,
          primary: AppTheme.tokyoNightPrimary,
          secondary: AppTheme.tokyoNightSecondary,
          tertiary: AppTheme.tokyoNightTertiary,
          error: AppTheme.tokyoNightError,
          onSurface: AppTheme.tokyoNightOnSurface,
          onPrimary: AppTheme.tokyoNightBackground,
          onSecondary: AppTheme.tokyoNightBackground,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardPage(),
    );
  }
}
