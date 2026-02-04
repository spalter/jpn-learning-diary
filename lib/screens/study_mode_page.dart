// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/repositories/jmdict_repository.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/collapsible_section.dart';
import 'package:jpn_learning_diary/widgets/vertical_text_display.dart';
import 'package:jpn_learning_diary/widgets/study_search_results_panel.dart';

/// Study mode page for analyzing Japanese text with dictionary lookup.
///
/// This widget provides an environment for reading and analyzing Japanese text,
/// displaying it in traditional vertical (tategaki) format. It supports interactive
/// study sessions by allowing users to tap on words to look them up.
class StudyModePage extends StatefulWidget {
  const StudyModePage({super.key});

  @override
  State<StudyModePage> createState() => _StudyModePageState();
}

class _StudyModePageState extends State<StudyModePage> {
  /// Controller for the main text input field.
  final TextEditingController _textController = TextEditingController();

  /// Focus node for the text input field.
  /// Used to programmatically unfocus before showing mobile bottom sheet,
  /// preventing the keyboard from reappearing unexpectedly.
  final FocusNode _textFocusNode = FocusNode();

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
    return CollapsibleSection(
      isCollapsed: _isInputCollapsed,
      onCollapseChanged: (value) => setState(() => _isInputCollapsed = value),
      child: TextField(
        controller: _textController,
        focusNode: _textFocusNode,
        maxLines: _isInputCollapsed ? 1 : null,
        minLines: _isInputCollapsed ? 1 : 3,
        readOnly: _isInputCollapsed && _isMobile,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_isInputCollapsed ? 12 : 0),
            ),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(80),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_isInputCollapsed ? 12 : 0),
            ),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(80),
            ),
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
    );
  }

  /// Builds the main vertical text display area.
  Widget _buildLinesAndKanjiList(BuildContext context) {
    return VerticalTextDisplay(
      lines: _lines,
      selectedWord: _selectedWord,
      annotations: _tokenAnnotations,
      onWordTap: _searchWord,
      scrollController: _horizontalScrollController,
      isMobile: _isMobile,
    );
  }

  /// Builds the search results panel for desktop layout.
  /// Shows different states: hint, loading, no results, or results list.
  Widget _buildSearchResultsPanel(BuildContext context) {
    return StudySearchResultsPanel(
      selectedWord: _selectedWord,
      isSearching: _isSearching,
      results: _searchResults,
      currentAnnotation: _selectedWord != null ? _tokenAnnotations[_selectedWord!] : null,
      onAnnotationChanged: (value) {
        setState(() {
          if (value.isEmpty) {
            _tokenAnnotations.remove(_selectedWord);
          } else {
            _tokenAnnotations[_selectedWord!] = value;
          }
        });
      },
    );
  }

  /// Builds the search results content (used in both desktop panel and mobile sheet).
  Widget _buildSearchResultsContent(
    BuildContext context,
    ScrollController? scrollController,
  ) {
    return StudySearchResultsPanel(
      selectedWord: _selectedWord,
      isSearching: _isSearching,
      results: _searchResults,
      scrollController: scrollController,
      currentAnnotation: _selectedWord != null ? _tokenAnnotations[_selectedWord!] : null,
      onAnnotationChanged: (value) {
        setState(() {
          if (value.isEmpty) {
            _tokenAnnotations.remove(_selectedWord);
          } else {
            _tokenAnnotations[_selectedWord!] = value;
          }
        });
      },
    );
  }
}
