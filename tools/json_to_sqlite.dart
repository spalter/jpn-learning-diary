// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Converts a JSON file with kanjis, readings, and words to a SQLite database.
///
/// Usage: dart run tool/json_to_sqlite.dart input.json output.db
///
/// Expected JSON format:
/// {
///   "kanjis": { "key1": {...}, "key2": {...}, ... },
///   "readings": { "key1": {...}, "key2": {...}, ... },
///   "words": { "key1": [{meanings: [...], variants: [...]}, ...], ... }
/// }

void main(List<String> args) {
  if (args.length < 2) {
    print('Usage: dart run tool/json_to_sqlite.dart input.json output.db');
    print('');
    print('Arguments:');
    print('  input.json   - Path to the input JSON file');
    print('  output.db    - Path to the output SQLite database file');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];

  // Validate input file exists
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Error: Input file not found: $inputPath');
    exit(1);
  }

  // Delete existing output file if it exists
  final outputFile = File(outputPath);
  if (outputFile.existsSync()) {
    print('Deleting existing database: $outputPath');
    outputFile.deleteSync();
  }

  try {
    print('Reading JSON file: $inputPath');
    final jsonString = inputFile.readAsStringSync();
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;

    print('Creating SQLite database: $outputPath');
    final db = sqlite3.open(outputPath);

    try {
      // Process kanjis and readings as simple map tables
      for (final tableName in ['kanjis', 'readings']) {
        if (jsonData.containsKey(tableName)) {
          final tableData = jsonData[tableName] as Map<String, dynamic>;
          convertMapToTable(db, tableData, tableName);
        } else {
          print('Warning: "$tableName" not found in JSON');
        }
      }

      // Process words with its special structure (array of entries per key)
      if (jsonData.containsKey('words')) {
        final wordsData = jsonData['words'] as Map<String, dynamic>;
        convertWordsToTables(db, wordsData);
      } else {
        print('Warning: "words" not found in JSON');
      }

      print('Conversion complete!');
    } finally {
      db.close();
    }
  } catch (e, stackTrace) {
    print('Error during conversion: $e');
    print(stackTrace);
    exit(1);
  }
}

/// Converts a map with keys as IDs to a SQLite table.
void convertMapToTable(Database db, Map<String, dynamic> data, String tableName) {
  if (data.isEmpty) {
    print('Warning: "$tableName" is empty, skipping.');
    return;
  }

  // Convert map to list with key as '_key' column
  final items = <Map<String, dynamic>>[];
  for (final entry in data.entries) {
    final item = Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
    item['_key'] = entry.key;
    items.add(item);
  }

  // Collect all unique columns from all items
  final columnsSet = <String>{};
  for (final item in items) {
    columnsSet.addAll(item.keys);
  }

  // Ensure _key is first
  columnsSet.remove('_key');
  final columns = ['_key', ...columnsSet];

  // Infer column types
  final columnTypes = <String, String>{};
  for (final column in columns) {
    String? inferredType;
    for (final item in items) {
      final value = item[column];
      if (value == null) continue;
      final valueType = _getSqliteType(value);
      if (inferredType == null) {
        inferredType = valueType;
      } else if (inferredType != valueType) {
        inferredType = 'TEXT';
        break;
      }
    }
    columnTypes[column] = inferredType ?? 'TEXT';
  }

  // Create table
  final columnDefs = columns.map((col) {
    final type = columnTypes[col] ?? 'TEXT';
    return '"$col" $type';
  }).join(', ');

  db.execute('CREATE TABLE "$tableName" ($columnDefs)');
  db.execute('CREATE INDEX "idx_${tableName}_key" ON "$tableName" ("_key")');

  // Insert data
  final placeholders = List.filled(columns.length, '?').join(', ');
  final columnNames = columns.map((c) => '"$c"').join(', ');
  final sql = 'INSERT INTO "$tableName" ($columnNames) VALUES ($placeholders)';
  final stmt = db.prepare(sql);

  try {
    db.execute('BEGIN TRANSACTION');

    for (final item in items) {
      final values = columns.map((col) => _convertValue(item[col])).toList();
      stmt.execute(values);
    }

    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  } finally {
    stmt.close();
  }

  print('Created table "$tableName" with ${items.length} rows and ${columns.length} columns');
}

/// Returns the SQLite type for a Dart value.
String _getSqliteType(dynamic value) {
  if (value is int) return 'INTEGER';
  if (value is double) return 'REAL';
  if (value is bool) return 'INTEGER';
  return 'TEXT';
}

