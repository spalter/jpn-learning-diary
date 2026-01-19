// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Converts a JMdict XML file to a SQLite database.
///
/// Usage: dart run tools/jmdict_to_sqlite.dart input.xml output.db
///
/// The JMdict XML file is the standard Japanese-Multilingual Dictionary file
/// from the EDRDG (Electronic Dictionary Research and Development Group).
///
/// Creates normalized tables in the jmdict schema:
/// - jmdict_entries: Main entry table with ent_seq
/// - jmdict_kanji: Kanji elements (k_ele) with keb, ke_inf, ke_pri
/// - jmdict_readings: Reading elements (r_ele) with reb, re_nokanji, re_restr, re_inf, re_pri
/// - jmdict_senses: Sense elements with pos, field, misc, dial, s_inf
/// - jmdict_glosses: Gloss translations for each sense
/// - jmdict_lsources: Loan word source information
/// - jmdict_xrefs: Cross-references
/// - jmdict_ants: Antonyms

void main(List<String> args) {
  if (args.length < 2) {
    print('Usage: dart run tools/jmdict_to_sqlite.dart input.xml output.db');
    print('');
    print('Arguments:');
    print('  input.xml    - Path to the JMdict XML file (e.g., JMdict_e)');
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

  try {
    print('Opening SQLite database: $outputPath');
    final db = sqlite3.open(outputPath);

    // Drop existing jmdict tables if they exist
    _dropExistingTables(db);

    try {
      // Create tables
      _createTables(db);

      // Parse and import XML
      print('Parsing JMdict XML file: $inputPath');
      _parseAndImportXml(db, inputFile);

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

/// Drops existing JMdict tables if they exist.
void _dropExistingTables(Database db) {
  final tables = [
    'jmdict_ants',
    'jmdict_xrefs',
    'jmdict_lsources',
    'jmdict_glosses',
    'jmdict_senses',
    'jmdict_readings',
    'jmdict_kanji',
    'jmdict_entries',
  ];

  for (final table in tables) {
    db.execute('DROP TABLE IF EXISTS "$table"');
  }
  print('Dropped existing jmdict tables (if any).');
}

/// Creates all JMdict tables in the database.
void _createTables(Database db) {
  print('Creating tables...');

  // Main entry table
  db.execute('''
    CREATE TABLE "jmdict_entries" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "ent_seq" INTEGER NOT NULL UNIQUE
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_entries_ent_seq" ON "jmdict_entries" ("ent_seq")');

  // Kanji elements table
  db.execute('''
    CREATE TABLE "jmdict_kanji" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "entry_id" INTEGER NOT NULL,
      "keb" TEXT NOT NULL,
      "ke_inf" TEXT,
      "ke_pri" TEXT,
      FOREIGN KEY ("entry_id") REFERENCES "jmdict_entries" ("id")
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_kanji_entry_id" ON "jmdict_kanji" ("entry_id")');
  db.execute('CREATE INDEX "idx_jmdict_kanji_keb" ON "jmdict_kanji" ("keb")');

  // Reading elements table
  db.execute('''
    CREATE TABLE "jmdict_readings" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "entry_id" INTEGER NOT NULL,
      "reb" TEXT NOT NULL,
      "re_nokanji" INTEGER DEFAULT 0,
      "re_restr" TEXT,
      "re_inf" TEXT,
      "re_pri" TEXT,
      FOREIGN KEY ("entry_id") REFERENCES "jmdict_entries" ("id")
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_readings_entry_id" ON "jmdict_readings" ("entry_id")');
  db.execute(
      'CREATE INDEX "idx_jmdict_readings_reb" ON "jmdict_readings" ("reb")');

  // Sense elements table
  db.execute('''
    CREATE TABLE "jmdict_senses" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "entry_id" INTEGER NOT NULL,
      "sense_num" INTEGER NOT NULL,
      "stagk" TEXT,
      "stagr" TEXT,
      "pos" TEXT,
      "field" TEXT,
      "misc" TEXT,
      "dial" TEXT,
      "s_inf" TEXT,
      FOREIGN KEY ("entry_id") REFERENCES "jmdict_entries" ("id")
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_senses_entry_id" ON "jmdict_senses" ("entry_id")');

  // Glosses table
  db.execute('''
    CREATE TABLE "jmdict_glosses" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "gloss" TEXT NOT NULL,
      "lang" TEXT DEFAULT 'eng',
      "g_type" TEXT,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_glosses_sense_id" ON "jmdict_glosses" ("sense_id")');

  // Loan source table
  db.execute('''
    CREATE TABLE "jmdict_lsources" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "lsource" TEXT,
      "lang" TEXT DEFAULT 'eng',
      "ls_type" TEXT,
      "ls_wasei" INTEGER DEFAULT 0,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_lsources_sense_id" ON "jmdict_lsources" ("sense_id")');

  // Cross-references table
  db.execute('''
    CREATE TABLE "jmdict_xrefs" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "xref" TEXT NOT NULL,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_xrefs_sense_id" ON "jmdict_xrefs" ("sense_id")');

  // Antonyms table
  db.execute('''
    CREATE TABLE "jmdict_ants" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "ant" TEXT NOT NULL,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    )
  ''');
  db.execute(
      'CREATE INDEX "idx_jmdict_ants_sense_id" ON "jmdict_ants" ("sense_id")');

  print('Tables created successfully.');
}

/// Parses the JMdict XML file and imports data into the database.
void _parseAndImportXml(Database db, File inputFile) {
  // Prepare statements
  final insertEntry =
      db.prepare('INSERT INTO "jmdict_entries" ("ent_seq") VALUES (?)');
  final insertKanji = db.prepare(
      'INSERT INTO "jmdict_kanji" ("entry_id", "keb", "ke_inf", "ke_pri") VALUES (?, ?, ?, ?)');
  final insertReading = db.prepare(
      'INSERT INTO "jmdict_readings" ("entry_id", "reb", "re_nokanji", "re_restr", "re_inf", "re_pri") VALUES (?, ?, ?, ?, ?, ?)');
  final insertSense = db.prepare(
      'INSERT INTO "jmdict_senses" ("entry_id", "sense_num", "stagk", "stagr", "pos", "field", "misc", "dial", "s_inf") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
  final insertGloss = db.prepare(
      'INSERT INTO "jmdict_glosses" ("sense_id", "gloss", "lang", "g_type") VALUES (?, ?, ?, ?)');
  final insertLsource = db.prepare(
      'INSERT INTO "jmdict_lsources" ("sense_id", "lsource", "lang", "ls_type", "ls_wasei") VALUES (?, ?, ?, ?, ?)');
  final insertXref =
      db.prepare('INSERT INTO "jmdict_xrefs" ("sense_id", "xref") VALUES (?, ?)');
  final insertAnt =
      db.prepare('INSERT INTO "jmdict_ants" ("sense_id", "ant") VALUES (?, ?)');

  int entryCount = 0;
  int kanjiCount = 0;
  int readingCount = 0;
  int senseCount = 0;
  int glossCount = 0;
  int lsourceCount = 0;
  int xrefCount = 0;
  int antCount = 0;

  try {
    db.execute('BEGIN TRANSACTION');

    // Read the file content
    final content = inputFile.readAsStringSync();

    // Use a streaming-like approach with regex to extract entries
    // This is more memory efficient than loading the entire DOM
    final entryRegex = RegExp(r'<entry>(.*?)</entry>', dotAll: true);
    final entries = entryRegex.allMatches(content);

    print('Found ${entries.length} entries to process...');

    for (final match in entries) {
      final entryXml = match.group(1)!;

      // Parse ent_seq
      final entSeq = _extractText(entryXml, 'ent_seq');
      if (entSeq == null) continue;

      // Insert entry
      insertEntry.execute([int.parse(entSeq)]);
      final entryId = db.lastInsertRowId;
      entryCount++;

      // Parse k_ele (kanji elements)
      final kEleRegex = RegExp(r'<k_ele>(.*?)</k_ele>', dotAll: true);
      for (final kEle in kEleRegex.allMatches(entryXml)) {
        final kEleXml = kEle.group(1)!;
        final keb = _extractText(kEleXml, 'keb');
        final keInf = _extractAllText(kEleXml, 'ke_inf');
        final kePri = _extractAllText(kEleXml, 'ke_pri');

        if (keb != null) {
          insertKanji.execute([
            entryId,
            keb,
            keInf.isNotEmpty ? json.encode(keInf) : null,
            kePri.isNotEmpty ? json.encode(kePri) : null,
          ]);
          kanjiCount++;
        }
      }

      // Parse r_ele (reading elements)
      final rEleRegex = RegExp(r'<r_ele>(.*?)</r_ele>', dotAll: true);
      for (final rEle in rEleRegex.allMatches(entryXml)) {
        final rEleXml = rEle.group(1)!;
        final reb = _extractText(rEleXml, 'reb');
        final reNokanji = _hasElement(rEleXml, 're_nokanji');
        final reRestr = _extractAllText(rEleXml, 're_restr');
        final reInf = _extractAllText(rEleXml, 're_inf');
        final rePri = _extractAllText(rEleXml, 're_pri');

        if (reb != null) {
          insertReading.execute([
            entryId,
            reb,
            reNokanji ? 1 : 0,
            reRestr.isNotEmpty ? json.encode(reRestr) : null,
            reInf.isNotEmpty ? json.encode(reInf) : null,
            rePri.isNotEmpty ? json.encode(rePri) : null,
          ]);
          readingCount++;
        }
      }

      // Parse sense elements
      final senseRegex = RegExp(r'<sense>(.*?)</sense>', dotAll: true);
      int senseNum = 0;
      for (final sense in senseRegex.allMatches(entryXml)) {
        senseNum++;
        final senseXml = sense.group(1)!;

        final stagk = _extractAllText(senseXml, 'stagk');
        final stagr = _extractAllText(senseXml, 'stagr');
        final pos = _extractAllText(senseXml, 'pos');
        final field = _extractAllText(senseXml, 'field');
        final misc = _extractAllText(senseXml, 'misc');
        final dial = _extractAllText(senseXml, 'dial');
        final sInf = _extractAllText(senseXml, 's_inf');

        insertSense.execute([
          entryId,
          senseNum,
          stagk.isNotEmpty ? json.encode(stagk) : null,
          stagr.isNotEmpty ? json.encode(stagr) : null,
          pos.isNotEmpty ? json.encode(pos) : null,
          field.isNotEmpty ? json.encode(field) : null,
          misc.isNotEmpty ? json.encode(misc) : null,
          dial.isNotEmpty ? json.encode(dial) : null,
          sInf.isNotEmpty ? json.encode(sInf) : null,
        ]);
        final senseId = db.lastInsertRowId;
        senseCount++;

        // Parse glosses
        final glossRegex =
            RegExp(r'<gloss(?:\s+([^>]*))?>([^<]*)</gloss>', dotAll: true);
        for (final gloss in glossRegex.allMatches(senseXml)) {
          final attrs = gloss.group(1) ?? '';
          final glossText = gloss.group(2)!.trim();

          // Extract lang attribute (default: eng)
          final langMatch = RegExp(r'xml:lang="([^"]*)"').firstMatch(attrs);
          final lang = langMatch?.group(1) ?? 'eng';

          // Extract g_type attribute
          final gTypeMatch = RegExp(r'g_type="([^"]*)"').firstMatch(attrs);
          final gType = gTypeMatch?.group(1);

          if (glossText.isNotEmpty) {
            insertGloss.execute([senseId, glossText, lang, gType]);
            glossCount++;
          }
        }

        // Parse lsource elements
        final lsourceRegex =
            RegExp(r'<lsource(?:\s+([^>]*))?>([^<]*)</lsource>|<lsource(?:\s+([^>]*))?/>', dotAll: true);
        for (final lsource in lsourceRegex.allMatches(senseXml)) {
          final attrs = lsource.group(1) ?? lsource.group(3) ?? '';
          final lsourceText = lsource.group(2)?.trim() ?? '';

          // Extract lang attribute (default: eng)
          final langMatch = RegExp(r'xml:lang="([^"]*)"').firstMatch(attrs);
          final lang = langMatch?.group(1) ?? 'eng';

          // Extract ls_type attribute
          final lsTypeMatch = RegExp(r'ls_type="([^"]*)"').firstMatch(attrs);
          final lsType = lsTypeMatch?.group(1);

          // Extract ls_wasei attribute
          final lsWaseiMatch = RegExp(r'ls_wasei="([^"]*)"').firstMatch(attrs);
          final lsWasei = lsWaseiMatch?.group(1) == 'y' ? 1 : 0;

          insertLsource.execute([
            senseId,
            lsourceText.isNotEmpty ? lsourceText : null,
            lang,
            lsType,
            lsWasei,
          ]);
          lsourceCount++;
        }

        // Parse xref elements
        final xrefs = _extractAllText(senseXml, 'xref');
        for (final xref in xrefs) {
          insertXref.execute([senseId, xref]);
          xrefCount++;
        }

        // Parse ant elements
        final ants = _extractAllText(senseXml, 'ant');
        for (final ant in ants) {
          insertAnt.execute([senseId, ant]);
          antCount++;
        }
      }

      // Progress indicator
      if (entryCount % 10000 == 0) {
        print('Processed $entryCount entries...');
      }
    }

    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  } finally {
    insertEntry.close();
    insertKanji.close();
    insertReading.close();
    insertSense.close();
    insertGloss.close();
    insertLsource.close();
    insertXref.close();
    insertAnt.close();
  }

  print('');
  print('Import summary:');
  print('  Entries: $entryCount');
  print('  Kanji elements: $kanjiCount');
  print('  Reading elements: $readingCount');
  print('  Senses: $senseCount');
  print('  Glosses: $glossCount');
  print('  Loan sources: $lsourceCount');
  print('  Cross-references: $xrefCount');
  print('  Antonyms: $antCount');
}

/// Extracts the first text content from an XML element.
String? _extractText(String xml, String tagName) {
  final regex = RegExp('<$tagName>([^<]*)</$tagName>');
  final match = regex.firstMatch(xml);
  return match?.group(1)?.trim();
}

/// Extracts all text contents from XML elements with the given tag name.
List<String> _extractAllText(String xml, String tagName) {
  final regex = RegExp('<$tagName>([^<]*)</$tagName>');
  return regex.allMatches(xml).map((m) => m.group(1)!.trim()).toList();
}

/// Checks if an element exists (including empty/self-closing).
bool _hasElement(String xml, String tagName) {
  return xml.contains('<$tagName>') || xml.contains('<$tagName/>');
}
