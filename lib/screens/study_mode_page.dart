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

/// Study mode page for analyzing text and displaying kanji information.
///
/// Allows users to input Japanese text and see a breakdown of each line
/// with the kanji characters found in that line displayed as cards.
class StudyModePage extends StatefulWidget {
  const StudyModePage({super.key});

  @override
  State<StudyModePage> createState() => _StudyModePageState();
}

class _StudyModePageState extends State<StudyModePage> {
  final TextEditingController _textController = TextEditingController();
  final JMdictRepository _jmdictRepository = JMdictRepository();

  /// Focus node for the text input field.
  final FocusNode _textFocusNode = FocusNode();

  /// Static storage for session persistence of input text.
  static String _sessionText = '';

  /// Current lines parsed from the input text.
  List<String> _lines = [];

  /// Currently selected word/token.
  String? _selectedWord;

  /// Search results for the selected word.
  List<JMdictEntry> _searchResults = [];

  /// Whether a search is in progress.
  bool _isSearching = false;

  /// Whether the text input area is collapsed.
  bool _isInputCollapsed = false;

  /// User annotations for tokens (token -> note text).
  final Map<String, String> _tokenAnnotations = {};

  /// Controller for annotation input field.
  final TextEditingController _annotationController = TextEditingController();

  /// Scroll controller for horizontal text scrolling.
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Restore text from session storage
    if (_sessionText.isNotEmpty) {
      _textController.text = _sessionText;
    }
  }

  @override
  void dispose() {
    // Save text to session storage before disposing
    _sessionText = _textController.text;
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _annotationController.dispose();
    _textFocusNode.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// Called when the text in the input field changes.
  void _onTextChanged() {
    final text = _textController.text;
    final newLines = text.split('\n');

    setState(() {
      _lines = newLines;
    });
  }

  /// Punctuation characters that should not have nakaguro around them.
  static final RegExp _punctuationPattern = RegExp(
    r'^[、。！？「」『』（）〈〉《》【】〔〕・…―ー～，．：；]+$',
  );

  /// Opens Takoboto dictionary for the given word in a popup dialog.
  void _openTakoboto(String word) {
    if (!mounted) return;
    TakobotoViewer.showPopup(context, word);
  }

  /// Clears the current word selection.
  void _clearSelection() {
    if (_selectedWord != null) {
      setState(() {
        _selectedWord = null;
        _searchResults = [];
      });
    }
  }

  /// Whether we're on a mobile platform (Android/iOS).
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  /// Searches for meanings of the given word.
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

  /// Shows the search results in a bottom sheet (for mobile).
  void _showMobileResultsSheet() {
    // Unfocus the text input to prevent keyboard from reappearing
    _textFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMobileBottomSheet(context),
    );
  }

  /// Builds the mobile bottom sheet with search results.
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
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: const LearningModeAppBar(title: 'Study Mode'),
      floatingActionButton: const BirdFab(),
      body: GestureDetector(
        onTap: _clearSelection,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text input area
              _buildTextInputArea(context),
              const SizedBox(height: 12),

              // Main content area - responsive layout
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

  /// Builds the mobile layout (full-width text area only).
  Widget _buildMobileLayout(BuildContext context) {
    return _buildLinesAndKanjiList(context);
  }

  /// Builds the desktop layout (two-column with separator).
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side: vertical lines (60%)
        Expanded(flex: 3, child: _buildLinesAndKanjiList(context)),
        // Subtle glow separator
        Padding(
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
        ),
        // Right side: search results (40%)
        Expanded(flex: 2, child: _buildSearchResultsPanel(context)),
      ],
    );
  }

  /// Builds the search results panel for the right side.
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
  Widget _buildSearchResultsContent(
    BuildContext context,
    ScrollController? scrollController,
  ) {
    // Searching - show loading
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

    // Show results
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with selected word
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

  /// Builds the expandable text input area with collapse button.
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
            readOnly:
                _isInputCollapsed &&
                _isMobile, // Prevent focus when collapsed on mobile
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
              suffixIcon: _isInputCollapsed
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _isInputCollapsed = false;
                        });
                      },
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
        // Collapse button integrated into bottom border
        if (!_isInputCollapsed) _buildCollapseButton(context),
      ],
    );
  }

  /// Builds a subtle collapse handle.
  Widget _buildCollapseButton(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary.withAlpha(80);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isInputCollapsed = true;
          });
        },
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

  /// Builds the list view showing lines and their associated kanji cards.
  Widget _buildLinesAndKanjiList(BuildContext context) {
    if (_lines.isEmpty || (_lines.length == 1 && _lines[0].isEmpty)) {
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

    // Vertical layout: display lines from right to left with automatic line breaks
    // Use Listener to convert vertical scroll wheel to horizontal scroll
    final nonEmptyLines = _lines.where((l) => l.trim().isNotEmpty).toList();
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
        reverse: true, // Start from right side
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl, // Right to left
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

  /// Builds a vertical section for a single line (tategaki style) with line breaks.
  Widget _buildVerticalLineSection(
    BuildContext context,
    int lineIndex,
    String line, {
    bool isLast = false,
  }) {
    // Add bottom padding on mobile to avoid FAB overlap
    final bottomPadding = _isMobile ? 110.0 : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subtle divider between sections (not after last line in RTL)
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
            ),
          ),
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
  Widget _buildVerticalTokenizedText(BuildContext context, String line) {
    final tokens = JapaneseTextUtils.tokenize(
      line,
    ).where((t) => t.trim().isNotEmpty).toList();

    // Build list of token widgets (each token stays together as a unit)
    final List<Widget> elements = [];
    for (int i = 0; i < tokens.length; i++) {
      elements.add(
        _buildVerticalToken(context, tokens[i], _tokenAnnotations[tokens[i]]),
      );
    }

    // Use Wrap with vertical direction, flowing right to left
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

  /// Builds a vertical token (characters stacked top to bottom, kept as a unit).
  Widget _buildVerticalToken(
    BuildContext context,
    String token,
    String? annotation,
  ) {
    final isPunctuation = _punctuationPattern.hasMatch(token);
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 23);
    final isSelected = token == _selectedWord;
    const double tokenWidth = 22.0;

    if (isPunctuation) {
      // Punctuation stays as-is without fixed width to merge with previous token
      return Text(token, style: style);
    }

    // Display each character vertically, keeping the word together
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

  /// Builds the annotation input field for adding notes to selected tokens.
  Widget _buildAnnotationInput(BuildContext context) {
    final currentAnnotation = _tokenAnnotations[_selectedWord] ?? '';

    // Update controller if the selected word changed
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

/// A clickable vertical word widget for tategaki (vertical) text display.
class _ClickableVerticalWord extends StatefulWidget {
  final String word;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final TextStyle? style;
  final bool isSelected;
  final String? annotation;
  final double? fixedWidth;
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
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.style?.color ?? Theme.of(context).colorScheme.onSurface;
    final hoverColor = Theme.of(context).colorScheme.primary;
    final selectedColor = Theme.of(context).colorScheme.primary;

    // Determine the color based on state
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
        // Use IntrinsicHeight + Row so annotation affects height but not token position
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMainWordColumn(context, textColor),
              // Annotation column - zero-width container with overflow
              if (widget.annotation != null && widget.annotation!.isNotEmpty)
                SizedBox(
                  width: 0,
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Padding(
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

  /// Builds the main word column with optional fixed width.
  Widget _buildMainWordColumn(BuildContext context, Color textColor) {
    return SizedBox(
      width: widget.fixedWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background highlight layer - larger than text, can overflow
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
          // Text layer with minimal padding
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
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : null,
                        ) ??
                        TextStyle(
                          color: textColor,
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : null,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the annotation column.
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
