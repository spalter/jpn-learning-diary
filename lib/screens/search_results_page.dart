// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/jmdict_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/jmdict_card.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/section_header.dart';

/// Search results page for displaying matches across all data sources.
///
/// This widget aggregates and displays search results from multiple repositories
/// based on the user's query. It segments results into different categories to
/// providing comprehensive coverage.
class SearchResultsPage extends StatefulWidget {
  /// The search query text.
  final String searchQuery;

  /// Callback to set search text in the navigation bar.
  final void Function(String)? onSearchTextSet;

  /// Global key to access the navigation bar for inserting search text.
  final GlobalKey<AppNavigationBarState>? navigationBarKey;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    this.onSearchTextSet,
    this.navigationBarKey,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<_SearchResults> _searchFuture;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(SearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-run search when the search query changes
    if (oldWidget.searchQuery != widget.searchQuery) {
      _performSearch();
    }
  }

  void _performSearch() {
    setState(() {
      _searchFuture = _search();
    });
  }

  /// Calculates the total number of items to display in the list.
  ///
  /// Includes section headers, spacing, diary entries, words, and kanji results.
  int _calculateItemCount(_SearchResults results) {
    int count = 0;
    if (results.diaryEntries.isNotEmpty) {
      count += 2; // Header + spacing
      count += results.diaryEntries.length;
      count += 1; // Spacing after section
    }
    if (results.jmdictEntries.isNotEmpty) {
      count += 2; // Header + spacing
      count += results.jmdictEntries.length;
      count += 1; // Spacing after section
    }
    if (results.kanji.isNotEmpty) {
      count += 2; // Header + spacing
      count += results.kanji.length;
    }
    return count;
  }

  /// Builds individual items for the list based on their position.
  Widget _buildResultItem(
    BuildContext context,
    _SearchResults results,
    int index,
  ) {
    int currentIndex = 0;

    // Diary Entries Section
    if (results.diaryEntries.isNotEmpty) {
      if (index == currentIndex) {
        return SectionHeader(
          icon: Icons.book,
          title: 'Diary Entries (${results.diaryEntries.length})',
        );
      }
      currentIndex++;

      if (index == currentIndex) {
        return const SizedBox(height: 0); // Spacing placeholder
      }
      currentIndex++;

      // Diary entry cards
      if (index < currentIndex + results.diaryEntries.length) {
        final entryIndex = index - currentIndex;
        return _buildDiaryEntryCard(
          results.diaryEntries[entryIndex],
        );
      }
      currentIndex += results.diaryEntries.length;

      if (index == currentIndex) {
        return const SizedBox(height: 32); // Section spacing
      }
      currentIndex++;
    }

    // JMdict Entries Section
    if (results.jmdictEntries.isNotEmpty) {
      if (index == currentIndex) {
        return SectionHeader(
          icon: Icons.menu_book,
          title: 'Dictionary (${results.jmdictEntries.length})',
        );
      }
      currentIndex++;

      if (index == currentIndex) {
        return const SizedBox(height: 0); // Spacing placeholder
      }
      currentIndex++;

      // JMdict cards
      if (index < currentIndex + results.jmdictEntries.length) {
        final entryIndex = index - currentIndex;
        return _buildJmdictCard(
          results.jmdictEntries[entryIndex],
        );
      }
      currentIndex += results.jmdictEntries.length;

      if (index == currentIndex) {
        return const SizedBox(height: 32); // Section spacing
      }
      currentIndex++;
    }

    // Kanji Section
    if (results.kanji.isNotEmpty) {
      if (index == currentIndex) {
        return SectionHeader(
          icon: Icons.language,
          title: 'Kanji (${results.kanji.length})',
        );
      }
      currentIndex++;

      if (index == currentIndex) {
        return const SizedBox(height: 0); // Spacing placeholder
      }
      currentIndex++;

      // Kanji cards
      if (index < currentIndex + results.kanji.length) {
        final kanjiIndex = index - currentIndex;
        return _buildKanjiCard(results.kanji[kanjiIndex]);
      }
    }

    return const SizedBox.shrink();
  }

  /// Builds a diary entry card.
  Widget _buildDiaryEntryCard(DiaryEntry entry) {
    return DiaryEntryCard(
      key: ValueKey(entry.id),
      entry: entry,
      onDoubleTap: () => _openSearchForEntry(entry),
      onEntryUpdated: (_) => _performSearch(),
      onEntryDeleted: (_) => _performSearch(),
    );
  }

