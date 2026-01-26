// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show Platform, exit;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/screens/learning_page.dart';
import 'package:jpn_learning_diary/screens/hiragana_page.dart';
import 'package:jpn_learning_diary/screens/katakana_page.dart';
import 'package:jpn_learning_diary/screens/diary_page.dart';
import 'package:jpn_learning_diary/screens/search_results_page.dart';
import 'package:jpn_learning_diary/screens/settings_page.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/edit_diary_entry_dialog.dart';

/// Returns true when running on Android or iOS where mobile UI patterns apply.
bool get _isMobile => Platform.isAndroid || Platform.isIOS;

/// Main application shell that manages navigation and persistent UI elements.
///
/// This widget serves as the root container for the app's main content, providing
/// a single persistent navigation bar instance that maintains search state across
/// page transitions. The architecture enables live search capability without losing
/// user input when switching between pages, and avoids rebuilding the navigation
/// bar for better performance and smoother transitions.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

/// Represents the different pages available in the main navigation.
enum AppPage {
  phrasesWords,
  hiragana,
  katakana,
  dashboard,
  settings,
  searchResults,
}

/// Internal state for [AppShell] managing navigation and search.
///
/// Maintains the current page selection, search controller, and handles
/// navigation transitions triggered by user interactions or keyboard shortcuts.
class _AppShellState extends State<AppShell> {
  /// The currently displayed page in the content area.
  AppPage _currentPage = AppPage.phrasesWords;

  /// Controller for the search text field shared across all pages.
  late final TextEditingController _searchController;

  /// Focus node for programmatic focus control of the search field.
  final FocusNode _searchFocusNode = FocusNode();

  /// Key for accessing the navigation bar's state to insert search text.
  final GlobalKey<AppNavigationBarState> _navigationBarKey =
      GlobalKey<AppNavigationBarState>();

  /// The current search query used by the search results page.
  String _searchQuery = '';

  /// Key used to force page rebuilds when data changes.
  Key _pageKey = UniqueKey();

  /// Whether to hide the mouse cursor (when using keyboard navigation).
  bool _hideMouseCursor = false;

