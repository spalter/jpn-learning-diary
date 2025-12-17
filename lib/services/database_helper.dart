import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';

/// Database helper for managing diary entries in SQLite.
///
/// Provides CRUD operations for diary entries with a singleton pattern.
/// Designed to be easily replaceable with an API service later.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Gets the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary.db');
    return _database!;
  }

  /// Initializes the database file and creates tables.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
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
  }

  /// Inserts initial dummy data into the database.
  Future<void> _insertDummyData(Database db) async {
    final dummyEntries = [
      {
        'japanese': 'こんにちは',
        'furigana': 'こんにちは',
        'romaji': 'konnichiwa',
        'meaning': 'Hello (daytime greeting)',
        'notes': 'Formal greeting used during the day',
        'date_added': DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch,
      },
      {
        'japanese': '食べる',
        'furigana': 'たべる',
        'romaji': 'taberu',
        'meaning': 'to eat',
        'notes': 'Ichidan verb (ru-verb)',
        'date_added': DateTime.now().subtract(const Duration(days: 6)).millisecondsSinceEpoch,
      },
      {
        'japanese': '図書館',
        'furigana': 'としょかん',
        'romaji': 'toshokan',
        'meaning': 'library',
        'notes': 'Compound word: 図書 (books) + 館 (building)',
        'date_added': DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch,
      },
      {
        'japanese': 'ありがとう',
        'furigana': 'ありがとう',
        'romaji': 'arigatou',
        'meaning': 'Thank you',
        'notes': 'Casual way to say thank you',
        'date_added': DateTime.now().subtract(const Duration(days: 4)).millisecondsSinceEpoch,
      },
      {
        'japanese': '勉強する',
        'furigana': 'べんきょうする',
        'romaji': 'benkyou suru',
        'meaning': 'to study',
        'notes': 'Suru verb - attach する to the noun 勉強',
        'date_added': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
      },
      {
        'japanese': '美味しい',
        'furigana': 'おいしい',
        'romaji': 'oishii',
        'meaning': 'delicious',
        'notes': 'I-adjective describing food taste',
        'date_added': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      },
      {
        'japanese': 'お願いします',
        'furigana': 'おねがいします',
        'romaji': 'onegai shimasu',
        'meaning': 'please',
        'notes': 'Polite request form',
        'date_added': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
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
  Future<List<DiaryEntry>> getAllEntries() async {
    final db = await database;
    final result = await db.query(
      'diary_entries',
      orderBy: 'date_added DESC',
    );
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
    return await db.delete(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
