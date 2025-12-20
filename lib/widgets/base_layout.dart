import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';

/// Base layout widget that provides common UI elements for all pages.
///
/// Wraps page content with:
/// - Navigation bar with search field and navigation buttons
/// - Consistent background styling with theme colors
/// - Padding for content area
///
/// This eliminates the need to duplicate these elements in every page.
/// All application screens should be wrapped with this widget to maintain
/// consistent UI structure and navigation.
class BaseLayout extends StatefulWidget {
  /// The main content to display in the page body.
  final Widget child;
  
  /// Optional page title to display (currently unused, but available for future use).
  final String? title;
  
  /// Optional callback when a new entry is added.
  final VoidCallback? onEntryAdded;
  
  /// Optional initial text for the search field.
  final String? initialSearchText;

  const BaseLayout({
    super.key,
    required this.child,
    this.title,
    this.onEntryAdded,
    this.initialSearchText,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

/// State for the base layout, managing search field state.
class _BaseLayoutState extends State<BaseLayout> {
  /// Text controller for the search field in the navigation bar.
  late final TextEditingController _textController;
  
  /// Key to access the navigation bar's focus node.
  final GlobalKey<AppNavigationBarState> _navBarKey = GlobalKey<AppNavigationBarState>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialSearchText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  /// Handle Cmd+F shortcut to focus search field.
  void _focusSearchField() {
    _navBarKey.currentState?.focusSearchField();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _buildShortcuts(),
      child: Actions(
        actions: _buildActions(),
        child: _buildScaffold(context),
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
        onInvoke: (intent) => _focusSearchField(),
      ),
    };
  }

  /// Builds the main scaffold with app bar and content.
  Widget _buildScaffold(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: AppTheme.scaffoldBackground(context),
        body: _buildBody(),
      ),
    );
  }

  /// Builds the navigation bar app bar.
  PreferredSizeWidget _buildAppBar() {
    return AppNavigationBar(
      key: _navBarKey,
      textController: _textController,
      onEntryAdded: widget.onEntryAdded,
    );
  }

  /// Builds the body content with padding.
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 0, bottom: 0),
      child: widget.child,
    );
  }
}

/// Intent for focusing the search field.
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}
