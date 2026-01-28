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

/// Custom app bar with integrated search and navigation functionality.
///
/// This widget provides the main navigation interface with buttons for diary,
/// hiragana, katakana, learning dashboard, and settings pages. The search field
/// supports live searching with a clear button that appears when text is present.
/// On mobile platforms, navigation buttons move to a drawer accessed via a menu
/// button, allowing the search bar to use the full width. Navigation events are
/// communicated to the parent widget through callbacks rather than being managed
/// internally.
class AppNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  /// Controller for the search text field.
  final TextEditingController textController;

  /// Focus node for the search field.
  final FocusNode searchFocusNode;

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

  /// Callback for navigating to settings page.
  final VoidCallback onNavigateToSettings;

  /// Callback when search is submitted with the search query.
  final void Function(String query) onSearch;

  /// Callback when search should be cleared and navigate to phrases/words.
  final VoidCallback onClearSearch;

  /// Callback when exit button is pressed.
  final VoidCallback onExit;

  const AppNavigationBar({
    super.key,
    required this.textController,
    required this.searchFocusNode,
    required this.currentPageIndex,
    required this.onNavigateToPhrasesWords,
    required this.onNavigateToHiragana,
    required this.onNavigateToKatakana,
    required this.onNavigateToDashboard,
    required this.onNavigateToSettings,
    required this.onSearch,
    required this.onClearSearch,
    required this.onExit,
  });

  @override
  State<AppNavigationBar> createState() => AppNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// State for [AppNavigationBar] managing search field interactions.
///
/// Listens to text controller changes to dynamically show or hide the clear
/// button, and provides methods for programmatically inserting search text.
class AppNavigationBarState extends State<AppNavigationBar> {
  /// Returns true when running on Android or iOS for mobile-specific layout.
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  /// Sets up the text controller listener for clear button visibility.
  @override
  void initState() {
    super.initState();
    // Listen to text changes to show/hide clear button dynamically.
    // setState is called on every text change to rebuild the suffix icon.
    widget.textController.addListener(() {
      setState(() {});
    });
  }

  /// Replaces the search field text and focuses it with cursor at the end.
  void insertSearchText(String text) {
    widget.textController.text = text;
    widget.searchFocusNode.requestFocus();
    // Position cursor at the end
    widget.textController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.textController.text.length),
    );
  }

  /// Builds the app bar with platform-specific layout.
  ///
  /// On mobile, shows a menu button and full-width search. On desktop, displays
  /// navigation buttons, centered search, and action buttons in a draggable area.
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

  /// Builds the mobile layout with a full-width search field.
  Widget _buildMobileTitle(BuildContext context) {
    return _buildSearchField(context, centered: false);
  }

  /// Builds the desktop layout with navigation buttons and centered search.
  ///
  /// Wraps content in DragOnlyMoveArea to enable window dragging on desktop.
  Widget _buildDesktopTitle(BuildContext context) {
    return DragOnlyMoveArea(
      child: Row(
        children: [
          ..._buildNavigationButtons(context),
          const Spacer(),
          _buildSearchField(context, centered: true),
          const Spacer(),
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
              // Also highlight when on search results (index 5)
              color: (widget.currentPageIndex == 0 || widget.currentPageIndex == 5)
                  ? primaryColor
                  : defaultColor,
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
          message: 'Learning',
          child: IconButton(
            icon: Icon(
              Icons.school,
              color: widget.currentPageIndex == 3 ? primaryColor : defaultColor,
            ),
            onPressed: widget.onNavigateToDashboard,
          ),
        ),
      ),
    ];
  }

  /// Builds the search text field with double-tap to select all.
  ///
  /// When [centered] is true, wraps the field in an Expanded widget for
  /// flexible sizing in the desktop layout.
  Widget _buildSearchField(BuildContext context, {required bool centered}) {
    final searchField = GestureDetector(
      onDoubleTap: () {
        // Select all text on double tap instead of maximizing window
        widget.textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.textController.text.length,
        );
      },
      child: TextField(
        controller: widget.textController,
        focusNode: widget.searchFocusNode,
        textAlign: TextAlign.left,
        onSubmitted: (value) => widget.onSearch(value),
        decoration: _buildSearchDecoration(context),
      ),
    );

    if (centered) {
      return Expanded(flex: 3, child: searchField);
    }
    return searchField;
  }

  /// Creates the input decoration with search icon, conditional clear button, and themed borders.
  InputDecoration _buildSearchDecoration(BuildContext context) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.search),
      suffixIcon: widget.textController.text.isNotEmpty
          ? ExcludeFocus(
            child:StyledTooltip(
              message: 'Clear',
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClearSearch,
              ),
            )
          )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withAlpha(128),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
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
              color: widget.currentPageIndex == 4 ? primaryColor : defaultColor,
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

  /// Callback for navigating to settings page.
  final VoidCallback onNavigateToSettings;

  const AppNavigationDrawer({
    super.key,
    required this.onNavigateToPhrasesWords,
    required this.onNavigateToHiragana,
    required this.onNavigateToKatakana,
    required this.onNavigateToDashboard,
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
                  icon: Icons.school,
                  title: 'Learning',
                  onTap: () {
                    Navigator.pop(context);
                    onNavigateToDashboard();
                  },
                ),
                const Divider(),
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
