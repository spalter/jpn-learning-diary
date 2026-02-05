// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/models/anki_card.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Service for loading and parsing Anki APKG flashcard files.
///
/// APKG files are ZIP archives containing a SQLite database
/// (`collection.anki2` or `collection.anki21`) with notes and cards tables.
/// This service extracts the database from the archive, reads the notes,
/// and converts them into [AnkiCard] instances for use in flashcard sessions.
class AnkiService {
  AnkiService._();

  /// The name of the app folder in Documents.
  static const String _appFolderName = 'JPN Learning Diary';

  /// The name of the flashcards subfolder.
  static const String _flashcardsFolderName = 'flashcards';

  /// Gets the path to the flashcards directory in Documents.
  ///
  /// Creates the directory structure if it doesn't exist.
  static Future<Directory> getFlashcardsDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final flashcardsDir = Directory(
      path.join(documentsDir.path, _appFolderName, _flashcardsFolderName),
    );

    if (!await flashcardsDir.exists()) {
      await flashcardsDir.create(recursive: true);
    }

    return flashcardsDir;
  }

  /// Initializes the flashcards folder, creating it if needed.
  ///
  /// Should be called on app startup or before listing flashcard decks.
  static Future<void> initializeFlashcardsFolder() async {
    await getFlashcardsDirectory();
  }

  /// Lists all available APKG files in the flashcards directory.
  ///
  /// Returns a list of [AnkiDeckInfo] with file name and path.
  static Future<List<AnkiDeckInfo>> listAvailableDecks() async {
    final flashcardsDir = await getFlashcardsDirectory();
    final deckFiles = <AnkiDeckInfo>[];

    await for (final entity in flashcardsDir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.apkg')) {
        final fileName = path.basename(entity.path);
        deckFiles.add(
          AnkiDeckInfo(
            name: _formatDeckName(fileName),
            path: entity.path,
            fileName: fileName,
          ),
        );
      }
    }

    // Sort alphabetically by display name
    deckFiles.sort((a, b) => a.name.compareTo(b.name));
    return deckFiles;
  }

  /// Audio file extensions that should be extracted from the archive.
  static const Set<String> _audioExtensions = {
    '.mp3', '.ogg', '.wav', '.m4a', '.aac', '.flac', '.opus',
  };

  /// Image file extensions supported for display.
  static const Set<String> _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg',
  };

  /// Loads Anki cards from an APKG file at the given path.
  ///
  /// Only extracts the SQLite database and media JSON mapping.
  /// Media files (audio/images) are NOT extracted upfront — they are
  /// extracted on-demand via [extractAudioFile] when playback is requested.
  ///
  /// Throws [Exception] if the file cannot be read or parsed.
  static Future<AnkiDeckData> loadFromFile(String filePath) async {
    try {
      return await compute(_parseApkgFromPath, filePath);
    } catch (e) {
      throw Exception('Failed to load deck from file: $e');
    }
  }

  /// Top-level function for isolate-based APKG parsing.
  ///
  /// Runs in a separate isolate via [compute] to avoid blocking the UI.
  static AnkiDeckData _parseApkgFromPath(String filePath) {
    return _parseApkg(filePath);
  }

  /// Parses an APKG file, extracting only the database and media map.
  ///
  /// Iterates the ZIP entries but only decompresses the SQLite database
  /// and the media JSON file. All numbered media files (images, audio) are
  /// skipped for fast loading. Audio can be extracted later on-demand.
  static AnkiDeckData _parseApkg(String filePath) {
    final inputStream = InputFileStream(filePath);
    final archive = ZipDecoder().decodeStream(inputStream);

    // Scan entries — only decompress DB + media JSON
    List<int>? dbBytes;
    List<int>? dbBytesLegacy21;
    List<int>? dbBytesLegacy2;
    Map<String, String> mediaMap = {};

    for (final file in archive) {
      final name = file.name.toLowerCase();

      if (name == 'collection.anki21b' || name.endsWith('.anki21b')) {
        dbBytes = file.content as List<int>;
      } else if (name == 'collection.anki21' || name.endsWith('.anki21')) {
        dbBytesLegacy21 = file.content as List<int>;
      } else if (name == 'collection.anki2' || name.endsWith('.anki2')) {
        dbBytesLegacy2 = file.content as List<int>;
      } else if (name == 'media') {
        try {
          final mediaJson = utf8.decode(file.content as List<int>);
          final decoded = json.decode(mediaJson);
          if (decoded is Map) {
            mediaMap = decoded.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            );
          }
        } catch (_) {
          // Media map is optional
        }
      }
      // Skip all other files (numbered media) — no decompression cost
    }

    inputStream.closeSync();

    // Priority: anki21b > anki21 > anki2
    final selectedDbBytes = dbBytes ?? dbBytesLegacy21 ?? dbBytesLegacy2;

    if (selectedDbBytes == null) {
      throw Exception(
        'Invalid APKG file: no Anki database found.',
      );
    }

    // Write the SQLite DB to a temporary file so sqlite3 can open it
    final tempDbPath = path.join(
      Directory.systemTemp.path,
      'anki_temp_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    final tempDbFile = File(tempDbPath);

    try {
      tempDbFile.writeAsBytesSync(selectedDbBytes);
      final db = sqlite3.open(tempDbPath);

      try {
        final cards = _readCardsFromDb(db);
        return AnkiDeckData(
          cards: cards,
          apkgPath: filePath,
          mediaMap: mediaMap,
        );
      } finally {
        db.dispose();
      }
    } finally {
      if (tempDbFile.existsSync()) {
        tempDbFile.deleteSync();
      }
    }
  }

  /// Extracts a single media file (audio or image) from an APKG on-demand.
  ///
  /// Looks up [fileName] in the [mediaMap] to find the archive entry index,
  /// then extracts just that one file to [cacheDir]. Returns the path to the
  /// extracted file, or null if not found.
  static Future<String?> extractMediaFile({
    required String apkgPath,
    required Map<String, String> mediaMap,
    required String fileName,
    required String cacheDir,
  }) async {
    // Only extract known audio/image files
    final ext = path.extension(fileName).toLowerCase();
    if (!_audioExtensions.contains(ext) && !_imageExtensions.contains(ext)) {
      return null;
    }

    // Check if already extracted
    final targetPath = path.join(cacheDir, fileName);
    if (File(targetPath).existsSync()) {
      return targetPath;
    }

    // Find the archive index for this filename
    String? archiveIndex;
    for (final entry in mediaMap.entries) {
      if (entry.value == fileName) {
        archiveIndex = entry.key;
        break;
      }
    }

    if (archiveIndex == null) return null;

    // Open the APKG and extract just this one file
    final inputStream = InputFileStream(apkgPath);
    final archive = ZipDecoder().decodeStream(inputStream);

    for (final file in archive) {
      if (file.name == archiveIndex) {
        Directory(cacheDir).createSync(recursive: true);
        File(targetPath).writeAsBytesSync(file.content as List<int>);
        inputStream.closeSync();
        return targetPath;
      }
    }

    inputStream.closeSync();
    return null;
  }

  /// Cleans up a temporary media directory.
  ///
  /// Should be called when the flashcard session ends to free disk space.
  static Future<void> cleanupMediaDirectory(String? mediaDir) async {
    if (mediaDir == null) return;
    try {
      final dir = Directory(mediaDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup
    }
  }

  /// Reads cards from the Anki SQLite database.
  ///
  /// Parses note type models from the `col` table to determine which fields
  /// to use as front/back, then reads all notes and converts them to cards.
  static List<AnkiCard> _readCardsFromDb(Database db) {
    final cards = <AnkiCard>[];

    // Check which tables exist
    final tables = db
        .select("SELECT name FROM sqlite_master WHERE type='table'")
        .map((row) => row['name'] as String)
        .toList();

    if (!tables.contains('notes')) {
      throw Exception(
        'Invalid Anki database: notes table not found. '
        'Found tables: ${tables.join(", ")}',
      );
    }

    // Parse note type models to determine field layout
    // The `col` table has a `models` JSON column mapping model IDs to their
    // definitions including field names. Each note has a `mid` column.
    final modelInfo = _parseNoteModels(db, tables);

    // Read notes — include mid to look up field mapping
    final hasMid = _tableHasColumn(db, 'notes', 'mid');
    final query = hasMid
        ? 'SELECT id, mid, flds, tags FROM notes'
        : 'SELECT id, flds, tags FROM notes';
    final result = db.select(query);

    int skipped = 0;
    for (final row in result) {
      final noteId = row['id'] as int;
      final flds = row['flds'] as String;
      final tags = (row['tags'] as String?) ?? '';
      final mid = hasMid ? (row['mid'] as int?) : null;

      // Look up field indices and names for this note's model
      final info = mid != null ? modelInfo[mid] : null;
      final frontIdx = info?.frontIndex ?? 0;
      final backIdx = info?.backIndex ?? 1;
      final fieldNames = info?.fieldNames ?? const [];

      final card = AnkiCard.fromAnkiNote(
        noteId: noteId,
        fieldsString: flds,
        tagsString: tags,
        frontIndex: frontIdx,
        backIndex: backIdx,
        fieldNames: fieldNames,
      );

      if (card.isValid) {
        cards.add(card);
      } else {
        skipped++;
        if (skipped <= 3) {
          final fieldPreview =
              flds.length > 200 ? '${flds.substring(0, 200)}...' : flds;
          debugPrint(
            '[AnkiService] Skipped note $noteId '
            '(front="${card.front}", back="${card.back}"). '
            'Raw fields: $fieldPreview',
          );
        }
      }
    }

    debugPrint(
      '[AnkiService] Result: ${cards.length} valid cards, '
      '$skipped skipped',
    );

    return cards;
  }

  /// Checks if a table has a specific column.
  static bool _tableHasColumn(Database db, String table, String column) {
    try {
      final info = db.select('PRAGMA table_info($table)');
      return info.any((row) => row['name'] == column);
    } catch (_) {
      return false;
    }
  }

  /// Parses note models from the database to determine front/back field indices.
  ///
  /// Returns a map of model ID -> [_NoteModelInfo].
  /// Uses field names to identify content fields vs. sort/index fields.
  static Map<int, _NoteModelInfo> _parseNoteModels(
    Database db,
    List<String> tables,
  ) {
    final result = <int, _NoteModelInfo>{};

    try {
      // In Anki's schema, models are stored as JSON in the `col` table
      if (!tables.contains('col')) return result;

      final colRows = db.select('SELECT models FROM col');
      if (colRows.isEmpty) return result;

      final modelsJson = colRows.first['models'] as String?;
      if (modelsJson == null) return result;

      final models = json.decode(modelsJson);
      if (models is! Map) return result;

      for (final entry in models.entries) {
        final modelId = int.tryParse(entry.key.toString());
        if (modelId == null) continue;

        final model = entry.value;
        if (model is! Map) continue;

        final flds = model['flds'];
        if (flds is! List) continue;

        final fieldNames = <String>[];
        for (final f in flds) {
          if (f is Map && f['name'] is String) {
            fieldNames.add((f['name'] as String).toLowerCase().trim());
          }
        }

        if (fieldNames.isEmpty) continue;

        debugPrint(
          '[AnkiService] Model $modelId '
          '(${model['name'] ?? 'unnamed'}): '
          'fields=${fieldNames.join(", ")}',
        );

        final indices = _pickFrontBackIndices(fieldNames);
        result[modelId] = _NoteModelInfo(
          frontIndex: indices.$1,
          backIndex: indices.$2,
          fieldNames: fieldNames,
        );
      }
    } catch (e) {
      debugPrint('[AnkiService] Failed to parse models: $e');
    }

    return result;
  }

  /// Field name patterns that indicate a sort/index field (not content).
  static final _sortFieldPatterns = RegExp(
    r'^(#|number|index|sort|order|seq|id|no\.?|nr\.?|pos)$',
    caseSensitive: false,
  );

  /// Field name patterns that indicate a "question" / front-side field.
  static final _frontFieldPatterns = RegExp(
    r'(expression|kanji|vocab|word|question|front|japanese|prompt|term|'
    r'hanzi|character|sentence|phrase)',
    caseSensitive: false,
  );

  /// Field name patterns that indicate an "answer" / back-side field.
  static final _backFieldPatterns = RegExp(
    r'(meaning|english|answer|back|definition|translation|reading|'
    r'glossary|gloss|response)',
    caseSensitive: false,
  );

  /// Picks the best front and back field indices based on field names.
  ///
  /// Skips fields that look like sort/index numbers and tries to match
  /// common Anki field naming conventions for language decks.
  static (int, int) _pickFrontBackIndices(List<String> fieldNames) {
    int? frontIdx;
    int? backIdx;

    // First pass: try to match known patterns
    for (int i = 0; i < fieldNames.length; i++) {
      final name = fieldNames[i];

      if (_sortFieldPatterns.hasMatch(name)) continue;

      if (frontIdx == null && _frontFieldPatterns.hasMatch(name)) {
        frontIdx = i;
      } else if (backIdx == null && _backFieldPatterns.hasMatch(name)) {
        backIdx = i;
      }
    }

    // Second pass: fill in missing indices with first non-sort fields
    if (frontIdx == null || backIdx == null) {
      for (int i = 0; i < fieldNames.length; i++) {
        if (i == frontIdx || i == backIdx) continue;
        if (_sortFieldPatterns.hasMatch(fieldNames[i])) continue;

        if (frontIdx == null) {
          frontIdx = i;
        } else if (backIdx == null) {
          backIdx = i;
          break;
        }
      }
    }

    return (frontIdx ?? 0, backIdx ?? (frontIdx == 0 ? 1 : 0));
  }

  /// Opens the flashcards folder in the system file explorer.
  static Future<void> openFlashcardsFolder() async {
    final flashcardsDir = await getFlashcardsDirectory();

    if (Platform.isWindows) {
      await Process.run('explorer', [flashcardsDir.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [flashcardsDir.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [flashcardsDir.path]);
    }
  }

  /// Deletes a deck file from the flashcards directory.
  ///
  /// Returns true if the file was successfully deleted, false otherwise.
  static Future<bool> deleteDeck(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Formats a file name into a human-readable deck name.
  ///
  /// Example: "japanese_core_2000.apkg" -> "Japanese Core 2000"
  static String _formatDeckName(String fileName) {
    // Remove .apkg extension
    var name =
        fileName.replaceAll(RegExp(r'\.apkg$', caseSensitive: false), '');
    // Replace underscores and hyphens with spaces
    name = name.replaceAll(RegExp(r'[_-]'), ' ');
    // Capitalize each word
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

/// Information about an Anki deck file.
class AnkiDeckInfo {
  /// Human-readable display name for the deck.
  final String name;

  /// Full path to the APKG file.
  final String path;

  /// Original file name.
  final String fileName;

  const AnkiDeckInfo({
    required this.name,
    required this.path,
    required this.fileName,
  });
}

/// Result of parsing an APKG file, containing cards and media info.
class AnkiDeckData {
  /// The parsed flashcards.
  final List<AnkiCard> cards;

  /// Path to the APKG file for on-demand media extraction.
  final String? apkgPath;

  /// Media map from the APKG (archive index -> original filename).
  /// Used for lazy audio extraction.
  final Map<String, String> mediaMap;

  const AnkiDeckData({
    required this.cards,
    this.apkgPath,
    this.mediaMap = const {},
  });
}

/// Internal model info parsed from the Anki `col.models` JSON.
class _NoteModelInfo {
  final int frontIndex;
  final int backIndex;
  final List<String> fieldNames;

  const _NoteModelInfo({
    required this.frontIndex,
    required this.backIndex,
    required this.fieldNames,
  });
}
