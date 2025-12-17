import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/screens/dashboard_page.dart';
import 'package:jpn_learning_diary/screens/hiragana_page.dart';
import 'package:jpn_learning_diary/screens/katakana_page.dart';
import 'package:jpn_learning_diary/screens/phrases_words_page.dart';
import 'package:jpn_learning_diary/screens/settings_page.dart';
import 'package:jpn_learning_diary/widgets/app_about_dialog.dart';

/// Custom page route with no transition animation.
class NoAnimationPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationPageRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}

/// Navigation menu drawer for the application.
///
/// Provides navigation links to all major sections:
/// - Dashboard
/// - Hiragana
/// - Katakana
/// - Phrases & Words
/// - Settings
/// - About dialog
/// - Exit application
class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.book,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'JPN Learning Diary',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                NoAnimationPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Hiragana'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                NoAnimationPageRoute(builder: (context) => const HiraganaPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_format),
            title: const Text('Katakana'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                NoAnimationPageRoute(builder: (context) => const KatakanaPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('Phrases & Words'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                NoAnimationPageRoute(builder: (context) => const PhrasesWordsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                NoAnimationPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAppAboutDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Exit'),
            onTap: () {
              exit(0);
            },
          ),
        ],
      ),
    );
  }
}
