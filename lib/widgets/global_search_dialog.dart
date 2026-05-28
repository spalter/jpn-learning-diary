// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/jmdict_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/jmdict_card.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';

/// A full-screen dialog providing unified search across diary entries,
/// the JMdict dictionary, and the kanji database.
///
/// This widget is displayed as a top-aligned overlay and accepts a text query
/// to search all three data sources simultaneously. Results are grouped by
/// category and displayed in a scrollable list. Tapping a result pops the
/// dialog and returns the selected term for further use by the caller.
class GlobalSearchDialog extends StatefulWidget {
  /// Creates a global search dialog.
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

/// Internal state for [GlobalSearchDialog] that manages search logic and results.
///
/// Handles debounced input, parallel repository queries, and result display.
/// The search fires 300ms after the user stops typing to avoid excessive
/// database lookups on every keystroke.
class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  /// Controller for the search input text field.
  final TextEditingController _controller = TextEditingController();

  /// Scroll controller for the results list view.
  final ScrollController _scrollController = ScrollController();

  /// Debounce timer that delays search execution after typing stops.
  Timer? _debounce;

  /// Repository for querying diary entries.
  final _diaryRepository = DiaryRepository();

  /// Repository for querying the JMdict dictionary.
  final _jmdictRepository = JMdictRepository();

  /// Repository for querying the kanji database.
  final _kanjiRepository = KanjiRepository();

  /// Diary entries matching the current search query.
  List<DiaryEntry> _diaryResults = [];

  /// Dictionary entries matching the current search query.
  List<JMdictEntry> _jmdictResults = [];

  /// Kanji characters matching the current search query.
  List<KanjiData> _kanjiResults = [];

  /// Whether a search is currently in progress.
  bool _isLoading = false;

