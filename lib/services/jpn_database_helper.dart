// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database helper for accessing the read-only Japanese dictionary data.
///
/// This singleton manages the connection to the pre-populated 'jpn.db' database
/// which contains the core dictionary, kanji information, and example sentences.
/// It handles the initial asset-to-filesystem copy process required on mobile
/// platforms and ensures efficient read access to the static learning content.
class JpnDatabaseHelper {
  /// Singleton instance of the database helper.
  static final JpnDatabaseHelper instance = JpnDatabaseHelper._init();

  /// The SQLite database instance.
  static Database? _database;

  /// Database filename in assets.
  static const String _dbName = 'jpn.db';

  /// Database version for tracking updates.
  /// Increment this when shipping a new database with an app update.
  static const int _dbVersion = 1;

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

  /// Initializes the database.
  ///
  /// On desktop platforms, opens directly from the assets folder.
  /// On mobile platforms, copies from assets to documents directory first.
  Future<Database> _initDB() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _initMobileDB();
    } else {
      return await _initDesktopDB();
    }
  }

  /// Initializes the database for desktop platforms.
  ///
  /// Opens directly from the `data/flutter_assets/` folder next to the executable.
  Future<Database> _initDesktopDB() async {
    final dbPath = _getDesktopAssetPath();
    return await openDatabase(dbPath, readOnly: true);
  }

  /// Initializes the database for mobile platforms.
  ///
  /// Copies the database from assets to the documents directory on first launch
  /// or when the database version changes.
  Future<Database> _initMobileDB() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, _dbName);
    final versionFile = File(join(documentsDir.path, '.jpn_db_version'));

    // Check if we need to copy the database
    bool needsCopy = !await File(dbPath).exists();

    // Check version to handle app updates with new database
    if (!needsCopy && await versionFile.exists()) {
      final storedVersion = int.tryParse(await versionFile.readAsString()) ?? 0;
      if (storedVersion < _dbVersion) {
        needsCopy = true;
      }
    } else if (!needsCopy) {
      // No version file exists, assume we need to update
      needsCopy = true;
    }

    if (needsCopy) {
      // Copy database from assets
      final data = await rootBundle.load('lib/assets/$_dbName');
      final bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes, flush: true);

      // Write version file
      await versionFile.writeAsString(_dbVersion.toString());
    }

    return await openDatabase(dbPath, readOnly: true);
  }

  /// Gets the path to the database file in the assets folder (desktop only).
  ///
  /// On desktop, asset location varies by platform:
  /// - macOS: `../Frameworks/App.framework/Resources/flutter_assets/lib/assets/`
  /// - Windows/Linux: `data/flutter_assets/lib/assets/`
  String _getDesktopAssetPath() {
    final exePath = Platform.resolvedExecutable;
    final exeDir = dirname(exePath);
    
    if (Platform.isMacOS) {
      // macOS bundles assets in App.framework
      return join(exeDir, '..', 'Frameworks', 'App.framework', 'Resources', 
                  'flutter_assets', 'lib', 'assets', _dbName);
    } else {
      // Windows and Linux use data/flutter_assets
      return join(exeDir, 'data', 'flutter_assets', 'lib', 'assets', _dbName);
    }
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
