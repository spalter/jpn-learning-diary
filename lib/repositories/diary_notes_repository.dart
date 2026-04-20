// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:jpn_learning_diary/models/diary_note.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';

/// Repository for diary notes operations.
class DiaryNotesRepository {
  final DatabaseHelper _databaseHelper;

  /// Creates a repository with the given database helper.
  DiaryNotesRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Creates a new diary note.
  Future<DiaryNote> createNote(DiaryNote note) async {
    return await _databaseHelper.createNote(note);
  }

  /// Retrieves all diary notes.
  Future<List<DiaryNote>> getAllNotes() async {
    return await _databaseHelper.getAllNotes();
  }

  /// Searches for diary notes matching the query.
  Future<List<DiaryNote>> searchNotes(String query) async {
    final allNotes = await getAllNotes();
    final normalizedQuery = JapaneseTextUtils.normalizeForSearch(query);

    if (normalizedQuery.isEmpty) return [];

    return allNotes.where((note) {
      final matchesJapanese = JapaneseTextUtils.normalizeForSearch(
        JapaneseTextUtils.stripRubyPatterns(note.contentJapanese),
      ).contains(normalizedQuery);

      final matchesTitle = JapaneseTextUtils.normalizeForSearch(
        note.title,
      ).contains(normalizedQuery);

      final matchesEnglish = JapaneseTextUtils.normalizeForSearch(
        note.contentEnglish,
      ).contains(normalizedQuery);

      final matchesTags =
          note.tags != null &&
          JapaneseTextUtils.normalizeForSearch(
            note.tags!,
          ).contains(normalizedQuery);

      return matchesJapanese || matchesTitle || matchesEnglish || matchesTags;
    }).toList();
  }

  /// Updates an existing diary note.
  Future<int> updateNote(DiaryNote note) async {
    if (note.id == null) {
      throw ArgumentError('Cannot update note without an ID');
    }
    return await _databaseHelper.updateNote(note);
  }

  /// Deletes a diary note by ID.
  Future<int> deleteNote(int id) async {
    return await _databaseHelper.deleteNote(id);
  }

  /// Deletes all diary notes.
  Future<int> deleteAllNotes() async {
    return await _databaseHelper.deleteAllNotes();
  }
}
