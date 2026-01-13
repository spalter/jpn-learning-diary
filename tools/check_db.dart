// ignore_for_file: avoid_print

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart check_db.dart <input.db>');
    exit(1);
  }

  final dbPath = args[0];
  final db = sqlite3.open(dbPath);

  print('Database: $dbPath');
  print('');

  // Print row counts at the top
  print('=== ROW COUNTS ===');
  final tables = ['kanjis', 'readings', 'words', 'word_meanings', 'word_variants'];
  for (final table in tables) {
    final count = db.select('SELECT COUNT(*) as count FROM $table').first['count'];
    print('$table: $count rows');
  }

  // Print sample data at the bottom
  print('');
  print('=== KANJIS (first 3) ===');
  for (final row in db.select('SELECT * FROM kanjis LIMIT 3')) {
    print(row);
  }

  print('');
  print('=== READINGS (first 3) ===');
  for (final row in db.select('SELECT * FROM readings LIMIT 3')) {
    print(row);
  }

  print('');
  print('=== WORDS (first 3) ===');
  for (final row in db.select('SELECT * FROM words LIMIT 3')) {
    print(row);
  }

  print('');
  print('=== WORD_MEANINGS (first 3) ===');
  for (final row in db.select('SELECT * FROM word_meanings LIMIT 3')) {
    print(row);
  }

  print('');
  print('=== WORD_VARIANTS (first 3) ===');
  for (final row in db.select('SELECT * FROM word_variants LIMIT 3')) {
    print(row);
  }

  db.close();
}