  /// Sets up the search controller and listens for text changes.
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchTextChanged);
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  /// Cleans up the search controller and focus node.
  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Responds to search text changes with automatic navigation.
  ///
  /// Navigates to search results when text is entered, or returns to the
  /// phrases/words page when the search is cleared.
  void _onSearchTextChanged() {
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      // Automatically navigate to search results and update query
      setState(() {
        _currentPage = AppPage.searchResults;
        _searchQuery = query;
      });
    } else if (_currentPage == AppPage.searchResults) {
      // If search is cleared while on search results, go back to phrases/words
      setState(() {
        _currentPage = AppPage.phrasesWords;
        _searchQuery = '';
      });
    }
  }

  /// Switches to the specified page if not already active.
  void _navigateToPage(AppPage page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  /// Processes search submission and navigates to results or clears search.
  ///
  /// After searching, selects all text in the search field for easy editing
  /// of follow-up queries.
  void _handleSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _currentPage = AppPage.searchResults;
        _searchQuery = query.trim();
      });
      // Select all text after search for easy editing
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
        }
      });
    } else {
      // Empty search navigates to phrases/words page
      _navigateToPage(AppPage.phrasesWords);
    }
  }

  /// Clears the search field and returns to the phrases/words page.
  void _clearSearchAndNavigate() {
    _searchController.clear();
    _navigateToPage(AppPage.phrasesWords);
  }

  /// Forces the current page to rebuild by assigning a new key.
  void _refreshCurrentPage() {
    setState(() {
      _pageKey = UniqueKey();
    });
  }

  /// Requests focus on the search field for keyboard shortcut handling.
  void _focusSearchField() {
    _searchFocusNode.requestFocus();
  }

  /// Shows the new diary entry dialog.
  Future<void> _showNewDiaryEntryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const EditDiaryEntryDialog(),
    );

    if (result == true) {
      _refreshCurrentPage();
    }
  }

  /// Populates the search field with text and focuses it for editing.
  void _setSearchText(String text) {
    _searchController.text = text;
    _searchFocusNode.requestFocus();
  }

  /// Returns the widget for the currently selected page.
  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.phrasesWords:
        return DiaryPage(key: _pageKey, onSearchTextSet: _setSearchText);
      case AppPage.hiragana:
        return const HiraganaPage();
      case AppPage.katakana:
        return const KatakanaPage();
      case AppPage.dashboard:
        return LearningPage(key: _pageKey);
      case AppPage.settings:
        return const SettingsPage();
      case AppPage.searchResults:
        return SearchResultsPage(
          key: _pageKey,
          searchQuery: _searchQuery,
          onSearchTextSet: _setSearchText,
          navigationBarKey: _navigationBarKey,
        );
    }
  }

  /// Builds the main scaffold with navigation bar, content, and floating button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavigationBar(
        key: _navigationBarKey,
        textController: _searchController,
        searchFocusNode: _searchFocusNode,
        currentPageIndex: _currentPage.index,
        onNavigateToPhrasesWords: () => _navigateToPage(AppPage.phrasesWords),
        onNavigateToHiragana: () => _navigateToPage(AppPage.hiragana),
        onNavigateToKatakana: () => _navigateToPage(AppPage.katakana),
        onNavigateToDashboard: () => _navigateToPage(AppPage.dashboard),
        onNavigateToSettings: () => _navigateToPage(AppPage.settings),
        onSearch: _handleSearch,
        onClearSearch: _clearSearchAndNavigate,
        onExit: () => exit(0),
      ),
      // Show drawer on mobile platforms
      drawer: _isMobile
          ? AppNavigationDrawer(
              onNavigateToPhrasesWords: () =>
                  _navigateToPage(AppPage.phrasesWords),
              onNavigateToHiragana: () => _navigateToPage(AppPage.hiragana),
              onNavigateToKatakana: () => _navigateToPage(AppPage.katakana),
              onNavigateToDashboard: () => _navigateToPage(AppPage.dashboard),
              onNavigateToSettings: () => _navigateToPage(AppPage.settings),
            )
          : null,
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: MouseRegion(
        cursor: _hideMouseCursor ? SystemMouseCursors.none : MouseCursor.defer,
        onHover: (_) {
          if (_hideMouseCursor) {
            setState(() {
              _hideMouseCursor = false;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            top: 16,
            right: 0,
            bottom: 0,
          ),
          child: _buildCurrentPage(),
        ),
      ),
      floatingActionButton: _currentPage != AppPage.settings
          ? BirdFab(onEntryCreated: _refreshCurrentPage)
          : null,
    );
  }

  /// Global keyboard event handler for shortcuts.
  ///
  /// Registered with HardwareKeyboard to catch all key events regardless
  /// of widget focus. Supports:
  /// - Cmd+F/Ctrl+F for search focus
  /// - F11 for fullscreen toggle
  /// - Option+1-4 (Mac) / Ctrl+1-4 (Win/Linux) for page navigation
  /// - Cmd+,/Ctrl+, for settings
  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final key = event.logicalKey;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

    // Cmd+F on macOS, Ctrl+F on Windows/Linux - focus search
    if (key == LogicalKeyboardKey.keyF) {
      if ((Platform.isMacOS && isMetaPressed) ||
          (!Platform.isMacOS && isControlPressed)) {
        _focusSearchField();
        return true;
      }
    }

    // Cmd+N on macOS, Ctrl+N on Windows/Linux - new diary entry
    if (key == LogicalKeyboardKey.keyN) {
      if ((Platform.isMacOS && isMetaPressed) ||
          (!Platform.isMacOS && isControlPressed)) {
        _showNewDiaryEntryDialog();
        return true;
      }
    }

    // F11 for fullscreen toggle
    if (key == LogicalKeyboardKey.f11 && !_isMobile) {
      _toggleFullscreen();
      return true;
    }

    // Navigation modifier: Cmd on Mac, Ctrl on Windows/Linux
    final isNavModifierPressed = Platform.isMacOS
        ? isMetaPressed
        : isControlPressed;

    // Cmd+1 (Mac) / Ctrl+1 (Win/Linux) - Diary page
    if (key == LogicalKeyboardKey.digit1 && isNavModifierPressed) {
      _navigateToPage(AppPage.phrasesWords);
      return true;
    }

    // Cmd+2 (Mac) / Ctrl+2 (Win/Linux) - Hiragana page
    if (key == LogicalKeyboardKey.digit2 && isNavModifierPressed) {
      _navigateToPage(AppPage.hiragana);
      return true;
    }

    // Cmd+3 (Mac) / Ctrl+3 (Win/Linux) - Katakana page
    if (key == LogicalKeyboardKey.digit3 && isNavModifierPressed) {
      _navigateToPage(AppPage.katakana);
      return true;
    }

    // Cmd+4 (Mac) / Ctrl+4 (Win/Linux) - Learning/Dashboard page
    if (key == LogicalKeyboardKey.digit4 && isNavModifierPressed) {
      _navigateToPage(AppPage.dashboard);
      return true;
    }

    // Cmd+, on macOS, Ctrl+, on Windows/Linux - Settings
    if (key == LogicalKeyboardKey.comma) {
      if ((Platform.isMacOS && isMetaPressed) ||
          (!Platform.isMacOS && isControlPressed)) {
        _navigateToPage(AppPage.settings);
        return true;
      }
    }

    // Escape - unfocus current element
    if (key == LogicalKeyboardKey.escape) {
      FocusScope.of(context).unfocus();
      return true;
    }

    // Vim-like navigation: h/j/k/l map to arrow keys
    // Only when not typing in search field and no modifiers pressed
    final isFocusedOnTextField = _searchFocusNode.hasFocus;
    if (!isFocusedOnTextField && !isControlPressed && !isMetaPressed) {
      final focus = FocusScope.of(context);

      if (key == LogicalKeyboardKey.keyH) {
        // Move left
        setState(() => _hideMouseCursor = true);
        focus.focusInDirection(TraversalDirection.left);
        return true;
      } else if (key == LogicalKeyboardKey.keyJ) {
        // Move down
        setState(() => _hideMouseCursor = true);
        focus.focusInDirection(TraversalDirection.down);
        return true;
      } else if (key == LogicalKeyboardKey.keyK) {
        // Move up
        setState(() => _hideMouseCursor = true);
        focus.focusInDirection(TraversalDirection.up);
        return true;
      } else if (key == LogicalKeyboardKey.keyL) {
        // Move right
        setState(() => _hideMouseCursor = true);
        focus.focusInDirection(TraversalDirection.right);
        return true;
      }
    }

    return false;
  }

  /// Toggles fullscreen mode on desktop platforms.
  Future<void> _toggleFullscreen() async {
    final isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);
  }
}
