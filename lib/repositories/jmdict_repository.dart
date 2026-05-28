// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/services/jpn_database_helper.dart';

/// Repository for JMdict dictionary data operations.
///
/// Provides access to the JMdict (Japanese-Multilingual Dictionary) data,
/// which contains comprehensive Japanese word entries with kanji forms,
/// readings, meanings, and linguistic information.
class JMdictRepository {
  final JpnDatabaseHelper _jpnDatabaseHelper;

  /// Creates a repository with the given database helper.
  ///
  /// In production, typically uses the singleton instance.
  /// For testing, can inject a mock database helper.
  JMdictRepository({JpnDatabaseHelper? jpnDatabaseHelper})
    : _jpnDatabaseHelper = jpnDatabaseHelper ?? JpnDatabaseHelper.instance;

  /// Searches JMdict entries by kanji, reading, or English meaning.
  ///
  /// This is a general search that looks across:
  /// - Kanji forms (exact and prefix match)
  /// - Reading forms (exact and prefix match)
  /// - English glosses (partial match)
  ///
  /// Returns up to [limit] results (default: 100).
  Future<List<JMdictEntry>> search(String query, {int limit = 100}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final ids = await _jpnDatabaseHelper.searchJMdict(query, limit: limit);
    return _fetchEntries(ids);
  }

  /// Searches JMdict for entries with an exact kanji match.
  ///
  /// Use this when you have a specific kanji word to look up.
  Future<List<JMdictEntry>> searchByKanji(
    String kanji, {
    int limit = 100,
  }) async {
    if (kanji.trim().isEmpty) {
      return [];
    }

    final ids = await _jpnDatabaseHelper.searchJMdictByKanji(
      kanji,
      limit: limit,
    );
    return _fetchEntries(ids);
  }

  /// Searches JMdict for entries with an exact reading match.
  ///
  /// Use this when you have a kana reading to look up.
  Future<List<JMdictEntry>> searchByReading(
    String reading, {
    int limit = 100,
  }) async {
    if (reading.trim().isEmpty) {
      return [];
    }

    final ids = await _jpnDatabaseHelper.searchJMdictByReading(
      reading,
      limit: limit,
    );
    return _fetchEntries(ids);
  }

  /// Searches JMdict for entries by English meaning.
  ///
  /// Performs a partial match on gloss text.
  Future<List<JMdictEntry>> searchByGloss(
    String gloss, {
    int limit = 100,
  }) async {
    if (gloss.trim().isEmpty) {
      return [];
    }

    final ids = await _jpnDatabaseHelper.searchJMdictByGloss(
      gloss,
      limit: limit,
    );
    return _fetchEntries(ids);
  }

  /// Searches JMdict entries for a token with smart filtering.
  ///
  /// For single-character tokens:
  /// - Particles: returns only particle entries from reading search
  /// - Non-particles: skips reading search (kanji only)
  /// For multi-character tokens: searches both kanji and reading.
  ///
  /// Results are deduplicated by entSeq.
  Future<List<JMdictEntry>> searchByToken(String token, {int limit = 5}) async {
    if (token.trim().isEmpty) {
      return [];
    }

    final entries = <JMdictEntry>[];
    final seenEntSeqs = <int>{};

    // Search by exact kanji match
    final entriesByKanji = await searchByKanji(token, limit: limit);

    // For single-character tokens, only search by reading if it's a particle
    // and only keep particle results. This avoids noise from verb endings etc.
    List<JMdictEntry> entriesByReading = [];
    if (token.length == 1) {
      if (JapaneseTextUtils.isParticle(token)) {
        final readingResults = await searchByReading(token, limit: limit);
        entriesByReading = readingResults.where((entry) {
          return entry.senses.any(
            (sense) => sense.partsOfSpeech.any(
              (pos) => pos.toLowerCase().contains('&prt'),
            ),
          );
        }).toList();
      }
      // Skip reading search for non-particle single chars
    } else {
      // Multi-character tokens: search normally
      entriesByReading = await searchByReading(token, limit: limit);
    }

    // Combine results, avoiding duplicates
    for (final entry in [...entriesByKanji, ...entriesByReading]) {
      if (!seenEntSeqs.contains(entry.entSeq)) {
        seenEntSeqs.add(entry.entSeq);
        entries.add(entry);
      }
    }

    return entries;
  }

  /// Gets random common JMdict entries.
  ///
  /// Returns entries that have priority markers (news1, ichi1, etc.)
  /// indicating they are commonly used words.
  Future<List<JMdictEntry>> getRandomCommonEntries({int count = 40}) async {
    final ids = await _jpnDatabaseHelper.getRandomCommonJMdictEntries(
      count: count,
    );
    return _fetchEntries(ids);
  }

  /// Gets a specific JMdict entry by its ent_seq number.
  ///
  /// The ent_seq is the unique identifier from the JMdict XML file.
  /// Returns null if no entry is found.
  Future<JMdictEntry?> getByEntSeq(int entSeq) async {
    final data = await _jpnDatabaseHelper.getJMdictEntryBySeq(entSeq);
    if (data == null) return null;
    return _mapToEntry(data);
  }

  /// Fetches full entries for a list of internal IDs.
  Future<List<JMdictEntry>> _fetchEntries(List<int> ids) async {
    final entries = <JMdictEntry>[];
    for (final id in ids) {
      final data = await _jpnDatabaseHelper.getJMdictEntry(id);
      if (data != null) {
        entries.add(_mapToEntry(data));
      }
    }
    return entries;
  }

  /// Maps raw database data to a JMdictEntry model.
  JMdictEntry _mapToEntry(Map<String, dynamic> data) {
    final entry = data['entry'] as Map<String, dynamic>;
    final kanjiList = data['kanji'] as List<Map<String, dynamic>>;
    final readingsList = data['readings'] as List<Map<String, dynamic>>;
    final sensesList = data['senses'] as List<Map<String, dynamic>>;

    return JMdictEntry(
      entSeq: entry['ent_seq'] as int,
      kanji: kanjiList.map((k) => JMdictKanji.fromDb(k)).toList(),
      readings: readingsList.map((r) => JMdictReading.fromDb(r)).toList(),
      senses: sensesList.map((s) {
        final glossesList = s['glosses'] as List<Map<String, dynamic>>;
        final lsourcesList = s['lsources'] as List<Map<String, dynamic>>;
        final xrefsList = s['xrefs'] as List<dynamic>;
        final antsList = s['ants'] as List<dynamic>;

        return JMdictSense.fromDb(s).copyWith(
          glosses: glossesList.map((g) => JMdictGloss.fromDb(g)).toList(),
          lsources: lsourcesList.map((l) => JMdictLSource.fromDb(l)).toList(),
          xrefs: xrefsList.cast<String>(),
          antonyms: antsList.cast<String>(),
        );
      }).toList(),
    );
  }
}
