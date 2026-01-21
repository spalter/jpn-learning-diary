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
import 'package:jpn_learning_diary/models/custom_quiz_entry.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for loading and managing custom quiz data from CSV files.
///
/// This service handles parsing CSV files containing custom quiz questions.
/// Supports two formats:
/// - 5 columns: id;question;correct answer;wrong answer 1;wrong answer 2;wrong answer 3
/// - 2 columns: id;question;correct answer (wrong answers randomly selected from other entries)
class CustomQuizService {
  CustomQuizService._();

  /// CSV template header for users to create their own quiz files.
  /// Supports both 5-column format (with predefined wrong answers) and
  /// 2-column format (with random wrong answers from other entries).
  static const String csvTemplate =
      '''id;question;correct answer;wrong answer 1;wrong answer 2;wrong answer 3
1;What is the capital of Japan?;Tokyo;Osaka;Kyoto;Nagoya
2;How do you say "hello" in Japanese?;こんにちは;さようなら;ありがとう;すみません
3;What is the Japanese word for "cat"?;猫 (neko);犬 (inu);鳥 (tori);魚 (sakana)

Alternatively, use 2-column format (id;question;correct answer):
Wrong answers will be randomly selected from other entries.
Requires at least 4 entries for random selection.

1;What is the capital of Japan?;Tokyo
2;How do you say "hello" in Japanese?;こんにちは
3;What is the Japanese word for "cat"?;猫 (neko)
4;What is the Japanese word for "dog"?;犬 (inu)''';

  /// Returns the CSV template string that users can use as a starting point.
  static String getTemplate() => csvTemplate;

  /// Loads custom quiz entries from a bundled asset file.
  ///
  /// [assetPath] - The path to the CSV file in the assets folder
  /// Returns a list of [CustomQuizEntry] objects parsed from the file.
  static Future<List<CustomQuizEntry>> loadFromAsset(String assetPath) async {
    try {
      final csvContent = await rootBundle.loadString(assetPath);
      return _parseCSV(csvContent);
    } catch (e) {
      throw Exception('Failed to load quiz from asset: $e');
    }
  }

  /// Loads custom quiz entries from a raw CSV string.
  ///
  /// [csvContent] - The raw CSV content to parse
  /// Returns a list of [CustomQuizEntry] objects parsed from the content.
  static List<CustomQuizEntry> loadFromString(String csvContent) {
    return _parseCSV(csvContent);
  }

  /// Parses CSV content into a list of CustomQuizEntry objects.
  ///
  /// Skips the header row and any empty lines.
  /// Throws [FormatException] if any row is malformed.
  static List<CustomQuizEntry> _parseCSV(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return [];
    }

    // Skip header row (first line)
    final dataLines = lines.skip(1).toList();

    final entries = <CustomQuizEntry>[];
    for (int i = 0; i < dataLines.length; i++) {
      try {
        entries.add(CustomQuizEntry.fromCsvRow(dataLines[i]));
      } catch (e) {
        throw FormatException('Error parsing row ${i + 2}: $e');
      }
    }

