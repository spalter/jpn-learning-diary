/// Retro-styled splash screen with terminal boot-up effect.
library;

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/app_shell.dart';

/// Splash screen with retro terminal boot-up aesthetic.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _bootMessages = [];
  bool _showCursor = true;
  bool _bootComplete = false;

  static const List<String> _allBootMessages = [
    'SYSTEM INITIALIZATION...',
    'LOADING JAPANESE CHARACTER DATABASE...',
    'INITIALIZING KANJI REPOSITORY...',
    'MOUNTING DIARY STORAGE...',
    'CALIBRATING DISPLAY PHOSPHORS...',
    'SYSTEM READY.',
    '',
    '日本語学習日記 v1.0',
    'JAPANESE LEARNING DIARY',
    '',
  ];

  @override
  void initState() {
    super.initState();
    _startBootSequence();
    _startCursorBlink();
  }

  Future<void> _startCursorBlink() async {
    while (mounted && !_bootComplete) {
      await Future.delayed(const Duration(milliseconds: 530));
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    }
  }

  Future<void> _startBootSequence() async {
    for (final message in _allBootMessages) {
      if (!mounted) return;
      
      // Type each character with a delay
      for (int i = 0; i <= message.length; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 15));
        if (mounted) {
          setState(() {
            if (_bootMessages.isEmpty || _bootMessages.last != message) {
              if (i == 0) {
                _bootMessages.add('');
              }
              _bootMessages[_bootMessages.length - 1] = message.substring(0, i);
            }
          });
        }
      }
      
      // Small pause between lines
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Final pause before navigation
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _bootComplete = true;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo at the top left (like Tux on Linux boot)
            ColorFiltered(
              // Apply monochrome tint to match theme
              colorFilter: ColorFilter.mode(
                theme.colorScheme.primary.withOpacity(0.9),
                BlendMode.srcATop,
              ),
              child: Image.asset(
                'lib/assets/bird_crop.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            // Boot messages
            ..._bootMessages.asMap().entries.map((entry) {
              final isLast = entry.key == _bootMessages.length - 1;
              return Text(
                isLast && !_bootComplete
                    ? '${entry.value}${_showCursor ? "█" : " "}'
                    : entry.value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: theme.colorScheme.primary,
                  height: 1.5,
                ),
              );
            }),
            const Spacer(),
            // Footer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '(C) 2024-2026 JAPANESE LEARNING DIARY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: theme.colorScheme.tertiary,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'INITIALIZING...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
