library;

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/app_shell.dart';

/// Splash screen with bird image shown while app initializes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for a short duration to show the splash screen
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'lib/assets/bird.png',
          fit: BoxFit.contain,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
