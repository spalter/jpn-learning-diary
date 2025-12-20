import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';
import 'package:jpn_learning_diary/data/kanji_data.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';
import 'package:jpn_learning_diary/widgets/responsive_grid_view.dart';

/// Search results page that displays results based on search query.
///
/// Shows matching diary entries, kanji, and other relevant information
/// based on the search text provided.
class SearchResultsPage extends StatefulWidget {
  /// The search query text.
  final String searchQuery;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
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

  void _performSearch() {
    setState(() {
      _searchFuture = _search();
    });
  }

  /// Calculates the total number of items to display in the list.
  /// 
  /// Includes section headers, spacing, diary entries, and kanji results.
  int _calculateItemCount(_SearchResults results) {
    int count = 0;
    if (results.diaryEntries.isNotEmpty) {
      count += 2; // Header + spacing
      count += results.diaryEntries.length;
      count += 1; // Spacing after section
    }
    if (results.kanji.isNotEmpty) {
      count += 2; // Header + spacing
      count += results.kanji.length;
    }
    return count;
  }

  /// Builds individual items for the list based on their position.
  Widget _buildResultItem(BuildContext context, _SearchResults results, int index, bool useBorderedStyle) {
    int currentIndex = 0;

    // Diary Entries Section
    if (results.diaryEntries.isNotEmpty) {
      if (index == currentIndex) {
        return _buildSectionHeader(
          context,
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
        return _buildDiaryEntryCard(results.diaryEntries[entryIndex], useBorderedStyle);
      }
      currentIndex += results.diaryEntries.length;

      if (index == currentIndex) {
        return const SizedBox(height: 32); // Section spacing
      }
      currentIndex++;
    }

    // Kanji Section
    if (results.kanji.isNotEmpty) {
      if (index == currentIndex) {
        return _buildSectionHeader(
          context,
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

  /// Builds a section header with icon and title.
  Widget _buildSectionHeader(BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a diary entry card.
  Widget _buildDiaryEntryCard(DiaryEntry entry, bool useBorderedStyle) {
    return DiaryEntryCard(
      entry: entry,
      onUpdate: _performSearch,
      useBorderedStyle: useBorderedStyle,
    );
  }

  /// Builds a kanji card.
  Widget _buildKanjiCard(KanjiData kanji, bool useBorderedStyle) {
    return KanjiCard(kanji: kanji, useBorderedStyle: useBorderedStyle);
  }

  /// Performs a comprehensive search across diary entries and kanji.
  /// 
  /// Searches through:
  /// - Diary entries: Japanese text, furigana, romaji, meaning, and notes
  /// - Kanji database: character, meanings, and readings
  /// 
  /// Returns a [_SearchResults] object containing all matching results.
  Future<_SearchResults> _search() async {
    final db = DatabaseHelper.instance;
    
    // Search diary entries across all text fields.
    final allEntries = await db.getAllEntries();
    final diaryResults = allEntries.where((entry) {
      final query = widget.searchQuery.toLowerCase();
      return entry.japanese.toLowerCase().contains(query) ||
          (entry.furigana?.toLowerCase().contains(query) ?? false) ||
          entry.romaji.toLowerCase().contains(query) ||
          entry.meaning.toLowerCase().contains(query) ||
          (entry.notes?.toLowerCase().contains(query) ?? false);
    }).toList();
    
    // Search kanji database using dedicated search method.
    final kanjiResults = await db.searchKanji(widget.searchQuery);
    
    return _SearchResults(
      diaryEntries: diaryResults,
      kanji: kanjiResults,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      initialSearchText: widget.searchQuery,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildSearchResults()),
        ],
      ),
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
        final hasResults = results.diaryEntries.isNotEmpty || results.kanji.isNotEmpty;

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
      itemBuilder: (context, index) => _buildResultItem(context, results, index, false),
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
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: _buildSectionHeader(
                context,
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
        
        // Kanji Section
        if (results.kanji.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: _buildSectionHeader(
                context,
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
        final crossAxisCount = _calculateGridColumns(constraints.crossAxisExtent);
        
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
        final crossAxisCount = _calculateGridColumns(constraints.crossAxisExtent);
        
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

  /// Calculates the number of columns based on available width.
  /// 
  /// Uses the same calculation logic as ResponsiveGridView.
  int _calculateGridColumns(double availableWidth) {
    return ResponsiveGridView.calculateCrossAxisCount(
      availableWidth,
      340.0, // minCardWidth
      8.0,   // spacing
      const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// Container for search results including diary entries and kanji.
class _SearchResults {
  final List<DiaryEntry> diaryEntries;
  final List<KanjiData> kanji;

  /// Creates a new instance of [_SearchResults].
  _SearchResults({
    required this.diaryEntries,
    required this.kanji,
  });
}
