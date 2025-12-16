import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:jpn_learning_diary/screens/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  await Window.setEffect(effect: WindowEffect.mica, dark: true);
  await Window.hideTitle();
  await Window.makeTitlebarTransparent();
  await Window.enableFullSizeContentView();
  await Window.hideWindowControls();

  runApp(const JapaneseLearningDiary());
}

class JapaneseLearningDiary extends StatelessWidget {
  const JapaneseLearningDiary({super.key});
  static const String appTitle = 'Japanese Learning Diary';

  // Tokyo Night Storm colors
  static const tokyoNightBackground = Color(0xFF24283b);
  static const tokyoNightSurface = Color(0xFF1f2335);
  static const tokyoNightPrimary = Color(0xFF7aa2f7);
  static const tokyoNightSecondary = Color(0xFFbb9af7);
  static const tokyoNightTertiary = Color(0xFF7dcfff);
  static const tokyoNightError = Color(0xFFf7768e);
  static const tokyoNightOnBackground = Color(0xFFc0caf5);
  static const tokyoNightOnSurface = Color(0xFFa9b1d6);

  // Tokyo Day colors
  static const tokyoDayBackground = Color(0xFFd5d6db);
  static const tokyoDaySurface = Color(0xFFe1e2e7);
  static const tokyoDayPrimary = Color(0xFF2e7de9);
  static const tokyoDaySecondary = Color(0xFF9854f1);
  static const tokyoDayTertiary = Color(0xFF007197);
  static const tokyoDayError = Color(0xFFf52a65);
  static const tokyoDayOnBackground = Color(0xFF3760bf);
  static const tokyoDayOnSurface = Color(0xFF6172b0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: tokyoDaySurface,
          primary: tokyoDayPrimary,
          secondary: tokyoDaySecondary,
          tertiary: tokyoDayTertiary,
          error: tokyoDayError,
          onSurface: tokyoDayOnSurface,
          onPrimary: tokyoDayBackground,
          onSecondary: tokyoDayBackground,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          surface: tokyoNightSurface,
          primary: tokyoNightPrimary,
          secondary: tokyoNightSecondary,
          tertiary: tokyoNightTertiary,
          error: tokyoNightError,
          onSurface: tokyoNightOnSurface,
          onPrimary: tokyoNightBackground,
          onSecondary: tokyoNightBackground,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardPage(),
    );
  }
}
