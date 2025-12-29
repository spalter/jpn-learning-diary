import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';

/// Data class holding dashboard statistics.
class DashboardData {
  final int totalEntries;
  final int totalKanji;
  final Map<int?, int> kanjiByJlptLevel;

  const DashboardData({
    required this.totalEntries,
    required this.kanjiByJlptLevel,
  }) : totalKanji = 0;

  DashboardData.withKanjiCount({
    required this.totalEntries,
    required this.kanjiByJlptLevel,
    required this.totalKanji,
  });

  /// Creates a copy with updated values.
  DashboardData copyWith({
    int? totalEntries,
    int? totalKanji,
    Map<int?, int>? kanjiByJlptLevel,
  }) {
    return DashboardData.withKanjiCount(
      totalEntries: totalEntries ?? this.totalEntries,
      totalKanji: totalKanji ?? this.totalKanji,
      kanjiByJlptLevel: kanjiByJlptLevel ?? this.kanjiByJlptLevel,
    );
  }
}

/// Controller for the learning dashboard/overview page.
///
/// Manages business logic for:
/// - Loading dashboard statistics
/// - Calculating kanji counts
/// - Refreshing data
///
/// Keeps the LearningPage widget focused purely on presentation.
class LearningController extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final KanjiRepository _kanjiRepository;

  DashboardData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  LearningController({
    DiaryRepository? diaryRepository,
    KanjiRepository? kanjiRepository,
  })  : _diaryRepository = diaryRepository ?? DiaryRepository(),
        _kanjiRepository = kanjiRepository ?? KanjiRepository();

  /// Current dashboard data, null if not loaded yet.
  DashboardData? get data => _data;

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Error message if loading failed, null otherwise.
  String? get errorMessage => _errorMessage;

  /// Whether data has been loaded successfully.
  bool get hasData => _data != null && _errorMessage == null;

  /// Loads dashboard statistics from repositories.
  ///
  /// Fetches:
  /// - Total diary entries count
  /// - Unique kanji count by JLPT level
  /// - Total unique kanji count
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final entries = await _diaryRepository.getAllEntries();
      final jlptStats = await _kanjiRepository.getLearnedKanjiByJlptLevel();
      
      // Calculate total kanji count from JLPT stats
      final totalKanji = jlptStats.values.fold<int>(0, (sum, count) => sum + count);

      _data = DashboardData.withKanjiCount(
        totalEntries: entries.length,
        kanjiByJlptLevel: jlptStats,
        totalKanji: totalKanji,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      _data = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the dashboard data.
  Future<void> refresh() => loadData();

  /// Gets the count of kanji for a specific JLPT level.
  int getKanjiCountForLevel(int level) {
    return _data?.kanjiByJlptLevel[level] ?? 0;
  }

  /// Gets the total count of all kanji.
  int get totalKanjiCount => _data?.totalKanji ?? 0;

  /// Gets the total count of diary entries.
  int get totalEntriesCount => _data?.totalEntries ?? 0;
}
