import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';

/// Data class holding search results.
class SearchResults {
  final List<DiaryEntry> diaryEntries;
  final List<KanjiData> kanji;

  const SearchResults({
    required this.diaryEntries,
    required this.kanji,
  });

  bool get isEmpty => diaryEntries.isEmpty && kanji.isEmpty;
  bool get hasResults => !isEmpty;
  int get totalResults => diaryEntries.length + kanji.length;
}

/// Controller for search functionality.
///
/// Manages business logic for:
/// - Searching across diary entries and kanji
/// - Managing search state
/// - Debouncing search queries (if needed)
///
/// Keeps the SearchResultsPage widget focused purely on presentation.
class SearchController extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final KanjiRepository _kanjiRepository;

  String _query = '';
  SearchResults? _results;
  bool _isSearching = false;
  String? _errorMessage;

  SearchController({
    DiaryRepository? diaryRepository,
    KanjiRepository? kanjiRepository,
  })  : _diaryRepository = diaryRepository ?? DiaryRepository(),
        _kanjiRepository = kanjiRepository ?? KanjiRepository();

  /// Current search query.
  String get query => _query;

  /// Current search results, null if no search performed yet.
  SearchResults? get results => _results;

  /// Whether a search is currently in progress.
  bool get isSearching => _isSearching;

  /// Error message if search failed, null otherwise.
  String? get errorMessage => _errorMessage;

  /// Whether results are available.
  bool get hasResults => _results != null && _results!.hasResults;

  /// Whether the results are empty (after a search).
  bool get isEmpty => _results != null && _results!.isEmpty;

  /// Performs a comprehensive search across diary entries and kanji.
  ///
  /// Searches through:
  /// - Diary entries: Japanese text, furigana, romaji, meaning, and notes
  /// - Kanji database: character, meanings, and readings
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _query = '';
      _results = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _query = query;
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Search diary entries across all text fields
      final allEntries = await _diaryRepository.getAllEntries();
      final lowerQuery = query.toLowerCase();
      
      final diaryResults = allEntries.where((entry) {
        return entry.japanese.toLowerCase().contains(lowerQuery) ||
            (entry.furigana?.toLowerCase().contains(lowerQuery) ?? false) ||
            entry.romaji.toLowerCase().contains(lowerQuery) ||
            entry.meaning.toLowerCase().contains(lowerQuery) ||
            (entry.notes?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();

      // Search kanji database using dedicated search method
      final kanjiResults = await _kanjiRepository.searchKanji(query);

      _results = SearchResults(
        diaryEntries: diaryResults,
        kanji: kanjiResults,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      _results = null;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clears the current search results and query.
  void clear() {
    _query = '';
    _results = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Gets the count of diary entry results.
  int get diaryEntryCount => _results?.diaryEntries.length ?? 0;

  /// Gets the count of kanji results.
  int get kanjiCount => _results?.kanji.length ?? 0;

  /// Gets the total count of all results.
  int get totalResultCount => _results?.totalResults ?? 0;
}