  /// The last query that was actually executed, used to avoid duplicate searches.
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  /// Listener callback for the text controller that debounces search input.
  ///
  /// Cancels any pending debounce timer and schedules a new search after
  /// 300 milliseconds of inactivity so that rapid typing does not trigger
  /// a flurry of database queries.
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_controller.text);
    });
  }

  /// Executes a parallel search across diary, dictionary, and kanji repositories.
  ///
  /// Clears the results when [query] is empty and short-circuits when the
  /// query matches the last executed search. All three repository calls run
  /// concurrently via [Future.wait] for minimal latency.
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _lastQuery = '';
        _diaryResults = [];
        _jmdictResults = [];
        _kanjiResults = [];
        _isLoading = false;
      });
      return;
    }

    if (query == _lastQuery) return;

    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      final futures = await Future.wait([
        _diaryRepository.searchEntries(query),
        _jmdictRepository.search(query, limit: 5),
        _kanjiRepository.searchKanji(query),
      ]);

      if (mounted) {
        setState(() {
          _diaryResults = futures[0] as List<DiaryEntry>;
          _jmdictResults = futures[1] as List<JMdictEntry>;
          _kanjiResults = (futures[2] as List<KanjiData>).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Builds a labeled section header with an icon and title text.
  ///
  /// Used to visually separate result groups (diary, dictionary, kanji)
  /// inside the results list. The icon and title are styled with the
  /// primary color of the current theme.
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          const Divider(),
        ],
      ),
    );
  }

  /// Builds the main dialog layout with search input and results container.
  ///
  /// The dialog is aligned to the top of the screen with a fixed 800-pixel
  /// width and a maximum height of 700 pixels. An escape-key shortcut is
  /// bound to close the dialog.
  @override
  Widget build(BuildContext context) {
    final hasResults =
        _diaryResults.isNotEmpty ||
        _jmdictResults.isNotEmpty ||
        _kanjiResults.isNotEmpty;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: 24,
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: FocusScope(
          autofocus: true,
          child: Container(
            width: 800,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchInput(),
                if (hasResults ||
                    (_controller.text.isNotEmpty && !_isLoading)) ...[
                  const SizedBox(height: 16),
                  _buildResultsContainer(hasResults),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the search input field inside a decorated container.
  ///
  /// The field uses a borderless style with rounded corners and a subtle
  /// drop shadow. A spinning progress indicator replaces the suffix icon
  /// while a search is in flight. Submitting the field pops the dialog
  /// and returns the raw query string.
  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (value) {
          Navigator.of(context).pop(value);
        },
        decoration: InputDecoration(
          hintText: 'Search diary, dictionary, kanji...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Builds the scrollable results container that holds all result sections.
  ///
  /// The container has rounded corners with a muted border and drop shadow
  /// matching the search input above it. Inside, a shrink-wrapped [ListView]
  /// displays diary, dictionary, and kanji sections in order. When no results
  /// exist and a query has been entered, a centered "No results found"
  /// placeholder is shown instead.
  Widget _buildResultsContainer(bool hasResults) {
    return Flexible(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(80),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            controller: _scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
            children: [
              ..._buildDiaryResults(),
              ..._buildDictionaryResults(),
              ..._buildKanjiResults(),
              if (!hasResults && _controller.text.isNotEmpty && !_isLoading)
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the diary entries result section.
  ///
  /// Returns a list of widgets starting with a section header followed by
  /// a [DiaryEntryCard] for each matching entry. Tapping a card pops the
  /// dialog with the entry's Japanese text (with ruby patterns stripped).
  /// If a diary entry is edited in-place, the local results list is updated
  /// to reflect the change.
  List<Widget> _buildDiaryResults() {
    if (_diaryResults.isEmpty) return [];
    return [
      _buildSectionHeader('Diary Entries', Icons.book),
      FutureBuilder<List<bool>>(
        future: Future.wait([
          AppPreferences.getShowRomaji(),
          AppPreferences.getShowFurigana(),
        ]),
        builder: (context, snapshot) {
          final showRomaji = snapshot.data?[0] ?? true;
          final showFurigana = snapshot.data?[1] ?? true;
          return Column(
            children: _diaryResults
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: DiaryEntryCard(
                      entry: entry,
                      showRomaji: showRomaji,
                      showFurigana: showFurigana,
                      onTap: () => Navigator.of(context).pop(
                        JapaneseTextUtils.stripRubyPatterns(entry.japanese),
                      ),
                      onEntryUpdated: (updated) {
                        setState(() {
                          final index = _diaryResults.indexWhere(
                            (e) => e.id == updated.id,
                          );
                          if (index != -1) {
                            _diaryResults[index] = updated;
                          }
                        });
                      },
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ];
  }

  /// Builds the dictionary result section.
  ///
  /// Returns a list of widgets starting with a section header followed by
  /// a [JMdictCard] for each matching dictionary entry. Tapping a card pops
  /// the dialog with the entry's kanji writing as the selected term.
  List<Widget> _buildDictionaryResults() {
    if (_jmdictResults.isEmpty) return [];
    return [
      _buildSectionHeader('Dictionary', Icons.translate),
      ..._jmdictResults.map(
        (entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: JMdictCard(
            entry: entry,
            onTap: () => Navigator.of(context).pop(entry.kanji),
          ),
        ),
      ),
    ];
  }

  /// Builds the kanji result section.
  ///
  /// Returns a list of widgets starting with a section header followed by
  /// a [KanjiCard] for each matching kanji character. Tapping a card pops
  /// the dialog with the kanji character as the selected term.
  List<Widget> _buildKanjiResults() {
    if (_kanjiResults.isEmpty) return [];
    return [
      _buildSectionHeader('Kanji', Icons.edit),
      ..._kanjiResults.map(
        (kanji) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: KanjiCard(
            kanji: kanji,
            onTap: () => Navigator.of(context).pop(kanji.kanji),
          ),
        ),
      ),
    ];
  }

  /// Builds a centered placeholder message shown when a query yields no results.
  ///
  /// Displayed only after the search completes with zero matches across all
  /// three data sources while the query field is non-empty.
  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text('No results found')),
    );
  }
}
