// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/diary_item.dart';
import 'package:jpn_learning_diary/models/diary_note.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/diary_notes_repository.dart';

/// Controller for the diary items list page.
class DiaryEntriesController extends ChangeNotifier {
  final DiaryRepository _repository;
  final DiaryNotesRepository _notesRepository;

  List<DiaryItem> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  DiaryEntriesController({
    DiaryRepository? repository,
    DiaryNotesRepository? notesRepository,
  }) : _repository = repository ?? DiaryRepository(),
       _notesRepository = notesRepository ?? DiaryNotesRepository();

  /// Current list of diary entries.
  List<DiaryItem> get entries => List.unmodifiable(_entries);

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Error message if loading failed, null otherwise.
  String? get errorMessage => _errorMessage;

  /// Whether the list is empty (no entries).
  bool get isEmpty => _entries.isEmpty && !_isLoading && _errorMessage == null;

  /// Loads all diary items (entries and notes) from the repositories.
  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Future<List<DiaryEntry>> entriesFuture = _repository
          .getAllEntries();
      final Future<List<DiaryNote>> notesFuture = _notesRepository
          .getAllNotes();

      final results = await Future.wait([entriesFuture, notesFuture]);
      final entriesList = results[0] as List<DiaryEntry>;
      final notesList = results[1] as List<DiaryNote>;

      _entries = [...entriesList, ...notesList]
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); // descending

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load entries: $e';
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the entries list.
  Future<void> refresh() => loadEntries();

  /// Updates a single item in the list without reloading everything.
  ///
  /// Finds the item by ID and type, and replaces it with the updated version.
  void updateEntry(DiaryItem updatedItem) {
    final index = _entries.indexWhere(
      (e) => e.id == updatedItem.id && e.runtimeType == updatedItem.runtimeType,
    );
    if (index != -1) {
      // We will sort again to ensure order is still correct if date changed, though typically it doesn't.
      _entries[index] = updatedItem;
      _entries.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      notifyListeners();
    }
  }

  /// Adds a new item to the list.
  void addEntry(DiaryItem newItem) {
    _entries.insert(0, newItem);
    _entries.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    notifyListeners();
  }

  /// Removes an item from the list by ID and type.
  void removeEntry(int entryId, Type itemType) {
    _entries.removeWhere((e) => e.id == entryId && e.runtimeType == itemType);
    notifyListeners();
  }
}
