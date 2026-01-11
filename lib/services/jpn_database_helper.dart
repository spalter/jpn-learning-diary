import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database helper for the read-only Japanese language database.
///
/// This database contains kanji, readings, and words data that is shipped
/// with the app as an asset. It is copied to the app's documents directory
/// on first launch and opened in read-only mode.
///
/// Uses a singleton pattern to ensure only one database connection exists.
class JpnDatabaseHelper {
  /// Singleton instance of the database helper.
  static final JpnDatabaseHelper instance = JpnDatabaseHelper._init();

  /// The SQLite database instance.
  static Database? _database;

  /// Asset path for the database file.
  static const String _assetPath = 'lib/assets/jpn.db';

  /// Database filename.
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

  /// Initializes the database by copying from assets if needed.
  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    // Check if database already exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets
      await _copyDatabaseFromAssets(path);
    }

    // Open in read-only mode
    return await openDatabase(path, readOnly: true);
  }

  /// Copies the database file from assets to the documents directory.
  Future<void> _copyDatabaseFromAssets(String targetPath) async {
    // Ensure the directory exists
    final directory = Directory(dirname(targetPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Load database from assets
    final data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    // Write to file
    await File(targetPath).writeAsBytes(bytes, flush: true);
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

  /// Gets the count of kanji entries in the database.
  Future<int> getKanjiCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM kanjis'),
    );
    return count ?? 0;
  }

  /// Searches for words by kanji, reading, or meaning.
  ///
  /// Returns word data with meanings and variants.
  Future<List<Map<String, dynamic>>> searchWords(String query) async {
    final db = await database;

    // Get word IDs matching the kanji
    final wordResults = await db.query(
      'words',
      where: 'kanji LIKE ?',
      whereArgs: ['%$query%'],
      limit: 100,
    );

    final results = <Map<String, dynamic>>[];

    for (var word in wordResults) {
      final wordId = word['id'] as int;
      final kanji = word['kanji'] as String;

      // Get meanings for this word
      final meanings = await db.query(
        'word_meanings',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      // Get variants for this word
      final variants = await db.query(
        'word_variants',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      results.add({
        'id': wordId,
        'kanji': kanji,
        'meanings': meanings,
        'variants': variants,
      });
    }

    // Also search by variant written/pronounced forms
    final variantResults = await db.rawQuery('''
      SELECT DISTINCT w.id, w.kanji
      FROM words w
      JOIN word_variants v ON w.id = v.word_id
      WHERE v.written LIKE ? OR v.pronounced LIKE ?
      LIMIT 100
    ''', ['%$query%', '%$query%']);

    for (var word in variantResults) {
      final wordId = word['id'] as int;

      // Skip if already in results
      if (results.any((r) => r['id'] == wordId)) continue;

      final kanji = word['kanji'] as String;

      // Get meanings for this word
      final meanings = await db.query(
        'word_meanings',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      // Get variants for this word
      final variants = await db.query(
        'word_variants',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      results.add({
        'id': wordId,
        'kanji': kanji,
        'meanings': meanings,
        'variants': variants,
      });
    }

    // Also search by meaning/gloss
    final glossResults = await db.rawQuery('''
      SELECT DISTINCT w.id, w.kanji
      FROM words w
      JOIN word_meanings m ON w.id = m.word_id
      WHERE m.glosses LIKE ?
      LIMIT 100
    ''', ['%$query%']);

    for (var word in glossResults) {
      final wordId = word['id'] as int;

      // Skip if already in results
      if (results.any((r) => r['id'] == wordId)) continue;

      final kanji = word['kanji'] as String;

      // Get meanings for this word
      final meanings = await db.query(
        'word_meanings',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      // Get variants for this word
      final variants = await db.query(
        'word_variants',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      results.add({
        'id': wordId,
        'kanji': kanji,
        'meanings': meanings,
        'variants': variants,
      });
    }

    return results.take(50).toList();
  }

  /// Gets words that contain a specific kanji character.
  Future<List<Map<String, dynamic>>> getWordsForKanji(String kanji) async {
    final db = await database;

    // Get word IDs for this kanji
    final wordResults = await db.query(
      'words',
      where: 'kanji = ?',
      whereArgs: [kanji],
      limit: 100,
    );

    final results = <Map<String, dynamic>>[];

    for (var word in wordResults) {
      final wordId = word['id'] as int;

      // Get meanings for this word
      final meanings = await db.query(
        'word_meanings',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      // Get variants for this word
      final variants = await db.query(
        'word_variants',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      results.add({
        'id': wordId,
        'kanji': kanji,
        'meanings': meanings,
        'variants': variants,
      });
    }

    return results;
  }

  /// Gets the count of word entries in the database.
  Future<int> getWordCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words'),
    );
    return count ?? 0;
  }

  /// Gets reading data for a specific reading string.
  Future<Map<String, dynamic>?> getReading(String reading) async {
    final db = await database;
    final result = await db.query(
      'readings',
      where: '_key = ?',
      whereArgs: [reading],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Searches for readings.
  Future<List<Map<String, dynamic>>> searchReadings(String query) async {
    final db = await database;
    final results = await db.query(
      'readings',
      where: '_key LIKE ? OR reading LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 50,
    );
    return results;
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Resets the database by deleting the local copy and re-copying from assets.
  ///
  /// This is useful if the asset database has been updated.
  Future<void> resetDatabase() async {
    await close();

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    // Database will be re-copied on next access
  }
}
