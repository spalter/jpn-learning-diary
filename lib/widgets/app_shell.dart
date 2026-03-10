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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/screens/learning_page.dart';
import 'package:jpn_learning_diary/screens/study_mode_page.dart';
import 'package:jpn_learning_diary/screens/kana_page.dart';
import 'package:jpn_learning_diary/screens/diary_page.dart';
import 'package:jpn_learning_diary/screens/help_page.dart';
import 'package:jpn_learning_diary/screens/settings_page.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/global_search_dialog.dart';
import 'package:jpn_learning_diary/screens/search_results_page.dart';
import 'package:jpn_learning_diary/widgets/edit_diary_entry_dialog.dart'
    show EditDiaryEntryDialog, EditDiaryEntryResult;

/// Returns true when running on Android or iOS where mobile UI patterns apply.
bool get _isMobile => Platform.isAndroid || Platform.isIOS;

/// Main application shell that manages navigation and persistent UI elements.
///
/// This widget serves as the root container for the app's main content, providing
/// a single persistent navigation bar instance.
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
  studyMode,
  dashboard,
  settings
}

/// Internal state for [AppShell] managing navigation.
///
/// Maintains the current page selection and handles navigation transitions
/// triggered by user interactions or keyboard shortcuts.
class _AppShellState extends State<AppShell> {
  /// The currently displayed page in the content area.
  AppPage _currentPage = AppPage.phrasesWords;

  /// Key used to force page rebuilds when data changes.
  Key _pageKey = UniqueKey();

  /// Whether to hide the mouse cursor (when using keyboard navigation).
  bool _hideMouseCursor = false;

  /// Sets up listeners.
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    _checkFirstLaunch();
  }

  /// Shows the help dialog on first launch.
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHelp = prefs.getBool('has_seen_help') ?? false;

    if (!hasSeenHelp && mounted) {
      // Small delay to ensure the app is fully rendered
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await _showHelpDialog();
        await prefs.setBool('has_seen_help', true);
      }
    }
  }

  /// Shows the help page as a dialog popup.
  Future<void> _showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: const HelpPage(isDialog: true),
        ),
      ),
    );
  }

  /// Cleans up listeners.
  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  /// Switches to the specified page if not already active.
  void _navigateToPage(AppPage page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  /// Forces the current page to rebuild by assigning a new key.
  void _refreshCurrentPage() {
    setState(() {
      _pageKey = UniqueKey();
    });
  }

  /// Shows the new diary entry dialog.
  Future<void> _showNewDiaryEntryDialog() async {
    final result = await showDialog<EditDiaryEntryResult>(
      context: context,
      builder: (context) => const EditDiaryEntryDialog(),
    );

    if (result?.updatedEntry != null) {
      _refreshCurrentPage();
    }
  }

  /// Opens the help page.
  void _openHelp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpPage()));
  }

  /// Shows the global search dialog.
  Future<void> _showGlobalSearch() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const GlobalSearchDialog(),
    );

    if (result != null && result.isNotEmpty && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(searchQuery: result),
        ),
      );
    }
  }

  /// Returns the widget for the currently selected page.
  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.phrasesWords:
        return DiaryPage(key: _pageKey);
      case AppPage.hiragana:
        return const KanaPage(type: KanaType.hiragana);
      case AppPage.katakana:
        return const KanaPage(type: KanaType.katakana);
      case AppPage.studyMode:
        return const StudyModePage();
      case AppPage.dashboard:
        return LearningPage(key: _pageKey);
      case AppPage.settings:
        return const SettingsPage();
    }
  }

  /// Builds the main scaffold with navigation bar, content, and floating button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavigationBar(
        currentPageIndex: _currentPage.index,
        onNavigateToPhrasesWords: () => _navigateToPage(AppPage.phrasesWords),
        onNavigateToHiragana: () => _navigateToPage(AppPage.hiragana),
        onNavigateToKatakana: () => _navigateToPage(AppPage.katakana),
        onNavigateToStudyMode: () => _navigateToPage(AppPage.studyMode),
        onNavigateToDashboard: () => _navigateToPage(AppPage.dashboard),
        onNavigateToSettings: () => _navigateToPage(AppPage.settings),
        onSearch: _showGlobalSearch,
        onExit: () => exit(0),
      ),
      // Show drawer on mobile platforms
      drawer: _isMobile
          ? AppNavigationDrawer(
              onNavigateToPhrasesWords: () =>
                  _navigateToPage(AppPage.phrasesWords),
              onNavigateToHiragana: () => _navigateToPage(AppPage.hiragana),
              onNavigateToKatakana: () => _navigateToPage(AppPage.katakana),
              onNavigateToStudyMode: () => _navigateToPage(AppPage.studyMode),
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
      floatingActionButton: _currentPage != AppPage.settings && _currentPage != AppPage.dashboard && _currentPage != AppPage.studyMode
          ? BirdFab(onEntryCreated: (_) => _refreshCurrentPage())
          : null,
    );
  }

  /// Global keyboard event handler for shortcuts.
  ///
  /// Registered with HardwareKeyboard to catch all key events regardless
  /// of widget focus. Supports:
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

    // Cmd+4 (Mac) / Ctrl+4 (Win/Linux) - Study Mode page
    if (key == LogicalKeyboardKey.digit4 && isNavModifierPressed) {
      _navigateToPage(AppPage.studyMode);
      return true;
    }

    // Cmd+5 (Mac) / Ctrl+5 (Win/Linux) - Learning/Dashboard page
    if (key == LogicalKeyboardKey.digit5 && isNavModifierPressed) {
      _navigateToPage(AppPage.dashboard);
      return true;
    }

    // Cmd+F (Mac) / Ctrl+F (Win/Linux) - Global search
    if (key == LogicalKeyboardKey.keyF) {
      if ((Platform.isMacOS && isMetaPressed) ||
          (!Platform.isMacOS && isControlPressed)) {
        _showGlobalSearch();
        return true;
      }
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

    // ? key (Shift+/) - Open help page
    // Only when not typing in a text field
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isFocusedOnTextField =
        primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() !=
        null;
    if (!isFocusedOnTextField) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if ((key == LogicalKeyboardKey.slash && isShiftPressed) ||
          key == LogicalKeyboardKey.f1) {
        _openHelp();
        return true;
      }
    }

    // Vim-like navigation: h/j/k/l map to arrow keys
    // Only when not typing in any text field and no modifiers pressed
    if (!isFocusedOnTextField && !isControlPressed && !isMetaPressed) {
      final primaryFocus = FocusManager.instance.primaryFocus;
      final focus = primaryFocus?.context != null
          ? FocusScope.of(primaryFocus!.context!)
          : FocusScope.of(context);

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
