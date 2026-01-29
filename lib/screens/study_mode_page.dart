// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show Platform;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/repositories/jmdict_repository.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/jmdict_card.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/takoboto_viewer.dart';

//// This page provides an interactive study environment for Japanese text:
/// Study mode page for analyzing Japanese text with dictionary lookup.
///
/// Displays text in traditional vertical (tategaki) format and provides
/// interactive word search capabilities using the JMdict dictionary.
class StudyModePage extends StatefulWidget {
  const StudyModePage({super.key});

  @override
  State<StudyModePage> createState() => _StudyModePageState();
}

class _StudyModePageState extends State<StudyModePage> {
  /// Punctuation characters that should not be treated as searchable tokens.
  /// These merge visually with adjacent text and don't need click handlers.
  static final RegExp _punctuationPattern = RegExp(
    r'^[、。！？「」『』（）〈〉《》【】〔〕・…―ー～，．：；]+$',
  );

  /// Controller for the main text input field.
  final TextEditingController _textController = TextEditingController();

  /// Focus node for the text input field.
  /// Used to programmatically unfocus before showing mobile bottom sheet,
  /// preventing the keyboard from reappearing unexpectedly.
  final FocusNode _textFocusNode = FocusNode();

  /// Controller for the annotation input in the results panel.
  final TextEditingController _annotationController = TextEditingController();

  /// Controller for horizontal scrolling of the vertical text display.
  /// Enables custom scroll behavior (mouse wheel without shift key).
  final ScrollController _horizontalScrollController = ScrollController();

  /// Static storage for session persistence of input text.
  /// Preserves text when navigating away and returning to the page.
  static String _sessionText = '';

  /// Current lines parsed from the input text.
  List<String> _lines = [];

  /// Currently selected word/token for dictionary lookup.
  String? _selectedWord;

  /// Dictionary search results for the selected word.
  List<JMdictEntry> _searchResults = [];

  /// Whether a dictionary search is currently in progress.
  bool _isSearching = false;

  /// Whether the text input area is collapsed to save space.
  bool _isInputCollapsed = false;

  /// User annotations for tokens (token -> annotation text).
  /// Annotations appear next to words in the vertical text display.
  final Map<String, String> _tokenAnnotations = {};