/// Converts a Dart value to a SQLite-compatible value.
dynamic _convertValue(dynamic value) {
  if (value == null) return null;
  if (value is int || value is double || value is String) return value;
  if (value is bool) return value ? 1 : 0;
  if (value is List || value is Map) return json.encode(value);
  return value.toString();
}

/// Converts the words data structure to normalized SQLite tables.
///
/// Words structure:
/// {
///   "kanji_key": [
///     {
///       "meanings": [{"glosses": ["meaning1", "meaning2"]}],
///       "variants": [{"priorities": [...], "pronounced": "...", "written": "..."}]
///     },
///     ...
///   ]
/// }
///
/// Creates three tables:
/// - words: (id, kanji) - main word entries
/// - word_meanings: (id, word_id, glosses) - meanings with glosses as JSON array
/// - word_variants: (id, word_id, priorities, pronounced, written)
void convertWordsToTables(Database db, Map<String, dynamic> data) {
  if (data.isEmpty) {
    print('Warning: "words" is empty, skipping.');
    return;
  }

  // Create tables
  db.execute('''
    CREATE TABLE "words" (
      "id" INTEGER PRIMARY KEY,
      "kanji" TEXT NOT NULL
    )
  ''');
  db.execute('CREATE INDEX "idx_words_kanji" ON "words" ("kanji")');

  db.execute('''
    CREATE TABLE "word_meanings" (
      "id" INTEGER PRIMARY KEY,
      "word_id" INTEGER NOT NULL,
      "glosses" TEXT NOT NULL,
      FOREIGN KEY ("word_id") REFERENCES "words" ("id")
    )
  ''');
  db.execute('CREATE INDEX "idx_word_meanings_word_id" ON "word_meanings" ("word_id")');

  db.execute('''
    CREATE TABLE "word_variants" (
      "id" INTEGER PRIMARY KEY,
      "word_id" INTEGER NOT NULL,
      "priorities" TEXT,
      "pronounced" TEXT,
      "written" TEXT,
      FOREIGN KEY ("word_id") REFERENCES "words" ("id")
    )
  ''');
  db.execute('CREATE INDEX "idx_word_variants_word_id" ON "word_variants" ("word_id")');

  // Prepare statements
  final insertWord = db.prepare('INSERT INTO "words" ("kanji") VALUES (?)');
  final insertMeaning = db.prepare(
    'INSERT INTO "word_meanings" ("word_id", "glosses") VALUES (?, ?)',
  );
  final insertVariant = db.prepare(
    'INSERT INTO "word_variants" ("word_id", "priorities", "pronounced", "written") VALUES (?, ?, ?, ?)',
  );

  int wordCount = 0;
  int meaningCount = 0;
  int variantCount = 0;

  try {
    db.execute('BEGIN TRANSACTION');

    for (final entry in data.entries) {
      final kanji = entry.key;
      final wordEntries = entry.value as List<dynamic>;

      for (final wordEntry in wordEntries) {
        final wordMap = wordEntry as Map<String, dynamic>;

        // Insert main word entry
        insertWord.execute([kanji]);
        final wordId = db.lastInsertRowId;
        wordCount++;

        // Insert meanings
        final meanings = wordMap['meanings'] as List<dynamic>? ?? [];
        for (final meaning in meanings) {
          final meaningMap = meaning as Map<String, dynamic>;
          final glosses = meaningMap['glosses'] as List<dynamic>? ?? [];
          insertMeaning.execute([wordId, json.encode(glosses)]);
          meaningCount++;
        }

        // Insert variants
        final variants = wordMap['variants'] as List<dynamic>? ?? [];
        for (final variant in variants) {
          final variantMap = variant as Map<String, dynamic>;
          final priorities = variantMap['priorities'] as List<dynamic>? ?? [];
          final pronounced = variantMap['pronounced'] as String?;
          final written = variantMap['written'] as String?;
          insertVariant.execute([
            wordId,
            json.encode(priorities),
            pronounced,
            written,
          ]);
          variantCount++;
        }
      }
    }

    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  } finally {
    insertWord.close();
    insertMeaning.close();
    insertVariant.close();
  }

  print('Created table "words" with $wordCount rows');
  print('Created table "word_meanings" with $meaningCount rows');
  print('Created table "word_variants" with $variantCount rows');
}

