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
import 'package:jpn_learning_diary/repositories/diary_repository.dart';

/// Controller for the diary entries list page.
class DiaryEntriesController extends ChangeNotifier {
  final DiaryRepository _repository;

  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  DiaryEntriesController({DiaryRepository? repository})
    : _repository = repository ?? DiaryRepository();

  /// Current list of diary entries.
  List<DiaryEntry> get entries => List.unmodifiable(_entries);

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Error message if loading failed, null otherwise.
  String? get errorMessage => _errorMessage;

  /// Whether the list is empty (no entries).
  bool get isEmpty => _entries.isEmpty && !_isLoading && _errorMessage == null;

  /// Loads all diary entries from the repository.
  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _repository.getAllEntries();
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

  /// Updates a single entry in the list without reloading everything.
  ///
  /// Finds the entry by ID and replaces it with the updated version.
  /// This preserves scroll position by only notifying of the change.
  void updateEntry(DiaryEntry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      notifyListeners();
    }
  }

  /// Adds a new entry to the beginning of the list.
  ///
  /// Used after creating a new entry to avoid full list reload.
  void addEntry(DiaryEntry newEntry) {
    _entries.insert(0, newEntry);
    notifyListeners();
  }

  /// Removes an entry from the list by ID.
  ///
  /// Used after deleting an entry to avoid full list reload.
  void removeEntry(int entryId) {
    _entries.removeWhere((e) => e.id == entryId);
    notifyListeners();
  }
}
