import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/widgets/styled_tooltip.dart';

/// Custom app bar with integrated search functionality.
///
/// Provides a navigation bar with:
/// - Navigation buttons for diary, hiragana (あ), and katakana (ア) pages
/// - Search field with submit functionality (searches when text present, navigates to diary when empty)
/// - Clear button (X) that appears when search has text
/// - Learning dashboard and settings buttons
/// - Exit button to close the application
/// - Custom styling matching the app theme
///
/// On mobile platforms (Android/iOS), the navigation buttons are moved to a
/// sidebar/drawer accessed via a menu button, and the search bar uses the
/// full available width.
///
/// Instead of managing navigation internally, this widget uses callbacks
/// to notify the parent widget of navigation and action events.
class AppNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  /// Controller for the search text field.
  final TextEditingController textController;

  /// Focus node for the search field.
  final FocusNode searchFocusNode;

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

/// State for the navigation bar.
class AppNavigationBarState extends State<AppNavigationBar> {
  /// Whether we're on a mobile platform (Android/iOS).
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    // Listen to text changes to show/hide clear button dynamically.
    // setState is called on every text change to rebuild the suffix icon.
    widget.textController.addListener(() {
      setState(() {});
    });
  }

  /// Inserts or replaces text in the search field and focuses it.
  void insertSearchText(String text) {
    widget.textController.text = text;
    widget.searchFocusNode.requestFocus();
    // Position cursor at the end
    widget.textController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.textController.text.length),
    );
  }

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

  /// Builds the title section for mobile layout (search bar only, uses full width).
  Widget _buildMobileTitle(BuildContext context) {
    return _buildSearchField(context, centered: false);
  }

  /// Builds the title section for desktop layout (nav buttons + centered search).
  Widget _buildDesktopTitle(BuildContext context) {
    return DragToMoveArea(
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

  /// Builds the navigation buttons (Diary, Hiragana, Katakana).
  List<Widget> _buildNavigationButtons(BuildContext context) {
    return [
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Diary (Phrases & Words)',
          child: IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: widget.onNavigateToPhrasesWords,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Hiragana',
          child: IconButton(
            icon: const Text(
              'あ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            onPressed: widget.onNavigateToHiragana,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Katakana',
          child: IconButton(
            icon: const Text(
              'ア',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            onPressed: widget.onNavigateToKatakana,
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Learning',
          child: IconButton(
            icon: const Icon(Icons.school),
            onPressed: widget.onNavigateToDashboard,
          ),
        ),
      ),
    ];
  }

  /// Builds the search text field.
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

  /// Builds the decoration for the search field.
  InputDecoration _buildSearchDecoration(BuildContext context) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.search),
      suffixIcon: widget.textController.text.isNotEmpty
          ? StyledTooltip(
              message: 'Clear',
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClearSearch,
              ),
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

  /// Builds the action buttons (Learning, Settings, Exit).
  List<Widget> _buildActionButtons(BuildContext context) {
    return [
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Settings',
          child: IconButton(
            icon: const Icon(Icons.settings),
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
          message: 'Maximize',
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
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Exit',
          child: IconButton(
            onPressed: widget.onExit,
            icon: const Icon(Icons.close),
          ),
        ),
      ),
    ];
  }
}

/// Navigation drawer for mobile platforms.
///
/// Contains all navigation items that are shown in the app bar on desktop.
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