  /// Opens the search results page for the given entry's Japanese text.
  void _openSearchForEntry(DiaryEntry entry) {
    if (!mounted) return;

    final query = JapaneseTextUtils.stripRubyPatterns(entry.japanese);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(searchQuery: query),
      ),
    );
  }

  /// Builds a kanji card.
  Widget _buildKanjiCard(KanjiData kanji) {
    return KanjiCard(
      kanji: kanji,
      onDoubleTap: () => _openSearchForKanji(kanji),
    );
  }

  void _openSearchForKanji(KanjiData kanji) {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(searchQuery: kanji.kanji),
      ),
    );
  }

  /// Builds a JMdict card.
  Widget _buildJmdictCard(JMdictEntry entry) {
    return JMdictCard(
      entry: entry,
      onDoubleTap: () => _openSearchForJmdict(entry),
      // onSearchTextSet: widget.onSearchTextSet,
    );
  }

  void _openSearchForJmdict(JMdictEntry entry) {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(searchQuery: entry.primaryForm),
      ),
    );
  }

  /// Performs a comprehensive search across diary entries and kanji.
  ///
  /// Searches through:
  /// - Diary entries: Japanese text (with inline furigana stripped), romaji, meaning, and notes
  /// - Kanji database: character, meanings, and readings
  ///
  /// Returns a [_SearchResults] object containing all matching results.
  Future<_SearchResults> _search() async {
    final diaryRepository = DiaryRepository();
    final kanjiRepository = KanjiRepository();
    final jmdictRepository = JMdictRepository();

    // Search diary entries across all text fields.
    // Strip ruby patterns from Japanese text so searching for "何歳" finds "[何](なん)[歳](さい)"
    final allEntries = await diaryRepository.getAllEntries();
    final diaryResults = allEntries.where((entry) {
      final query = JapaneseTextUtils.normalizeForSearch(widget.searchQuery);
      final strippedJapanese = JapaneseTextUtils.normalizeForSearch(
        JapaneseTextUtils.stripRubyPatterns(entry.japanese),
      );
      
      return strippedJapanese.contains(query) ||
          JapaneseTextUtils.normalizeForSearch(entry.romaji).contains(query) ||
          JapaneseTextUtils.normalizeForSearch(entry.meaning).contains(query) ||
          (JapaneseTextUtils.normalizeForSearch(entry.notes ?? '').contains(query));
    }).toList();

    // Search kanji database using dedicated search method.
    final kanjiResults = await kanjiRepository.searchKanji(widget.searchQuery);

    // Search JMdict using tokenized search
    final tokens = JapaneseTextUtils.tokenize(
      widget.searchQuery,
    ).where((t) => t.trim().isNotEmpty).toSet().toList();
    final jmdictResults = <JMdictEntry>[];
    final seenEntSeqs = <int>{};
    for (final token in tokens) {
      final entries = await jmdictRepository.searchByToken(token, limit: 5);
      for (final entry in entries) {
        if (!seenEntSeqs.contains(entry.entSeq)) {
          seenEntSeqs.add(entry.entSeq);
          jmdictResults.add(entry);
        }
      }
    }

    return _SearchResults(
      diaryEntries: diaryResults,
      kanji: kanjiResults,
      jmdictEntries: jmdictResults,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: LearningModeAppBar(
        title: 'Search Results: ${widget.searchQuery}',
      ),
      body: _buildSearchResults(),
    );
  }

  /// Builds the search results list with loading and error states.
  Widget _buildSearchResults() {
    return FutureBuilder<_SearchResults>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final results = snapshot.data!;
        final hasResults =
            results.diaryEntries.isNotEmpty ||
            results.kanji.isNotEmpty ||
            results.jmdictEntries.isNotEmpty;

        if (!hasResults) {
          return _buildNoResultsState();
        }

        return _buildResultsList(results);
      },
    );
  }

  /// Builds the loading indicator shown while searching.
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Builds the error message display.
  Widget _buildErrorState(Object? error) {
    return Center(child: Text('Error: $error'));
  }

  /// Builds the no results message.
  Widget _buildNoResultsState() {
    return Center(
      child: Text(
        'No results found',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
      ),
    );
  }

  /// Builds the scrollable list of search results.
  Widget _buildResultsList(_SearchResults results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _calculateItemCount(results),
      itemBuilder: (context, index) =>
          _buildResultItem(context, results, index),
    );
  }
}

/// Container for search results including diary entries, kanji, and JMdict entries.
class _SearchResults {
  final List<DiaryEntry> diaryEntries;
  final List<KanjiData> kanji;
  final List<JMdictEntry> jmdictEntries;

  /// Creates a new instance of [_SearchResults].
  _SearchResults({
    required this.diaryEntries,
    required this.kanji,
    required this.jmdictEntries,
  });
}
