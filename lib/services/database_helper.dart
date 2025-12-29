import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/file_access_service.dart';

/// Database helper for managing diary entries in SQLite.
///
/// Provides CRUD operations for diary entries with a singleton pattern.
/// Designed to be easily replaceable with an API service later.
///
/// Uses a singleton pattern to ensure only one database connection exists
/// throughout the application lifecycle.
class DatabaseHelper {
  /// Singleton instance of the database helper.
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// The SQLite database instance.
  static Database? _database;

  /// Private constructor to enforce singleton pattern.
  DatabaseHelper._init() {
    // Initialize FFI for desktop platforms (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Gets the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary.db');
    return _database!;
  }

  /// Initializes the database file and creates tables.
  ///
  /// Determines the database path based on user preferences and platform:
  /// - If custom path exists: Uses it (with security-scoped bookmark on macOS)
  /// - Otherwise: Uses default application documents directory
  ///
  /// **macOS Security-Scoped Bookmarks:**
  /// On macOS, attempts to resolve a saved bookmark first to regain access
  /// to custom database files outside the sandbox. Falls back to stored path
  /// if bookmark resolution fails (which may result in SQLITE error 14: CANTOPEN).
  ///
  /// **Parameters:**
  /// - [filePath]: Default database filename (e.g., 'diary.db')
  ///
  /// **Returns:** Initialized SQLite database instance
  ///
  /// **Throws:** May throw database exceptions if file cannot be opened
  Future<Database> _initDB(String filePath) async {
    // Retrieve custom database path from user preferences (if set)
    final customPath = await AppPreferences.getCustomDatabasePath();

    final String path;
    if (customPath != null && customPath.isNotEmpty) {
      // Custom path exists - handle platform-specific access requirements
      if (Platform.isMacOS) {
        // On macOS, try to resolve security-scoped bookmark for persistent access
        final resolvedPath = await FileAccessService.resolveBookmark();
        if (resolvedPath != null) {
          // Bookmark successfully resolved - use the resolved path
          path = resolvedPath;
        } else {
          // No bookmark or resolution failed - use stored path directly
          // Note: This may fail with SQLITE error 14 (CANTOPEN) due to sandbox restrictions
          path = customPath.endsWith('.db') ? customPath : join(customPath, filePath);
        }
      } else {
        // Other platforms don't need security-scoped bookmarks
        path = customPath.endsWith('.db') ? customPath : join(customPath, filePath);
      }
    } else {
      // No custom path set - use default application database directory
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Creates the database tables.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        japanese TEXT NOT NULL,
        furigana TEXT,
        romaji TEXT NOT NULL,
        meaning TEXT NOT NULL,
        notes TEXT,
        date_added INTEGER NOT NULL
      )
    ''');

    // Insert dummy data for initial setup
    await _insertDummyData(db);

    // Create kanji table
    await _createKanjiTable(db);
  }

  /// Upgrades the database schema when version changes.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add kanji table if upgrading from version 1
      await _createKanjiTable(db);
    }
  }

  /// Creates the kanji table and loads data from JSON.
  Future<void> _createKanjiTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kanji (
        kanji TEXT PRIMARY KEY,
        strokes INTEGER NOT NULL,
        grade INTEGER,
        freq INTEGER,
        jlpt_old INTEGER,
        jlpt_new INTEGER,
        meanings TEXT NOT NULL,
        readings_on TEXT NOT NULL,
        readings_kun TEXT NOT NULL,
        wk_level INTEGER,
        wk_meanings TEXT,
        wk_readings_on TEXT,
        wk_readings_kun TEXT,
        wk_radicals TEXT
      )
    ''');

