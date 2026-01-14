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
}
