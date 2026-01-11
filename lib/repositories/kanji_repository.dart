import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/models/word_data.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/services/jpn_database_helper.dart';

/// Repository for kanji data operations.
///
/// Provides a clean abstraction over kanji data access and queries.
/// This layer separates business logic from data source implementation.
///
/// Uses two databases:
/// - JpnDatabaseHelper: Read-only database shipped with app (kanji, words, readings)
/// - DatabaseHelper: User database for diary entries and learned kanji tracking
class KanjiRepository {
  final DatabaseHelper _databaseHelper;
  final JpnDatabaseHelper _jpnDatabaseHelper;

  /// Creates a repository with the given database helpers.
  ///
  /// In production, typically uses singleton instances.
  /// For testing, can inject mock database helpers.
  KanjiRepository({
    DatabaseHelper? databaseHelper,
    JpnDatabaseHelper? jpnDatabaseHelper,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _jpnDatabaseHelper = jpnDatabaseHelper ?? JpnDatabaseHelper.instance;

  /// Searches for kanji by character, meaning, or reading.
  ///
  /// Supports:
  /// - Text search in meanings and readings
  /// - Direct kanji character lookup
  /// - Extracts kanji from mixed queries
  ///
  /// Returns up to 50 results from the jpn.db database.
  Future<List<KanjiData>> searchKanji(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    final results = await _jpnDatabaseHelper.searchKanji(query);
    return results.map((map) => KanjiData.fromJpnDb(map)).toList();
  }

  /// Gets a specific kanji by its character.
  ///
  /// Returns null if the kanji is not found in the database.
  Future<KanjiData?> getKanji(String kanji) async {
    if (kanji.isEmpty) {
      return null;
    }
    final result = await _jpnDatabaseHelper.getKanji(kanji);
    if (result == null) return null;
    return KanjiData.fromJpnDb(result);
  }

  /// Gets random kanji for practice from those found in diary entries.
  ///
  /// Only returns kanji that appear in the user's diary entries,
  /// making practice more relevant to their learning.
  ///
  /// Returns up to [count] random kanji, or fewer if not enough
  /// kanji are found in diary entries.
  Future<List<KanjiData>> getRandomKanjiFromDiary({int count = 10}) async {
    if (count <= 0) {
      return [];
    }
    return await _databaseHelper.getRandomKanjiFromDiary(count: count);
  }

  /// Gets JLPT level statistics for kanji found in diary entries.
  ///
  /// Returns a map with counts for each JLPT level:
  /// - Keys: 5, 4, 3, 2, 1 (N5 to N1)
  /// - null key for unclassified kanji
  Future<Map<int?, int>> getLearnedKanjiByJlptLevel() async {
    return await _databaseHelper.getLearnedKanjiByJlptLevel();
  }

  /// Gets the total count of kanji in the database.
  Future<int> getKanjiCount() async {
    return await _jpnDatabaseHelper.getKanjiCount();
  }

  /// Gets kanji by JLPT level.
  ///
  /// Note: This is a convenience method. For better performance on large
  /// datasets, consider adding a direct database query method to DatabaseHelper.
  Future<List<KanjiData>> getKanjiByJlptLevel(int level) async {
    if (level < 1 || level > 5) {
      throw ArgumentError('JLPT level must be between 1 (N1) and 5 (N5)');
    }
    
    // This is a placeholder for future implementation
    // For now, we'd need to add this method to DatabaseHelper
    // or implement it using search functionality
    throw UnimplementedError(
      'getKanjiByJlptLevel needs to be implemented in DatabaseHelper',
    );
  }

  /// Gets random kanji from a specific JLPT level.
  ///
  /// This is useful for targeted practice.
  Future<List<KanjiData>> getRandomKanjiByLevel({
    required int jlptLevel,
    int count = 10,
  }) async {
    if (jlptLevel < 1 || jlptLevel > 5) {
      throw ArgumentError('JLPT level must be between 1 (N1) and 5 (N5)');
    }
    if (count <= 0) {
      return [];
    }

    // This is a placeholder for future implementation
    // Would require DatabaseHelper method to query by JLPT level
    throw UnimplementedError(
      'getRandomKanjiByLevel needs to be implemented in DatabaseHelper',
    );
  }

  /// Gets the total count of unique kanji found in diary entries.
  Future<int> getLearnedKanjiCount() async {
    final stats = await getLearnedKanjiByJlptLevel();
    return stats.values.fold<int>(0, (sum, count) => sum + count);
  }

  /// Checks if a character is a kanji.
  bool isKanji(String char) {
    if (char.isEmpty) return false;
    final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
    return kanjiPattern.hasMatch(char);
  }

  /// Extracts all kanji characters from a text string.
  List<String> extractKanji(String text) {
    final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
    final matches = kanjiPattern.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }

  // ==================== Word Operations ====================

  /// Searches for words by kanji, reading, or meaning.
  ///
  /// Returns up to 50 results from the jpn.db database.
  Future<List<WordData>> searchWords(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    final results = await _jpnDatabaseHelper.searchWords(query);
    return results.map((map) => WordData.fromMap(map)).toList();
  }

  /// Gets words that contain a specific kanji character.
  ///
  /// Returns all word entries where the kanji key matches.
  Future<List<WordData>> getWordsForKanji(String kanji) async {
    if (kanji.isEmpty) {
      return [];
    }
    final results = await _jpnDatabaseHelper.getWordsForKanji(kanji);
    return results.map((map) => WordData.fromMap(map)).toList();
  }

  /// Gets the total count of words in the database.
  Future<int> getWordCount() async {
    return await _jpnDatabaseHelper.getWordCount();
  }
}