    return entries;
  }

  /// Validates CSV content and returns any errors found.
  ///
  /// Returns a list of error messages, empty if the content is valid.
  /// Supports both 5-column format (with wrong answers) and 2-column format (question and answer only).
  static List<String> validateCSV(String csvContent) {
    final errors = <String>[];
    final lines = csvContent
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      errors.add('CSV file is empty');
      return errors;
    }

    // Check header
    final header = lines.first.toLowerCase();
    if (!header.contains('id') || !header.contains('question')) {
      errors.add('Missing or invalid header row');
    }

    // Validate data rows
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(';');
      
      // Must be either 3 fields (id;question;answer) or 6 fields (with 3 wrong answers)
      if (parts.length < 3) {
        errors.add('Row ${i + 1}: Expected at least 3 fields (id;question;answer), found ${parts.length}');
        continue;
      }
      
      if (parts.length != 3 && parts.length < 6) {
        errors.add('Row ${i + 1}: Expected 3 fields or 6 fields, found ${parts.length}');
        continue;
      }

      if (int.tryParse(parts[0].trim()) == null) {
        errors.add('Row ${i + 1}: Invalid ID "${parts[0]}"');
      }

      if (parts[1].trim().isEmpty) {
        errors.add('Row ${i + 1}: Question cannot be empty');
      }

      if (parts[2].trim().isEmpty) {
        errors.add('Row ${i + 1}: Correct answer cannot be empty');
      }
    }

    return errors;
  }

  /// The name of the app folder in Documents.
  static const String _appFolderName = 'JPN Learning Diary';

  /// The name of the quizzes subfolder.
  static const String _quizzesFolderName = 'quizzes';

  /// List of bundled quiz assets to copy on first run.
  static const List<String> _bundledQuizzes = [
    'assets/quizzes/template.csv',
  ];

  /// Gets the path to the quizzes directory in Documents.
  ///
  /// Creates the directory structure if it doesn't exist.
  static Future<Directory> getQuizzesDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final quizzesDir = Directory(
      path.join(documentsDir.path, _appFolderName, _quizzesFolderName),
    );

    if (!await quizzesDir.exists()) {
      await quizzesDir.create(recursive: true);
    }

    return quizzesDir;
  }

  /// Initializes the quizzes folder with bundled samples if needed.
  ///
  /// This should be called on app startup. It copies bundled quiz files
  /// to the user's Documents folder if they don't already exist.
  static Future<void> initializeQuizzesFolder() async {
    final quizzesDir = await getQuizzesDirectory();

    for (final assetPath in _bundledQuizzes) {
      final fileName = path.basename(assetPath);
      final targetFile = File(path.join(quizzesDir.path, fileName));

      // Only copy if the file doesn't exist (don't overwrite user changes)
      if (!await targetFile.exists()) {
        try {
          final content = await rootBundle.loadString(assetPath);
          await targetFile.writeAsString(content);
        } catch (e) {
          // Asset might not exist, skip silently
          continue;
        }
      }
    }
  }

  /// Lists all available quiz files in the quizzes directory.
  ///
  /// Returns a list of [QuizFileInfo] with file name and path.
  static Future<List<QuizFileInfo>> listAvailableQuizzes() async {
    final quizzesDir = await getQuizzesDirectory();
    final quizFiles = <QuizFileInfo>[];

    await for (final entity in quizzesDir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.csv')) {
        final fileName = path.basename(entity.path);
        // Skip template file from the list
        if (fileName.toLowerCase() != 'template.csv') {
          quizFiles.add(
            QuizFileInfo(
              name: _formatQuizName(fileName),
              path: entity.path,
              fileName: fileName,
            ),
          );
        }
      }
    }

    // Sort alphabetically by display name
    quizFiles.sort((a, b) => a.name.compareTo(b.name));
    return quizFiles;
  }

  /// Loads quiz entries from a file in the quizzes directory.
  static Future<List<CustomQuizEntry>> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      return _parseCSV(content);
    } catch (e) {
      throw Exception('Failed to load quiz from file: $e');
    }
  }

  /// Opens the quizzes folder in the system file explorer.
  static Future<void> openQuizzesFolder() async {
    final quizzesDir = await getQuizzesDirectory();

    if (Platform.isWindows) {
      await Process.run('explorer', [quizzesDir.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [quizzesDir.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [quizzesDir.path]);
    }
  }

  /// Deletes a quiz file from the quizzes directory.
  ///
  /// Returns true if the file was successfully deleted, false otherwise.
  static Future<bool> deleteQuiz(String filePath) async {
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

  /// Formats a file name into a human-readable quiz name.
  ///
  /// Example: "sample_japanese_basics.csv" -> "Sample Japanese Basics"
  static String _formatQuizName(String fileName) {
    // Remove .csv extension
    var name = fileName.replaceAll(RegExp(r'\.csv$', caseSensitive: false), '');
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

/// Information about a quiz file.
class QuizFileInfo {
  /// Human-readable display name for the quiz.
  final String name;

  /// Full path to the quiz file.
  final String path;

  /// Original file name.
  final String fileName;

  const QuizFileInfo({
    required this.name,
    required this.path,
    required this.fileName,
  });
}
