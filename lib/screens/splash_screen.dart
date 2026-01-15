library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/services/cloud_sync_service.dart';
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
    if (Platform.isAndroid && await CloudSyncService.isCloudSyncEnabled()) {
      await CloudSyncService.syncFromCloud();
    }

    // Ensure splash is shown for at least a short duration
    await Future.delayed(const Duration(milliseconds: 500));

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
