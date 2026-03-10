// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/widgets/styled_tooltip.dart';
import 'package:jpn_learning_diary/widgets/drag_to_move_area.dart';

/// Custom app bar with navigation functionality.
///
/// This widget provides the main navigation interface with buttons for diary,
/// hiragana, katakana, learning dashboard, and settings pages.
/// On mobile platforms, navigation buttons move to a drawer accessed via a menu
/// button. Navigation events are
/// communicated to the parent widget through callbacks rather than being managed
/// internally.
///
/// * [onNavItemSelected]: Callback triggered when a navigation item is selected.
/// * [onOpenDrawer]: Callback triggered when the hamburger menu is tapped (mobile only).
/// * [currentRoute]: The name of the currently active route for highlighting.
class AppNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  /// The currently active page for highlighting the navigation icon.
  final int currentPageIndex;

  /// Callback for navigating to phrases/words page.
  final VoidCallback onNavigateToPhrasesWords;

  /// Callback for navigating to hiragana page.
  final VoidCallback onNavigateToHiragana;

  /// Callback for navigating to katakana page.
  final VoidCallback onNavigateToKatakana;

  /// Callback for navigating to dashboard page.
  final VoidCallback onNavigateToDashboard;

  /// Callback for navigating to study mode page.
  final VoidCallback onNavigateToStudyMode;

  /// Callback for navigating to settings page.
  final VoidCallback onNavigateToSettings;

  /// Callback when exit button is pressed.
  final VoidCallback onExit;

  const AppNavigationBar({
    super.key,
    required this.currentPageIndex,
    required this.onNavigateToPhrasesWords,
    required this.onNavigateToHiragana,
    required this.onNavigateToKatakana,
    required this.onNavigateToDashboard,
    required this.onNavigateToStudyMode,
    required this.onNavigateToSettings,
    required this.onExit,
  });

  @override
  State<AppNavigationBar> createState() => AppNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// State for [AppNavigationBar].
