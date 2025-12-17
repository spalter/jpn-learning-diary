import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_menu.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';

/// Base layout widget that provides common UI elements for all pages.
///
/// Wraps page content with:
/// - Navigation bar with search field
/// - Side menu drawer
/// - Consistent background styling
///
/// This eliminates the need to duplicate these elements in every page.
class BaseLayout extends StatefulWidget {
  /// The main content to display in the page body.
  final Widget child;
  
  /// Optional page title to display (currently unused, but available for future use).
  final String? title;
  
  /// Optional callback when a new entry is added.
  final VoidCallback? onEntryAdded;

  const BaseLayout({
    super.key,
    required this.child,
    this.title,
    this.onEntryAdded,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

/// State for the base layout, managing search field state.
class _BaseLayoutState extends State<BaseLayout> {
  /// Text controller for the search field in the navigation bar.
  final TextEditingController _textController = TextEditingController();

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
      drawer: const AppMenu(),
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 0),
        child: widget.child,
      ),
    );
  }
}
