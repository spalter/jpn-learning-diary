import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom app bar with integrated search functionality.
///
/// Provides a navigation bar with:
/// - Navigation buttons for diary, hiragana (あ), and katakana (ア) pages
/// - Add entry button for creating new diary entries
/// - Search field with submit functionality (searches when text present, navigates to diary when empty)
/// - Clear button (X) that appears when search has text
/// - Learning dashboard and settings buttons
/// - Exit button to close the application
/// - Custom styling matching the app theme
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

  /// Callback when add entry button is pressed.
  final VoidCallback onAddEntry;

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
    required this.onAddEntry,
    required this.onExit,
  });

  @override
  State<AppNavigationBar> createState() => AppNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// State for the navigation bar.
class AppNavigationBarState extends State<AppNavigationBar> {
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
      title: DragToMoveArea(
        child: Row(
          children: [
            ..._buildNavigationButtons(context),
            const Spacer(),
            _buildAddButton(context),
            const SizedBox(width: 8),
            _buildSearchField(context),
            const Spacer(),
          ],
        ),
      ),
      actions: [..._buildActionButtons(context), const SizedBox(width: 16)],
    );
  }

  /// Builds the navigation buttons (Diary, Hiragana, Katakana).
  List<Widget> _buildNavigationButtons(BuildContext context) {
    return [
      ExcludeFocus(
        child: IconButton(
          icon: const Icon(Icons.menu_book),
          tooltip: 'Diary (Phrases & Words)',
          onPressed: widget.onNavigateToPhrasesWords,
        ),
      ),
      ExcludeFocus(
        child: IconButton(
          icon: const Text(
            'あ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          tooltip: 'Hiragana',
          onPressed: widget.onNavigateToHiragana,
        ),
      ),
      ExcludeFocus(
        child: IconButton(
          icon: const Text(
            'ア',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          tooltip: 'Katakana',
          onPressed: widget.onNavigateToKatakana,
        ),
      ),
      ExcludeFocus(
        child: IconButton(
          icon: const Icon(Icons.school),
          tooltip: 'Learning',
          onPressed: widget.onNavigateToDashboard,
        ),
      ),
    ];
  }

  /// Builds the add entry button.
  Widget _buildAddButton(BuildContext context) {
    return ExcludeFocus(
      child: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Add new diary entry',
        onPressed: widget.onAddEntry,
      ),
    );
  }

  /// Builds the search text field.
  Widget _buildSearchField(BuildContext context) {
    return Expanded(
      flex: 3,
      child: GestureDetector(
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
      ),
    );
  }

  /// Builds the decoration for the search field with sharp edges.
  InputDecoration _buildSearchDecoration(BuildContext context) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.search),
      suffixIcon: widget.textController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Clear',
              onPressed: widget.onClearSearch,
            )
          : null,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
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
        child: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: widget.onNavigateToSettings,
        ),
      ),
      ExcludeFocus(
        child: IconButton(
          icon: const Icon(Icons.remove),
          tooltip: 'Minimize',
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
      ),
      ExcludeFocus(
        child: IconButton(
          icon: const Icon(Icons.crop_square),
          tooltip: 'Maximize',
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
      ExcludeFocus(
        child: IconButton(
          onPressed: widget.onExit,
          icon: const Icon(Icons.close),
          tooltip: 'Exit',
        ),
      ),
    ];
  }
}
