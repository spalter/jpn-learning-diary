import 'dart:io' show exit;

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/screens/dashboard_page.dart';
import 'package:jpn_learning_diary/screens/hiragana_page.dart';
import 'package:jpn_learning_diary/screens/katakana_page.dart';
import 'package:jpn_learning_diary/screens/phrases_words_page.dart';
import 'package:jpn_learning_diary/screens/search_results_page.dart';
import 'package:jpn_learning_diary/screens/settings_page.dart';
import 'package:jpn_learning_diary/widgets/app_menu.dart';
import 'edit_diary_entry_dialog.dart';

/// Custom app bar with integrated search functionality.
///
/// Provides a navigation bar with:
/// - Menu button to open the navigation drawer
/// - Search field with auto-complete suggestions
/// - Window control buttons (minimize, maximize, close)
/// - Custom styling matching the app theme
class AppNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  /// Controller for the search text field.
  final TextEditingController textController;
  
  /// Optional callback when a new entry is added.
  final VoidCallback? onEntryAdded;

  const AppNavigationBar({
    super.key,
    required this.textController,
    this.onEntryAdded,
  });

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// State for the navigation bar.
class _AppNavigationBarState extends State<AppNavigationBar> {
  /// Focus node for the search text field.
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Row(
        children: [
          // Navigation buttons
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Diary (Phrases & Words)',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                NoAnimationPageRoute(builder: (context) => const PhrasesWordsPage()),
              );
            },
          ),
          IconButton(
            icon: const Text(
              'あ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            tooltip: 'Hiragana',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                NoAnimationPageRoute(builder: (context) => const HiraganaPage()),
              );
            },
          ),
          IconButton(
            icon: const Text(
              'ア',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            tooltip: 'Katakana',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                NoAnimationPageRoute(builder: (context) => const KatakanaPage()),
              );
            },
          ),
          const Spacer(),
          
          // Add entry button
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add new diary entry',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const EditDiaryEntryDialog(),
              );
              
              if (result == true) {
                widget.onEntryAdded?.call();
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: widget.textController,
              focusNode: _focusNode,
              textAlign: TextAlign.left,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pushReplacement(
                      context,
                      NoAnimationPageRoute(
                        builder: (context) => SearchResultsPage(
                          searchQuery: value.trim(),
                        ),
                      ),
                    );
                    // Select all text after navigation to keep it visible and ready for next search
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        widget.textController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: widget.textController.text.length,
                        );
                      }
                    });
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withAlpha(128)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          const Spacer(),
        ],
      ),
      actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Learning',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                NoAnimationPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                NoAnimationPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        IconButton(
          onPressed: () {
            exit(0);
          },
          icon: const Icon(Icons.close),
          tooltip: 'Exit',
        ),
      ],
    );
  }
}
