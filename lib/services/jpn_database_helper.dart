// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database helper for the read-only Japanese language database.
///
/// This database contains kanji, readings, words, and JMdict data that is
/// shipped with the app as an asset. On desktop platforms, it is opened
/// directly from the assets folder without copying.
///
/// Uses a singleton pattern to ensure only one database connection exists.
class JpnDatabaseHelper {
  /// Singleton instance of the database helper.
  static final JpnDatabaseHelper instance = JpnDatabaseHelper._init();

  /// The SQLite database instance.
  static Database? _database;

  /// Database filename in assets.
  static const String _dbName = 'jpn.db';

  /// Private constructor to enforce singleton pattern.
  JpnDatabaseHelper._init() {
    // Initialize FFI for desktop platforms (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Gets the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initializes the database by opening directly from assets.
  ///
  /// On desktop platforms, assets are stored as files in the
  /// `data/flutter_assets/` folder next to the executable.
  Future<Database> _initDB() async {
    final dbPath = _getAssetPath();

    // Open in read-only mode directly from assets
    return await openDatabase(dbPath, readOnly: true);
  }

  /// Gets the path to the database file in the assets folder.
  ///
  /// On desktop, assets are in `data/flutter_assets/lib/assets/` relative
  /// to the executable directory.
  String _getAssetPath() {
    // Get the directory containing the executable
    final exePath = Platform.resolvedExecutable;
    final exeDir = dirname(exePath);

    // Assets are in data/flutter_assets/ relative to executable
    return join(exeDir, 'data', 'flutter_assets', 'lib', 'assets', _dbName);
  }

  /// Searches for kanji by character, meaning, or reading.
  ///
  /// Returns kanji data from the kanjis table.
  Future<List<Map<String, dynamic>>> searchKanji(String query) async {
    final db = await database;

    final results = <String, Map<String, dynamic>>{};

    // Search by meaning (stored as JSON array)
    final meaningResults = await db.query(
      'kanjis',
      where: 'meanings LIKE ?',
      whereArgs: ['%$query%'],
      limit: 50,
    );
    for (var row in meaningResults) {
      final key = row['_key'] as String;
      results[key] = row;
    }

    // Search by on/kun readings (stored as JSON arrays)
    final readingResults = await db.query(
      'kanjis',
      where: 'on_readings LIKE ? OR kun_readings LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 50,
    );
    for (var row in readingResults) {
      final key = row['_key'] as String;
      results[key] = row;
    }

    // Extract individual kanji characters from the query
    final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
    final matches = kanjiPattern.allMatches(query);

    for (var match in matches) {
      final kanjiChar = match.group(0)!;
      final charResults = await db.query(
        'kanjis',
        where: '_key = ?',
        whereArgs: [kanjiChar],
      );
      for (var row in charResults) {
        final key = row['_key'] as String;
        results[key] = row;
      }
    }

    return results.values.take(50).toList();
  }

  /// Gets a specific kanji by its character.
  Future<Map<String, dynamic>?> getKanji(String kanji) async {
    final db = await database;
    final result = await db.query(
      'kanjis',
      where: '_key = ?',
      whereArgs: [kanji],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Searches for words by kanji, reading, or meaning.
  ///
  /// Returns flat word data rows with word_id, glosses, written, pronounced, priorities.
  /// The repository layer will group these into WordData objects.
  Future<List<Map<String, dynamic>>> searchWords(String query) async {
    final db = await database;

    // Search by exact written form, or partial pronounced/glosses match
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT
        wm.word_id,
        wm.glosses,
        wv.written,
        wv.pronounced,
        wv.priorities
      FROM word_meanings wm
      INNER JOIN word_variants wv ON wm.word_id = wv.word_id
      WHERE wv.written = ?
         OR wv.pronounced LIKE ?
         OR wm.glosses LIKE ?
      LIMIT 500
    ''',
      [query, '%$query%', '%$query%'],
    );

    return results;
  }

  // ===========================================================================
  // JMdict methods
  // ===========================================================================

  /// Searches JMdict entries by kanji, reading, or English gloss.
  ///
  /// Returns entry IDs matching the query. Use [getJMdictEntry] to fetch full details.
  Future<List<int>> searchJMdict(String query, {int limit = 100}) async {
    final db = await database;

    final results = await db.rawQuery(
      '''
      SELECT DISTINCT e.id
      FROM jmdict_entries e
      LEFT JOIN jmdict_kanji k ON k.entry_id = e.id
      LEFT JOIN jmdict_readings r ON r.entry_id = e.id
      LEFT JOIN jmdict_senses s ON s.entry_id = e.id
      LEFT JOIN jmdict_glosses g ON g.sense_id = s.id
      WHERE k.keb = ?
         OR k.keb LIKE ?
         OR r.reb = ?
         OR r.reb LIKE ?
         OR g.gloss LIKE ?
      LIMIT ?
    ''',
      [query, '$query%', query, '$query%', '%$query%', limit],
    );

    return results.map((row) => row['id'] as int).toList();
  }

  /// Searches JMdict for exact kanji match.
  Future<List<int>> searchJMdictByKanji(String kanji, {int limit = 100}) async {
    final db = await database;

    final results = await db.rawQuery(
      '''
      SELECT DISTINCT e.id
      FROM jmdict_entries e
      JOIN jmdict_kanji k ON k.entry_id = e.id
      WHERE k.keb = ?
      LIMIT ?
    ''',
      [kanji, limit],
    );

    return results.map((row) => row['id'] as int).toList();
  }

  /// Searches JMdict for exact reading match.
  Future<List<int>> searchJMdictByReading(
    String reading, {
    int limit = 100,
  }) async {
    final db = await database;

    final results = await db.rawQuery(
      '''
      SELECT DISTINCT e.id
      FROM jmdict_entries e
      JOIN jmdict_readings r ON r.entry_id = e.id
      WHERE r.reb = ?
      LIMIT ?
    ''',
      [reading, limit],
    );

    return results.map((row) => row['id'] as int).toList();
  }

  /// Searches JMdict glosses (English meanings).
  Future<List<int>> searchJMdictByGloss(String gloss, {int limit = 100}) async {
    final db = await database;

    final results = await db.rawQuery(
      '''
      SELECT DISTINCT e.id
      FROM jmdict_entries e
      JOIN jmdict_senses s ON s.entry_id = e.id
      JOIN jmdict_glosses g ON g.sense_id = s.id
      WHERE g.gloss LIKE ?
      LIMIT ?
    ''',
      ['%$gloss%', limit],
    );

    return results.map((row) => row['id'] as int).toList();
  }

  /// Gets a full JMdict entry by internal ID.
  ///
  /// Returns all related data: kanji, readings, senses, glosses, etc.
  Future<Map<String, dynamic>?> getJMdictEntry(int id) async {
    final db = await database;

    // Get entry
    final entries = await db.query(
      'jmdict_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (entries.isEmpty) return null;

    final entry = entries.first;
    final entryId = entry['id'] as int;

    // Get kanji
    final kanji = await db.query(
      'jmdict_kanji',
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );

    // Get readings
    final readings = await db.query(
      'jmdict_readings',
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );

    // Get senses with related data
    final senses = await db.query(
      'jmdict_senses',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'sense_num',
    );

    final sensesWithData = <Map<String, dynamic>>[];
    for (final sense in senses) {
      final senseId = sense['id'] as int;

      final glosses = await db.query(
        'jmdict_glosses',
        where: 'sense_id = ?',
        whereArgs: [senseId],
      );

      final lsources = await db.query(
        'jmdict_lsources',
        where: 'sense_id = ?',
        whereArgs: [senseId],
      );

      final xrefs = await db.query(
        'jmdict_xrefs',
        where: 'sense_id = ?',
        whereArgs: [senseId],
      );

      final ants = await db.query(
        'jmdict_ants',
        where: 'sense_id = ?',
        whereArgs: [senseId],
      );

      sensesWithData.add({
        ...sense,
        'glosses': glosses,
        'lsources': lsources,
        'xrefs': xrefs.map((r) => r['xref']).toList(),
        'ants': ants.map((r) => r['ant']).toList(),
      });
    }

    return {
      'entry': entry,
      'kanji': kanji,
      'readings': readings,
      'senses': sensesWithData,
    };
  }

  /// Gets random common JMdict entry IDs.
  ///
  /// Returns IDs of entries that have priority markers (indicating common words).
  /// Priority markers include: news1, news2, ichi1, ichi2, spec1, spec2, gai1, gai2, nfXX.
  Future<List<int>> getRandomCommonJMdictEntries({int count = 40}) async {
    final db = await database;

    // Get entries that have at least one kanji or reading with priority markers
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT e.id
      FROM jmdict_entries e
      LEFT JOIN jmdict_kanji k ON k.entry_id = e.id
      LEFT JOIN jmdict_readings r ON r.entry_id = e.id
      WHERE (k.ke_pri IS NOT NULL AND k.ke_pri != '[]')
         OR (r.re_pri IS NOT NULL AND r.re_pri != '[]')
      ORDER BY RANDOM()
      LIMIT ?
    ''',
      [count],
    );

    return results.map((row) => row['id'] as int).toList();
  }

  /// Gets a JMdict entry by its ent_seq number.
  Future<Map<String, dynamic>?> getJMdictEntryBySeq(int entSeq) async {
    final db = await database;

    final entries = await db.query(
      'jmdict_entries',
      where: 'ent_seq = ?',
      whereArgs: [entSeq],
    );
    if (entries.isEmpty) return null;

    return getJMdictEntry(entries.first['id'] as int);
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