    // Load kanji data from JSON
    await _loadKanjiData(db);
  }

  /// Inserts initial dummy data into the database.
  ///
  /// This provides example entries for new users to demonstrate
  /// the application's features. Includes common Japanese phrases,
  /// vocabulary, and usage examples with timestamps spread across
  /// the last week.
  Future<void> _insertDummyData(Database db) async {
    final dummyEntries = [
      {
        'japanese': 'こんにちは',
        'furigana': 'こんにちは',
        'romaji': 'konnichiwa',
        'meaning': 'Hello (daytime greeting)',
        'notes': 'Formal greeting used during the day',
        'date_added': DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      },
      {
        'japanese': '食べる',
        'furigana': 'たべる',
        'romaji': 'taberu',
        'meaning': 'to eat',
        'notes': 'Ichidan verb (ru-verb)',
        'date_added': DateTime.now()
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
      },
      {
        'japanese': '図書館',
        'furigana': 'としょかん',
        'romaji': 'toshokan',
        'meaning': 'library',
        'notes': 'Compound word: 図書 (books) + 館 (building)',
        'date_added': DateTime.now()
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
      },
      {
        'japanese': 'ありがとう',
        'furigana': 'ありがとう',
        'romaji': 'arigatou',
        'meaning': 'Thank you',
        'notes': 'Casual way to say thank you',
        'date_added': DateTime.now()
            .subtract(const Duration(days: 4))
            .millisecondsSinceEpoch,
      },
      {
        'japanese': '勉強する',
        'furigana': 'べんきょうする',
        'romaji': 'benkyou suru',
        'meaning': 'to study',
        'notes': 'Suru verb - attach する to the noun 勉強',
        'date_added': DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
      },
      {
        'japanese': '美味しい',
        'furigana': 'おいしい',
        'romaji': 'oishii',
        'meaning': 'delicious',
        'notes': 'I-adjective describing food taste',
        'date_added': DateTime.now()
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
      },
      {
        'japanese': 'お願いします',
        'furigana': 'おねがいします',
        'romaji': 'onegai shimasu',
        'meaning': 'please',
        'notes': 'Polite request form',
        'date_added': DateTime.now()
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
      },
      {
        'japanese': '明日',
        'furigana': 'あした',
        'romaji': 'ashita',
        'meaning': 'tomorrow',
        'notes': 'Time expression',
        'date_added': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (var entry in dummyEntries) {
      await db.insert('diary_entries', entry);
    }
  }

  /// Creates a new diary entry in the database.
  ///
  /// Returns a copy of the entry with the auto-generated ID populated.
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    final db = await database;
    final id = await db.insert('diary_entries', {
      'japanese': entry.japanese,
      'furigana': entry.furigana,
      'romaji': entry.romaji,
      'meaning': entry.meaning,
      'notes': entry.notes,
      'date_added': entry.dateAdded.millisecondsSinceEpoch,
    });
    return entry.copyWith(id: id);
  }

  /// Retrieves all diary entries from the database.
  ///
  /// Returns entries ordered by date added (newest first) to show
  /// recent learning progress at the top of lists.
  Future<List<DiaryEntry>> getAllEntries() async {
    final db = await database;
    final result = await db.query('diary_entries', orderBy: 'date_added DESC');
    return result.map((json) => DiaryEntry.fromMap(json)).toList();
  }

  /// Updates an existing diary entry.
  Future<int> updateEntry(DiaryEntry entry) async {
    final db = await database;
    return db.update(
      'diary_entries',
      {
        'japanese': entry.japanese,
        'furigana': entry.furigana,
        'romaji': entry.romaji,
        'meaning': entry.meaning,
        'notes': entry.notes,
        'date_added': entry.dateAdded.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Deletes a diary entry from the database.
  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes all diary entries from the database.
  Future<int> deleteAllEntries() async {
    final db = await database;
    return await db.delete('diary_entries');
  }

  /// Loads kanji data from JSON asset into the database.
  Future<void> _loadKanjiData(Database db) async {
    try {
      // Check if kanji data already exists
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM kanji'),
      );

      if (count != null && count > 0) {
        return; // Data already loaded
      }

      // Load JSON from assets
      final String jsonString = await rootBundle.loadString(
        'lib/assets/kanji_data.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Insert kanji data in batches for better performance
      var batch = db.batch();
      int batchCount = 0;

      for (var entry in jsonData.entries) {
        final kanjiData = KanjiData.fromJson(entry.key, entry.value);
        batch.insert('kanji', kanjiData.toMap());
        batchCount++;

        // Commit batch every 500 entries and create a new batch
        if (batchCount >= 500) {
          await batch.commit(noResult: true);
          batch = db.batch(); // Create new batch
          batchCount = 0;
        }
      }

      // Commit remaining entries
      if (batchCount > 0) {
        await batch.commit(noResult: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Gets the count of kanji entries in the database (for debugging).
  Future<int> getKanjiCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM kanji'),
    );
    return count ?? 0;
  }

  /// Searches for kanji by character, meaning, or reading.
  /// Also extracts individual kanji characters from the query for more flexible matching.
  Future<List<KanjiData>> searchKanji(String query) async {
    final db = await database;
    try {
      final results = <String, KanjiData>{};

      // First, search by meaning and readings (original behavior)
      final textResults = await db.query(
        'kanji',
        where: 'meanings LIKE ? OR readings_on LIKE ? OR readings_kun LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        limit: 50,
      );
      for (var json in textResults) {
        final kanji = KanjiData.fromMap(json);
        results[kanji.kanji] = kanji;
      }

      // Extract individual kanji characters from the query
      final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
      final matches = kanjiPattern.allMatches(query);

      for (var match in matches) {
        final kanjiChar = match.group(0)!;
        final charResults = await db.query(
          'kanji',
          where: 'kanji = ?',
          whereArgs: [kanjiChar],
        );
        for (var json in charResults) {
          final kanji = KanjiData.fromMap(json);
          results[kanji.kanji] = kanji;
        }
      }

      return results.values.take(50).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets a specific kanji by its character.
  Future<KanjiData?> getKanji(String kanji) async {
    final db = await database;
    final result = await db.query(
      'kanji',
      where: 'kanji = ?',
      whereArgs: [kanji],
    );
    if (result.isEmpty) return null;
    return KanjiData.fromMap(result.first);
  }

  /// Gets JLPT level statistics for kanji found in diary entries.
  ///
  /// Extracts all unique kanji characters from diary entries and queries
  /// the kanji table to get their JLPT levels. Returns a map with counts
  /// for each JLPT level (N5-N1, using jlpt_new field).
  ///
  /// Returns a map with keys: 5, 4, 3, 2, 1 (N5 to N1) and null for unclassified.
  Future<Map<int?, int>> getLearnedKanjiByJlptLevel() async {
    final db = await database;

    // Get all diary entries
    final allEntries = await getAllEntries();

    if (allEntries.isEmpty) {
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0, null: 0};
    }

    // Extract all unique kanji characters from diary entries
    final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
    final uniqueKanji = <String>{};

    for (var entry in allEntries) {
      final matches = kanjiPattern.allMatches(entry.japanese);
      for (var match in matches) {
        uniqueKanji.add(match.group(0)!);
      }
    }

    if (uniqueKanji.isEmpty) {
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0, null: 0};
    }

    // Query kanji table for JLPT levels
    final placeholders = List.filled(uniqueKanji.length, '?').join(',');
    final results = await db.query(
      'kanji',
      columns: ['jlpt_new'],
      where: 'kanji IN ($placeholders)',
      whereArgs: uniqueKanji.toList(),
    );

    // Count kanji by JLPT level
    final Map<int?, int> levelCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0, null: 0};

    for (var result in results) {
      final level = result['jlpt_new'] as int?;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }

    return levelCounts;
  }

  /// Gets random kanji data for practice from those found in diary entries.
  ///
  /// This method ensures practice is relevant by only including kanji that
  /// the user has encountered in their diary entries. The algorithm:
  ///
  /// 1. Fetches all diary entries
  /// 2. Extracts unique kanji characters using Unicode ranges:
  ///    - U+4E00-U+9FFF (CJK Unified Ideographs)
  ///    - U+3400-U+4DBF (CJK Extension A)
  /// 3. Queries the kanji table for matching characters (efficient WHERE IN)
  /// 4. Shuffles and returns up to [count] random kanji
  ///
  /// Returns an empty list if no diary entries exist or no kanji are found.
  Future<List<KanjiData>> getRandomKanjiFromDiary({int count = 10}) async {
    final db = await database;

    // Get all diary entries to extract kanji from
    final allEntries = await getAllEntries();

    if (allEntries.isEmpty) {
      return [];
    }

    // Extract all unique kanji characters from diary entries
    final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
    final uniqueKanji = <String>{};

    for (var entry in allEntries) {
      final matches = kanjiPattern.allMatches(entry.japanese);
      for (var match in matches) {
        uniqueKanji.add(match.group(0)!);
      }
    }

    if (uniqueKanji.isEmpty) {
      return [];
    }

    // Query kanji table for only those kanji that appear in diary entries
    final placeholders = List.filled(uniqueKanji.length, '?').join(',');
    final results = await db.query(
      'kanji',
      where: 'kanji IN ($placeholders)',
      whereArgs: uniqueKanji.toList(),
    );

    if (results.isEmpty) {
      return [];
    }

    // Convert to KanjiData and shuffle
    final allKanji = results.map((json) => KanjiData.fromMap(json)).toList();

    final random = Random();
    allKanji.shuffle(random);

    // Take up to the requested count
    return allKanji.take(min(count, allKanji.length)).toList();
  }

  /// Gets the full path to the database file.
  ///
  /// Returns the custom path if set, otherwise returns the default path.
  Future<String> getDatabasePath() async {
    final customPath = await AppPreferences.getCustomDatabasePath();

    if (customPath != null && customPath.isNotEmpty) {
      if (customPath.endsWith('.db')) {
        return customPath;
      } else {
        return join(customPath, 'diary.db');
      }
    }

    final dbPath = await getDatabasesPath();
    return join(dbPath, 'diary.db');
  }

  /// Deletes the entire database file and resets the instance.
  /// This will remove all data including diary entries and kanji.
  Future<void> deleteDatabase() async {
    try {
      final path = await getDatabasePath();
      await close();
      _database = null;

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await database;
    db.close();
  }

  /// Resets the database connection.
  /// Call this after changing the database path to force a reconnection.
  Future<void> resetConnection() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