  /// Repository for JMdict dictionary lookups.
  final JMdictRepository _jmdictRepository = JMdictRepository();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    // Restore text from session storage if available
    if (_sessionText.isNotEmpty) {
      _textController.text = _sessionText;
    }
  }

  @override
  void dispose() {
    // Save text to session storage before disposing
    _sessionText = _textController.text;

    // Clean up listeners and controllers
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _annotationController.dispose();
    _textFocusNode.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// Whether the app is running on a mobile platform (Android/iOS).
  /// Used to adapt the layout and interaction patterns.
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  /// Called when the text in the input field changes.
  /// Parses the text into lines for vertical display.
  void _onTextChanged() {
    final text = _textController.text;
    final newLines = text.split('\n');

    setState(() {
      _lines = newLines;
    });
  }

  /// Clears the current word selection and search results.
  /// Called when tapping outside of any word.
  void _clearSelection() {
    if (_selectedWord != null) {
      setState(() {
        _selectedWord = null;
        _searchResults = [];
      });
    }
  }

  /// Searches for dictionary entries matching the given word.
  /// Updates the selection state and triggers UI updates.
  /// On mobile, shows results in a bottom sheet.
  Future<void> _searchWord(String word) async {
    setState(() {
      _selectedWord = word;
      _isSearching = true;
    });

    final results = await _jmdictRepository.searchByToken(word, limit: 20);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      // On mobile, show bottom sheet with results
      if (_isMobile) {
        _showMobileResultsSheet();
      }
    }
  }

  /// Opens the Takoboto dictionary app/website for the given word.
  /// Triggered by long-pressing a word.
  void _openTakoboto(String word) {
    if (!mounted) return;
    TakobotoViewer.showPopup(context, word);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: const LearningModeAppBar(title: 'Study Mode'),
      floatingActionButton: const BirdFab(),
      body: GestureDetector(
        // Clear selection when tapping empty space
        onTap: _clearSelection,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Collapsible text input area
              _buildTextInputArea(context),
              const SizedBox(height: 12),

              // Main content area - adapts to platform
              Expanded(
                child: _isMobile
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the mobile layout: full-width vertical text area.
  /// Search results appear in a bottom sheet when a word is selected.
  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: _buildLinesAndKanjiList(context),
    );
  }

  /// Builds the desktop layout: two-column split with glowing separator.
  /// Left side (60%): vertical text display
  /// Right side (40%): search results panel
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side: vertical text (60%)
        Expanded(flex: 3, child: _buildLinesAndKanjiList(context)),

        // Glowing vertical separator (decorative)
        _buildGlowingSeparator(context),

        // Right side: search results (40%)
        Expanded(flex: 2, child: _buildSearchResultsPanel(context)),
      ],
    );
  }

  /// Builds the decorative glowing vertical separator for desktop layout.
  Widget _buildGlowingSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 1,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(180),
          borderRadius: BorderRadius.circular(1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withAlpha(60),
              blurRadius: 4,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the search results in a draggable bottom sheet (mobile only).
  /// Unfocuses the text input first to prevent keyboard issues.
  void _showMobileResultsSheet() {
    // Unfocus text input to prevent keyboard from reappearing
    _textFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMobileBottomSheet(context),
    );
  }

  /// Builds the draggable bottom sheet container for mobile.
  /// Includes a drag handle and the search results content.
  Widget _buildMobileBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle indicator
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Search results content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchResultsContent(context, scrollController),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the collapsible text input area at the top of the page.
  /// Features an animated height transition and a collapse handle.
  Widget _buildTextInputArea(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary.withAlpha(80);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text field with animated height
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(
            minHeight: _isInputCollapsed ? 40 : 80,
            maxHeight: _isInputCollapsed ? 40 : 200,
          ),
          child: TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            maxLines: _isInputCollapsed ? 1 : null,
            minLines: _isInputCollapsed ? 1 : 3,
            // Prevent focus when collapsed on mobile to avoid keyboard popup
            readOnly: _isInputCollapsed && _isMobile,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isInputCollapsed ? 12 : 0),
                ),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isInputCollapsed ? 12 : 0),
                ),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isInputCollapsed ? 12 : 0),
                ),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: _isInputCollapsed ? 8 : 16,
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha(20),
              // Show expand button when collapsed
              suffixIcon: _isInputCollapsed
                  ? IconButton(
                      onPressed: () => setState(() => _isInputCollapsed = false),
                      icon: Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Expand',
                    )
                  : null,
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ),
        // Collapse handle (only shown when expanded)
        if (!_isInputCollapsed) _buildCollapseHandle(context),
      ],
    );
  }

  /// Builds the subtle collapse handle below the text input.
  /// Styled as a grip line to indicate draggability.
  Widget _buildCollapseHandle(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary.withAlpha(80);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _isInputCollapsed = true),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            // Small horizontal grip line
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main vertical text display area.
  /// Shows an empty state hint when no text is entered, or the vertical
  /// tokenized text with right-to-left line flow.
  Widget _buildLinesAndKanjiList(BuildContext context) {
    // Empty state
    if (_lines.isEmpty || (_lines.length == 1 && _lines[0].isEmpty)) {
      return _buildEmptyStateHint(context);
    }

    // Filter out empty lines for display
    final nonEmptyLines = _lines.where((l) => l.trim().isNotEmpty).toList();

    // Vertical layout with custom scroll behavior:
    // Listener converts vertical mouse wheel to horizontal scroll,
    // allowing natural scrolling without holding Shift key.
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final offset =
              _horizontalScrollController.offset - event.scrollDelta.dy;
          _horizontalScrollController.jumpTo(
            offset.clamp(
              0.0,
              _horizontalScrollController.position.maxScrollExtent,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        reverse: true, // Start from right side (traditional Japanese)
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl, // Lines flow right to left
          children: [
            for (int index = 0; index < nonEmptyLines.length; index++)
              _buildVerticalLineSection(
                context,
                index,
                nonEmptyLines[index],
                isLast: index == nonEmptyLines.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the empty state hint when no text has been entered.
  Widget _buildEmptyStateHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter some Japanese text above',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kanji found in each line will be displayed here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a vertical section for a single line (tategaki style).
  /// Includes a subtle divider between line sections (except after the last).
  Widget _buildVerticalLineSection(
    BuildContext context,
    int lineIndex,
    String line, {
    bool isLast = false,
  }) {
    // Add bottom padding on mobile to avoid FAB (floating bird) overlap
    final bottomPadding = _isMobile ? 110.0 : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subtle divider between sections (not after last line in RTL layout)
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
            ),
          ),
        // The vertical tokenized text for this line
        Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: isLast ? 8 : 0,
            bottom: bottomPadding,
          ),
          child: _buildVerticalTokenizedText(context, line),
        ),
      ],
    );
  }

  /// Builds vertical tokenized text with automatic column wrapping.
  /// Tokenizes the line and displays each token as a vertical unit.
  Widget _buildVerticalTokenizedText(BuildContext context, String line) {
    final tokens = JapaneseTextUtils.tokenize(
      line,
    ).where((t) => t.trim().isNotEmpty).toList();

    // Build list of token widgets
    final List<Widget> elements = [];
    for (int i = 0; i < tokens.length; i++) {
      elements.add(
        _buildVerticalToken(context, tokens[i], _tokenAnnotations[tokens[i]]),
      );
    }

    // Wrap flows vertically down, then creates new columns to the left
    return Wrap(
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.down,
      textDirection: TextDirection.rtl, // New columns appear to the left
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: _isMobile ? 16 : 12, // More space between columns on mobile
      children: elements,
    );
  }

  /// Builds a single vertical token (word displayed character-by-character).
  /// Punctuation is rendered inline without interaction.
  /// Words are clickable for dictionary lookup and support annotations.
  Widget _buildVerticalToken(
    BuildContext context,
    String token,
    String? annotation,
  ) {
    final isPunctuation = _punctuationPattern.hasMatch(token);
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 23);
    final isSelected = token == _selectedWord;
    const double tokenWidth = 22.0;

    // Punctuation: simple text without interaction
    if (isPunctuation) {
      return Text(token, style: style);
    }

    // Word: clickable with hover effects and optional annotation
    return _ClickableVerticalWord(
      word: token,
      isSelected: isSelected,
      annotation: annotation,
      onTap: () => _searchWord(token),
      onLongPress: () => _openTakoboto(token),
      style: style,
      fixedWidth: tokenWidth,
      isMobile: _isMobile,
    );
  }

  /// Builds the search results panel for desktop layout.
  /// Shows different states: hint, loading, no results, or results list.
  Widget _buildSearchResultsPanel(BuildContext context) {
    // No word selected - show hint
    if (_selectedWord == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap a word to search',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dictionary results will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      );
    }

    return _buildSearchResultsContent(context, null);
  }

  /// Builds the search results content (used in both desktop panel and mobile sheet).
  /// Handles loading state, empty results, and the results list with annotation input.
  Widget _buildSearchResultsContent(
    BuildContext context,
    ScrollController? scrollController,
  ) {
    // Loading state
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for "$_selectedWord"...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      );
    }

    // No results found
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_selectedWord"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      );
    }

    // Results list with header and annotation input
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with selected word and result count
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                _selectedWord!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_searchResults.length} results)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        // Annotation input field
        _buildAnnotationInput(context),
        const SizedBox(height: 12),
        // Results list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return JMdictCard(
                entry: _searchResults[index],
                useBorderedStyle: false,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the annotation input field for adding notes to selected tokens.
  /// Annotations appear as small text next to words in the vertical display.
  Widget _buildAnnotationInput(BuildContext context) {
    final currentAnnotation = _tokenAnnotations[_selectedWord] ?? '';

    // Sync controller with current annotation value
    if (_annotationController.text != currentAnnotation) {
      _annotationController.text = currentAnnotation;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_note,
            size: 18,
            color: Theme.of(context).colorScheme.primary.withAlpha(150),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _annotationController,
              decoration: InputDecoration(
                hintText: 'Add note (e.g., reading, meaning)...',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    _tokenAnnotations.remove(_selectedWord);
                  } else {
                    _tokenAnnotations[_selectedWord!] = value;
                  }
                });
              },
            ),
          ),
          // Clear button
          if (_annotationController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _annotationController.clear();
                  _tokenAnnotations.remove(_selectedWord);
                });
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
            ),
        ],
      ),
    );
  }
}

