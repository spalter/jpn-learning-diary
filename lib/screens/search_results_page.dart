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
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/jmdict_card.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';
import 'package:jpn_learning_diary/widgets/responsive_grid_view.dart';
import 'package:jpn_learning_diary/widgets/section_header.dart';

/// Search results page for displaying matches across all data sources.
///
/// This widget aggregates and displays search results from multiple repositories
/// based on the user's query. It segments results into different categories to
/// providing comprehensive coverage. The results include:
///
/// - Diary Entries: Matches from the user's personal collection
/// - Kanji: Matches from the kanji database
/// - Dictionary: Matches from the JMdict dictionary (via [JMdictRepository])
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
    bool useBorderedStyle,
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
          useBorderedStyle,
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
          useBorderedStyle,
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
        return _buildKanjiCard(results.kanji[kanjiIndex], useBorderedStyle);
      }
    }

    return const SizedBox.shrink();
  }

  /// Builds a diary entry card.
  Widget _buildDiaryEntryCard(DiaryEntry entry, bool useBorderedStyle) {
    return DiaryEntryCard(
      key: ValueKey(entry.id),
      entry: entry,
      onEntryUpdated: (_) => _performSearch(),
      onEntryDeleted: (_) => _performSearch(),
      onTap: widget.onSearchTextSet != null
          ? () => widget.onSearchTextSet!(entry.japanese)
          : null,
      useBorderedStyle: useBorderedStyle,
    );
  }

  /// Builds a kanji card.
  Widget _buildKanjiCard(KanjiData kanji, bool useBorderedStyle) {
    return KanjiCard(
      kanji: kanji,
      useBorderedStyle: useBorderedStyle,
      navigationBarKey: widget.navigationBarKey,
    );
  }

  /// Builds a JMdict card.
  Widget _buildJmdictCard(JMdictEntry entry, bool useBorderedStyle) {
    return JMdictCard(
      entry: entry,
      useBorderedStyle: useBorderedStyle,
      onSearchTextSet: widget.onSearchTextSet,
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
      final query = widget.searchQuery.toLowerCase();
      final strippedJapanese = JapaneseTextUtils.stripRubyPatterns(
        entry.japanese,
      ).toLowerCase();
      return strippedJapanese.contains(query) ||
          entry.romaji.toLowerCase().contains(query) ||
          entry.meaning.toLowerCase().contains(query) ||
          (entry.notes?.toLowerCase().contains(query) ?? false);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: _buildSearchResults())],
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

        return FutureBuilder<String>(
          future: AppPreferences.getViewMode(),
          builder: (context, viewModeSnapshot) {
            final viewMode = viewModeSnapshot.data ?? 'list';
            return viewMode == 'grid'
                ? _buildGridResults(results)
                : _buildResultsList(results);
          },
        );
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
      itemCount: _calculateItemCount(results),
      itemBuilder: (context, index) =>
          _buildResultItem(context, results, index, false),
    );
  }

  /// Builds a responsive grid view of search results.
  Widget _buildGridResults(_SearchResults results) {
    return CustomScrollView(
      slivers: [
        // Diary Entries Section
        if (results.diaryEntries.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: SectionHeader(
                icon: Icons.book,
                title: 'Diary Entries (${results.diaryEntries.length})',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: _buildDiaryEntriesGrid(results.diaryEntries),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32), // Section spacing
          ),
        ],

        // JMdict Entries Section
        if (results.jmdictEntries.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: SectionHeader(
                icon: Icons.menu_book,
                title: 'Dictionary (${results.jmdictEntries.length})',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: _buildJmdictGrid(results.jmdictEntries),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32), // Section spacing
          ),
        ],

        // Kanji Section
        if (results.kanji.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: SectionHeader(
                icon: Icons.language,
                title: 'Kanji (${results.kanji.length})',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: _buildKanjiGrid(results.kanji),
          ),
        ],
      ],
    );
  }

  /// Builds a grid of diary entry cards using responsive layout.
  Widget _buildDiaryEntriesGrid(List<DiaryEntry> entries) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateGridColumns(
          constraints.crossAxisExtent,
        );

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 4 / 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildDiaryEntryCard(entries[index], true),
            childCount: entries.length,
          ),
        );
      },
    );
  }

  /// Builds a grid of kanji cards using responsive layout.
  Widget _buildKanjiGrid(List<KanjiData> kanjiList) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateGridColumns(
          constraints.crossAxisExtent,
        );

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 4 / 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildKanjiCard(kanjiList[index], true),
            childCount: kanjiList.length,
          ),
        );
      },
    );
  }

  /// Builds a grid of JMdict cards using responsive layout.
  Widget _buildJmdictGrid(List<JMdictEntry> entries) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateGridColumns(
          constraints.crossAxisExtent,
        );

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3 / 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildJmdictCard(entries[index], true),
            childCount: entries.length,
          ),
        );
      },
    );
  }

  /// Calculates the number of columns based on available width.
  ///
  /// Uses the same calculation logic as ResponsiveGridView.
  int _calculateGridColumns(double availableWidth) {
    return ResponsiveGridView.calculateCrossAxisCount(
      availableWidth,
      340.0, // minCardWidth
      8.0, // spacing
      const EdgeInsets.symmetric(horizontal: 8),
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
