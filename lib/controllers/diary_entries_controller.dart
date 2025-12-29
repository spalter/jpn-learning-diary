import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';

/// Controller for the diary entries list page.
///
/// Manages business logic for:
/// - Loading diary entries
/// - Creating new entries
/// - Updating existing entries
/// - Deleting entries
/// - Refreshing the list
///
/// Keeps the PhrasesWordsPage widget focused purely on presentation.
class DiaryEntriesController extends ChangeNotifier {
  final DiaryRepository _repository;

  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  DiaryEntriesController({DiaryRepository? repository})
      : _repository = repository ?? DiaryRepository();

  /// Current list of diary entries.
  List<DiaryEntry> get entries => _entries;

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Error message if loading failed, null otherwise.
  String? get errorMessage => _errorMessage;

  /// Whether entries have been loaded successfully.
  bool get hasEntries => _entries.isNotEmpty && _errorMessage == null;

  /// Whether the list is empty (no entries).
  bool get isEmpty => _entries.isEmpty && !_isLoading && _errorMessage == null;

  /// Total count of entries.
  int get entryCount => _entries.length;

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

  /// Creates a new diary entry.
  ///
  /// Returns the created entry with its generated ID, or null if creation failed.
  Future<DiaryEntry?> createEntry(DiaryEntry entry) async {
    try {
      final createdEntry = await _repository.createEntry(entry);
      await loadEntries(); // Reload to get updated list
      return createdEntry;
    } catch (e) {
      _errorMessage = 'Failed to create entry: $e';
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing diary entry.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> updateEntry(DiaryEntry entry) async {
    try {
      await _repository.updateEntry(entry);
      await loadEntries(); // Reload to get updated list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update entry: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a diary entry by ID.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> deleteEntry(int id) async {
    try {
      await _repository.deleteEntry(id);
      await loadEntries(); // Reload to get updated list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete entry: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes all diary entries.
  ///
  /// USE WITH CAUTION: This permanently removes all entries.
  /// Returns true if successful, false otherwise.
  Future<bool> deleteAllEntries() async {
    try {
      await _repository.deleteAllEntries();
      await loadEntries(); // Reload to get updated (empty) list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete all entries: $e';
      notifyListeners();
      return false;
    }
  }

  /// Refreshes the entries list.
  Future<void> refresh() => loadEntries();

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Gets entries added within the last [days] days.
  List<DiaryEntry> getRecentEntries({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _entries.where((entry) => entry.dateAdded.isAfter(cutoffDate)).toList();
  }

  /// Searches entries by query text.
  ///
  /// Searches across: japanese, furigana, romaji, meaning, and notes.
  List<DiaryEntry> searchEntries(String query) {
    if (query.trim().isEmpty) {
      return _entries;
    }

    final lowerQuery = query.toLowerCase();
    return _entries.where((entry) {
      return entry.japanese.toLowerCase().contains(lowerQuery) ||
          (entry.furigana?.toLowerCase().contains(lowerQuery) ?? false) ||
          entry.romaji.toLowerCase().contains(lowerQuery) ||
          entry.meaning.toLowerCase().contains(lowerQuery) ||
          (entry.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
