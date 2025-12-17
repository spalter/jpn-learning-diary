import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';
import 'package:jpn_learning_diary/data/kanji_data.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';

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
          Expanded(
            child: FutureBuilder<_SearchResults>(
              future: _searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                final results = snapshot.data!;
                final hasResults = results.diaryEntries.isNotEmpty || results.kanji.isNotEmpty;
                
                if (!hasResults) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }
                
                return ListView(
                  children: [
                    // Diary Entries Section
                    if (results.diaryEntries.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.book,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Diary Entries (${results.diaryEntries.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...results.diaryEntries.map((entry) => DiaryEntryCard(
                            entry: entry,
                            onUpdate: _performSearch,
                          )),
                      const SizedBox(height: 32),
                    ],
                    
                    // Kanji Section
                    if (results.kanji.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kanji (${results.kanji.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...results.kanji.map((kanji) => KanjiCard(kanji: kanji)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults {
  final List<DiaryEntry> diaryEntries;
  final List<KanjiData> kanji;

  _SearchResults({
    required this.diaryEntries,
    required this.kanji,
  });
}