// These widgets are only used within this page and handle the interactive
// vertical text display with hover/selection states and annotations.

/// A clickable vertical word widget for tategaki (vertical) text display.
///
/// Displays a word character-by-character in a vertical column with:
class _ClickableVerticalWord extends StatefulWidget {
  /// The word to display vertically.
  final String word;

  /// Callback when the word is tapped (triggers dictionary search).
  final VoidCallback onTap;

  /// Callback when the word is long-pressed (opens Takoboto).
  final VoidCallback? onLongPress;

  /// Text style for the word characters.
  final TextStyle? style;

  /// Whether this word is currently selected.
  final bool isSelected;

  /// Optional annotation to display next to the word.
  final String? annotation;

  /// Fixed width for consistent character alignment.
  final double? fixedWidth;

  /// Whether we're on mobile (affects annotation spacing).
  final bool isMobile;

  const _ClickableVerticalWord({
    required this.word,
    required this.onTap,
    this.onLongPress,
    this.style,
    this.isSelected = false,
    this.annotation,
    this.fixedWidth,
    this.isMobile = false,
  });

  @override
  State<_ClickableVerticalWord> createState() => _ClickableVerticalWordState();
}

class _ClickableVerticalWordState extends State<_ClickableVerticalWord> {
  /// Whether the mouse is currently hovering over this word.
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Determine text color based on interaction state
    final baseColor =
        widget.style?.color ?? Theme.of(context).colorScheme.onSurface;
    final hoverColor = Theme.of(context).colorScheme.primary;
    final selectedColor = Theme.of(context).colorScheme.primary;

