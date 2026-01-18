// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/models/word_data.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/services/jpn_database_helper.dart';

/// Repository for kanji data operations.
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
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
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

  /// Searches for words by kanji, reading, or meaning.
  ///
  /// Returns up to 50 results from the jpn.db database.
  /// Results are grouped by word_id + written + meanings, with pronunciations collected.
  Future<List<WordData>> searchWords(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    final results = await _jpnDatabaseHelper.searchWords(query);
    return WordData.fromRows(results);
  }
}
