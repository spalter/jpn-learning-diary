// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

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
    }
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

              // Main content area split into two parts
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left side: vertical lines
                    Expanded(child: _buildLinesAndKanjiList(context)),
                    // Subtle glow separator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: 1,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(180),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(60),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(30),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right side: search results
                    Expanded(child: _buildSearchResultsPanel(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            maxLines: _isInputCollapsed ? 1 : null,
            minLines: _isInputCollapsed ? 1 : 3,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Start from right side
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl, // Right to left
        children: [
          for (int index = 0; index < _lines.length; index++)
            if (_lines[index].trim().isNotEmpty)
              _buildVerticalLineSection(context, index, _lines[index]),
        ],
      ),
    );
  }

  /// Builds a vertical section for a single line (tategaki style) with line breaks.
  Widget _buildVerticalLineSection(
    BuildContext context,
    int lineIndex,
    String line,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Line number badge at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${lineIndex + 1}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Vertical text with line breaks (wraps to new columns)
          Expanded(child: _buildVerticalTokenizedText(context, line)),
        ],
      ),
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
      crossAxisAlignment:
          WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 8, // Space between columns
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
    final style = Theme.of(context).textTheme.titleLarge;
    final isSelected = token == _selectedWord;
    const double tokenWidth = 20.0;

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

  const _ClickableVerticalWord({
    required this.word,
    required this.onTap,
    this.onLongPress,
    this.style,
    this.isSelected = false,
    this.annotation,
    this.fixedWidth,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main word column with optional fixed width
            SizedBox(
              width: widget.fixedWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Background highlight layer - larger than text, can overflow
                  if (widget.isSelected)
                    Positioned.fill(
                      top: -2,
                      bottom: -3,
                      left: -4,
                      right: -4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  // Text layer with minimal padding
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 1,
                      vertical: 1,
                    ),
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
            ),
            // Annotation column (to the right of the main text, like furigana)
            if (widget.annotation != null && widget.annotation!.isNotEmpty)
              Transform.translate(
                offset: const Offset(4, 0), // Visual offset without affecting layout
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final char in widget.annotation!.characters)
                      Text(
                        char,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.0,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(180),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
