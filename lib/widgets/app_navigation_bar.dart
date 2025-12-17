import 'dart:io' show exit;

import 'package:flutter/material.dart';

/// Custom app bar with integrated search functionality.
///
/// Provides a navigation bar with:
/// - Menu button to open the navigation drawer
/// - Search field with auto-complete suggestions
/// - Window control buttons (minimize, maximize, close)
/// - Custom styling matching the app theme
class AppNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  /// Controller for the search text field.
  final TextEditingController textController;

  const AppNavigationBar({
    super.key,
    required this.textController,
  });

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// State for the navigation bar with search overlay management.
class _AppNavigationBarState extends State<AppNavigationBar> {
  /// Focus node for the search text field.
  final FocusNode _focusNode = FocusNode();
  
  /// Layer link for positioning the search suggestions overlay.
  final LayerLink _layerLink = LayerLink();
  
  /// Global key for the text field to get its position and size.
  final GlobalKey _textFieldKey = GlobalKey();
  
  /// The current search suggestions overlay entry.
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  /// Handles focus changes on the search text field.
  ///
  /// Shows the search suggestions overlay when focused,
  /// hides it when focus is lost.
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  /// Displays the search suggestions overlay below the search field.
  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Removes the search suggestions overlay from the screen.
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Creates the overlay entry for search suggestions.
  ///
  /// Positions the overlay below the search field and styles it
  /// to match the app theme.
  OverlayEntry _createOverlayEntry() {
    final RenderBox? renderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 400;
    
    return OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(128),
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  _buildSuggestionItem('Dummy Item 1', Icons.text_fields),
                  _buildSuggestionItem('Dummy Item 2', Icons.translate),
                  _buildSuggestionItem('Dummy Item 3', Icons.book),
                  _buildSuggestionItem('Dummy Item 4', Icons.school),
                  _buildSuggestionItem('Dummy Item 5', Icons.language),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String text, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(text),
      onTap: () {
        widget.textController.text = text;
        _focusNode.unfocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        tooltip: 'Menu',
      ),
      title: Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 3,
            child: CompositedTransformTarget(
              key: _textFieldKey,
              link: _layerLink,
              child: TextField(
                controller: widget.textController,
                focusNode: _focusNode,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withAlpha(128)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            exit(0);
          },
          icon: const Icon(Icons.close),
          tooltip: 'Exit',
        ),
      ],
    );
  }
}