class AppNavigationBarState extends State<AppNavigationBar> {
  /// Returns true when running on Android or iOS for mobile-specific layout.
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  /// Builds the app bar with platform-specific layout.
  ///
  /// On mobile, shows a menu button and full-width title. On desktop, displays
  /// navigation buttons and action buttons in a draggable area.
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      // Show menu button on mobile to open the drawer
      leading: _isMobile
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            )
          : null,
      automaticallyImplyLeading: false,
      title: _isMobile
          ? _buildMobileTitle(context)
          : _buildDesktopTitle(context),
      actions: _isMobile
          ? null
          : [..._buildActionButtons(context), const SizedBox(width: 16)],
    );
  }

  /// Builds the mobile layout with title.
  Widget _buildMobileTitle(BuildContext context) {
      return Text('JPN Learning Diary');
  }

  /// Builds the desktop layout with navigation buttons.
  ///
  /// Wraps content in DragOnlyMoveArea to enable window dragging on desktop.
  Widget _buildDesktopTitle(BuildContext context) {
    return DragOnlyMoveArea(
      child: Row(
        children: [
          ..._buildNavigationButtons(context),
        ],
      ),
    );
  }

  /// Creates the main navigation buttons for diary, hiragana, katakana, and learning.
  ///
  /// The currently active page icon is highlighted with the primary color.
  List<Widget> _buildNavigationButtons(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final defaultColor = Theme.of(context).colorScheme.onSurface;

    return [
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Diary',
          child: IconButton(
            icon: Icon(
              Icons.menu_book,
              color: widget.currentPageIndex == 0 ? primaryColor : defaultColor,
            ),
            onPressed: widget.onNavigateToPhrasesWords,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Hiragana',
          child: IconButton(
            icon: Text(
              'あ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.currentPageIndex == 1 ? primaryColor : defaultColor,
              ),
            ),
            onPressed: widget.onNavigateToHiragana,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Katakana',
          child: IconButton(
            icon: Text(
              'ア',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.currentPageIndex == 2 ? primaryColor : defaultColor,
              ),
            ),
            onPressed: widget.onNavigateToKatakana,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Study Mode',
          child: IconButton(
            icon: Icon(
              Icons.auto_stories,
              color: widget.currentPageIndex == 3 ? primaryColor : defaultColor,
            ),
            onPressed: widget.onNavigateToStudyMode,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Learning',
          child: IconButton(
            icon: Icon(
              Icons.school,
              color: widget.currentPageIndex == 4 ? primaryColor : defaultColor,
            ),
            onPressed: widget.onNavigateToDashboard,
          ),
        ),
      ),
    ];
  }

  /// Creates the right-side action buttons for settings, window controls, and exit.
  List<Widget> _buildActionButtons(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final defaultColor = Theme.of(context).colorScheme.onSurface;

    return [
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Settings',
          child: IconButton(
            icon: Icon(
              Icons.settings,
              color: widget.currentPageIndex == 5 ? primaryColor : defaultColor,
            ),
            onPressed: widget.onNavigateToSettings,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Minimize',
          child: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () async {
              await windowManager.minimize();
            },
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Maximize or hold for Fullscreen',
          child: GestureDetector(
            onLongPress: () async {
              final isFullScreen = await windowManager.isFullScreen();
              await windowManager.setFullScreen(!isFullScreen);
            },
            child: IconButton(
              icon: const Icon(Icons.crop_square),
              onPressed: () async {
                final isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Exit',
          child: IconButton(
            onPressed: widget.onExit,
            icon: const Icon(Icons.close),
          ),
        ),
      ),
  ]
  ;
  }
}

/// Navigation drawer for mobile platforms containing all navigation items.
///
/// Provides the same navigation options as the desktop app bar in a
/// mobile-friendly slide-out drawer format with a branded header.
class AppNavigationDrawer extends StatelessWidget {
  /// Callback for navigating to phrases/words page.
  final VoidCallback onNavigateToPhrasesWords;

  /// Callback for navigating to hiragana page.
  final VoidCallback onNavigateToHiragana;

  /// Callback for navigating to katakana page.
  final VoidCallback onNavigateToKatakana;

  /// Callback for navigating to dashboard page.
  final VoidCallback onNavigateToDashboard;

  /// Callback for navigating to study mode page.
  final VoidCallback onNavigateToStudyMode;

  /// Callback for navigating to settings page.
  final VoidCallback onNavigateToSettings;

  const AppNavigationDrawer({
    super.key,
    required this.onNavigateToPhrasesWords,
    required this.onNavigateToHiragana,
    required this.onNavigateToKatakana,
    required this.onNavigateToDashboard,
    required this.onNavigateToStudyMode,
    required this.onNavigateToSettings,
  });

  /// Builds the drawer with a branded header and navigation list items.
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.inversePrimary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Image.asset(
              'lib/assets/bird_cropped.png',
              width: 128,
              height: 128,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.menu_book,
                  title: 'Diary (Phrases & Words)',
                  onTap: () {
                    Navigator.pop(context);
                    onNavigateToPhrasesWords();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: null,
                  customIcon: const Text(
                    'あ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  title: 'Hiragana',
                  onTap: () {
                    Navigator.pop(context);
                    onNavigateToHiragana();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: null,
                  customIcon: const Text(
                    'ア',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  title: 'Katakana',
                  onTap: () {
                    Navigator.pop(context);
                    onNavigateToKatakana();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.auto_stories,
                  title: 'Study Mode',
                  onTap: () {
                    Navigator.pop(context);
                    onNavigateToStudyMode();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.school,
                  title: 'Learning',
                  onTap: () {
                    Navigator.pop(context);
                    onNavigateToDashboard();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    onNavigateToSettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a drawer list item with an icon (or custom widget) and title.
  Widget _buildDrawerItem(
    BuildContext context, {
    IconData? icon,
    Widget? customIcon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: customIcon ?? Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
