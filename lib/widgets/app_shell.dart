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

/// Whether we're on a mobile platform (Android/iOS).
bool get _isMobile => Platform.isAndroid || Platform.isIOS;

/// Main application shell that manages navigation and persistent UI elements.
///
/// This widget provides:
/// - A single persistent navigation bar instance
/// - Content area that switches between different pages
/// - Centralized navigation state management
/// - Consistent search bar behavior across all pages
///
/// This architecture allows for:
/// - Live search capability
/// - No loss of search state during navigation
/// - Better performance (navigation bar doesn't rebuild)
/// - Smoother transitions without page route animations
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

/// Enum representing the different pages/views in the app.
enum AppPage {
  phrasesWords,
  hiragana,
  katakana,
  dashboard,
  settings,
  searchResults,
}

class _AppShellState extends State<AppShell> {
  /// Current active page.
  AppPage _currentPage = AppPage.phrasesWords;

  /// Text controller for the search field in the navigation bar.
  late final TextEditingController _searchController;

  /// Focus node for the search field.
  final FocusNode _searchFocusNode = FocusNode();

  /// Global key to access the navigation bar state.
  final GlobalKey<AppNavigationBarState> _navigationBarKey =
      GlobalKey<AppNavigationBarState>();

  /// Current search query (when on search results page).
  String _searchQuery = '';

  /// Key to force rebuild of pages when data changes.
  Key _pageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Called when search text changes.
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

  /// Navigates to a specific page.
  void _navigateToPage(AppPage page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  /// Handles search submission from the navigation bar.
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

  /// Clears search and navigates to phrases/words page.
  void _clearSearchAndNavigate() {
    _searchController.clear();
    _navigateToPage(AppPage.phrasesWords);
  }

  /// Refreshes the current page by generating a new key.
  void _refreshCurrentPage() {
    setState(() {
      _pageKey = UniqueKey();
    });
  }

  /// Focus the search field (for keyboard shortcuts).
  void _focusSearchField() {
    _searchFocusNode.requestFocus();
  }

  /// Sets search text and focuses the search field.
  void _setSearchText(String text) {
    _searchController.text = text;
    _searchFocusNode.requestFocus();
  }

  /// Builds the current page content based on navigation state.
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
            floatingActionButton: BirdFab(onEntryCreated: _refreshCurrentPage),
          ),
        ),
      ),
    );
  }

  /// Builds keyboard shortcuts for search field focus.
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

  /// Builds actions that respond to intents.
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

/// Intent for focusing the search field.
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}
