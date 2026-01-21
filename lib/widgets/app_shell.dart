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
import 'package:jpn_learning_diary/screens/learning_page.dart';
import 'package:jpn_learning_diary/screens/hiragana_page.dart';
import 'package:jpn_learning_diary/screens/katakana_page.dart';
import 'package:jpn_learning_diary/screens/diary_page.dart';
import 'package:jpn_learning_diary/screens/search_results_page.dart';
import 'package:jpn_learning_diary/screens/settings_page.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';

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

  /// Sets up the search controller and listens for text changes.
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchTextChanged);
  }

  /// Cleans up the search controller and focus node.
  @override
  void dispose() {
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
  ///
  /// Wraps everything in Shortcuts and Actions to enable keyboard navigation
  /// like Ctrl+F for search focus.
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _buildShortcuts(),
      child: Actions(
        actions: _buildActions(),
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppNavigationBar(
              key: _navigationBarKey,
              textController: _searchController,
              searchFocusNode: _searchFocusNode,
              onNavigateToPhrasesWords: () =>
                  _navigateToPage(AppPage.phrasesWords),
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
                    onNavigateToHiragana: () =>
                        _navigateToPage(AppPage.hiragana),
                    onNavigateToKatakana: () =>
                        _navigateToPage(AppPage.katakana),
                    onNavigateToDashboard: () =>
                        _navigateToPage(AppPage.dashboard),
                    onNavigateToSettings: () =>
                        _navigateToPage(AppPage.settings),
                  )
                : null,
            backgroundColor: AppTheme.scaffoldBackground(context),
            body: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                top: 16,
                right: 0,
                bottom: 0,
              ),
              child: _buildCurrentPage(),
            ),
            floatingActionButton: _currentPage != AppPage.settings
                ? BirdFab(onEntryCreated: _refreshCurrentPage)
                : null,
          ),
        ),
      ),
    );
  }

  /// Creates keyboard shortcut mappings for search focus.
  ///
  /// Supports Cmd+F on macOS, Ctrl+F on other platforms, plus / and F3 as
  /// universal alternatives.
  Map<LogicalKeySet, Intent> _buildShortcuts() {
    return <LogicalKeySet, Intent>{
      // Use Cmd+F on macOS, Ctrl+F on Windows/Linux
      LogicalKeySet(
        Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
        LogicalKeyboardKey.keyF,
      ): const FocusSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.slash): const FocusSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.f3): const FocusSearchIntent(),
    };
  }

  /// Creates action handlers that respond to keyboard shortcut intents.
  Map<Type, Action<Intent>> _buildActions() {
    return <Type, Action<Intent>>{
      FocusSearchIntent: CallbackAction<FocusSearchIntent>(
        onInvoke: (intent) {
          _focusSearchField();
          return null;
        },
      ),
    };
  }
}

/// Intent triggered by keyboard shortcuts to focus the search field.
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}
