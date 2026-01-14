import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';

/// Repository for diary entry operations.
///
/// Provides a clean abstraction over data access for diary entries.
/// This layer separates business logic from data source implementation,
/// making it easier to:
/// - Test business logic by mocking repositories
/// - Switch data sources (e.g., from local database to API)
/// - Apply caching strategies
/// - Handle data transformation consistently
class DiaryRepository {
  final DatabaseHelper _databaseHelper;

  /// Creates a repository with the given database helper.
  ///
  /// In production, typically uses [DatabaseHelper.instance].
  /// For testing, can inject a mock database helper.
  DiaryRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Creates a new diary entry.
  ///
  /// Returns the created entry with its generated ID.
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    return await _databaseHelper.createEntry(entry);
  }

  /// Retrieves all diary entries.
  ///
  /// Entries are ordered by date added (newest first).
  Future<List<DiaryEntry>> getAllEntries() async {
    return await _databaseHelper.getAllEntries();
  }

  /// Updates an existing diary entry.
  ///
  /// Returns the number of rows affected (should be 1 on success).
  Future<int> updateEntry(DiaryEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError('Cannot update entry without an ID');
    }
    return await _databaseHelper.updateEntry(entry);
  }

  /// Deletes a diary entry by ID.
  ///
  /// Returns the number of rows affected (should be 1 on success).
  Future<int> deleteEntry(int id) async {
    return await _databaseHelper.deleteEntry(id);
  }

  /// Deletes all diary entries.
  ///
  /// USE WITH CAUTION: This permanently removes all entries.
  /// Returns the number of rows deleted.
  Future<int> deleteAllEntries() async {
    return await _databaseHelper.deleteAllEntries();
  }
}
