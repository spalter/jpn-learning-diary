import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavigationBar(
        textController: _textController,
        onEntryAdded: widget.onEntryAdded,
      ),
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, right:0, bottom: 0),
        child: widget.child,
      ),
    );
  }
}