    Color textColor;
    if (widget.isSelected) {
      textColor = selectedColor;
    } else if (_isHovering) {
      textColor = hoverColor;
    } else {
      textColor = baseColor;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        // IntrinsicHeight + Row: annotation affects height but not word position.
        // This ensures the word stays aligned while annotation can overflow.
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMainWordColumn(context, textColor),
              // Annotation: zero-width container with overflow to avoid shifting word
              if (widget.annotation != null && widget.annotation!.isNotEmpty)
                SizedBox(
                  width: 0,
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      // More spacing on mobile for touch readability
                      padding: EdgeInsets.only(left: widget.isMobile ? 8 : 2),
                      child: _buildAnnotationColumn(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the main word column with selection highlight.
  Widget _buildMainWordColumn(BuildContext context, Color textColor) {
    return SizedBox(
      width: widget.fixedWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Selection highlight background (slightly larger than text)
          if (widget.isSelected)
            Positioned.fill(
              top: -1,
              bottom: -3,
              left: -4,
              right: -8,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          // Text layer: each character stacked vertically
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final char in widget.word.characters)
                  Text(
                    char,
                    style:
                        widget.style?.copyWith(
                          color: textColor,
                          fontWeight: widget.isSelected ? FontWeight.bold : null,
                        ) ??
                        TextStyle(
                          color: textColor,
                          fontWeight: widget.isSelected ? FontWeight.bold : null,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the annotation column (small vertical text next to the word).
  Widget _buildAnnotationColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final char in widget.annotation!.characters)
          Text(
            char,
            style: TextStyle(
              fontSize: 12,
              height: 1.0,
              color: Theme.of(context).colorScheme.primary.withAlpha(180),
            ),
          ),
      ],
    );
  }
}
