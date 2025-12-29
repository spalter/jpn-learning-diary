import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';

/// Practice mode types for different learning scenarios.
enum PracticeMode {
  diaryEntries('Diary Entries', 'Practice words and phrases from your diary'),
  kanji('Kanji', 'Practice kanji characters and their meanings');

  const PracticeMode(this.label, this.description);
  final String label;
  final String description;
}

/// Abstract practice item that can represent different types of content.
class PracticeItem {
  final String prompt;
  final String correctAnswer;
  final String? furigana;
  final PracticeMode mode;

  PracticeItem({
    required this.prompt,
    required this.correctAnswer,
    this.furigana,
    required this.mode,
  });

  factory PracticeItem.fromDiaryEntry(DiaryEntry entry) {
    return PracticeItem(
      prompt: entry.meaning,
      correctAnswer: entry.japanese,
      furigana: entry.furigana,
      mode: PracticeMode.diaryEntries,
    );
  }

  factory PracticeItem.fromKanji(KanjiData kanji) {
    return PracticeItem(
      prompt: kanji.meanings,
      correctAnswer: kanji.kanji,
      furigana: kanji.readingsKun.isNotEmpty
          ? kanji.readingsKun.split(',').first.trim()
          : kanji.readingsOn.split(',').first.trim(),
      mode: PracticeMode.kanji,
    );
  }
}

/// Controller for practice mode logic.
///
/// Manages business logic for:
/// - Loading practice items
/// - Checking answers
/// - Tracking progress
/// - Managing question flow
///
/// Keeps the PracticeModePage widget focused purely on presentation.
class PracticeController extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final KanjiRepository _kanjiRepository;
  final PracticeMode mode;

  List<PracticeItem> _items = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Answer state
  bool _showCorrectAnswer = false;
  bool _isCorrect = false;
  int _correctCount = 0;
  bool _hasAttemptedCurrentQuestion = false;
  bool _isCompleted = false;

  PracticeController({
    required this.mode,
    DiaryRepository? diaryRepository,
    KanjiRepository? kanjiRepository,
  })  : _diaryRepository = diaryRepository ?? DiaryRepository(),
        _kanjiRepository = kanjiRepository ?? KanjiRepository();

  // Getters
  List<PracticeItem> get items => _items;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showCorrectAnswer => _showCorrectAnswer;
  bool get isCorrect => _isCorrect;
  int get correctCount => _correctCount;
  bool get hasAttemptedCurrentQuestion => _hasAttemptedCurrentQuestion;
  bool get isCompleted => _isCompleted;
  bool get hasItems => _items.isNotEmpty;
  
  PracticeItem? get currentItem =>
      _items.isEmpty || _currentIndex >= _items.length ? null : _items[_currentIndex];
  
  int get totalItems => _items.length;
  int get currentQuestionNumber => _currentIndex + 1;
  double get progressPercentage =>
      _items.isEmpty ? 0.0 : (_currentIndex / _items.length);
  double get scorePercentage =>
      _items.isEmpty ? 0.0 : (_correctCount / _items.length) * 100;

  /// Loads practice items based on the selected mode.
  Future<void> loadItems({int count = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<PracticeItem> items = [];

      switch (mode) {
        case PracticeMode.diaryEntries:
          final allEntries = await _diaryRepository.getAllEntries();
          if (allEntries.isNotEmpty) {
            final random = Random();
            final shuffled = List<DiaryEntry>.from(allEntries)..shuffle(random);
            items = shuffled
                .take(count)
                .map((e) => PracticeItem.fromDiaryEntry(e))
                .toList();
          }
          break;

        case PracticeMode.kanji:
          final kanjiList = await _kanjiRepository.getRandomKanjiFromDiary(
            count: count,
          );
          items = kanjiList.map((k) => PracticeItem.fromKanji(k)).toList();
          break;
      }

      _items = items;
      _currentIndex = 0;
      _correctCount = 0;
      _isCompleted = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load practice items: $e';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks if the user's answer is correct.
  ///
  /// Returns true if correct, false otherwise.
  bool checkAnswer(String userAnswer) {
    if (_items.isEmpty || _currentIndex >= _items.length) {
      return false;
    }

    final currentItem = _items[_currentIndex];
    final isAnswerCorrect =
        userAnswer.trim() == currentItem.correctAnswer.trim();

    _isCorrect = isAnswerCorrect;

    if (isAnswerCorrect) {
      // Only count as correct if this is the first attempt
      if (!_hasAttemptedCurrentQuestion) {
        _correctCount++;
      }
      _showCorrectAnswer = false;
    } else {
      _showCorrectAnswer = true;
    }

    _hasAttemptedCurrentQuestion = true;
    notifyListeners();

    return isAnswerCorrect;
  }

  /// Advances to the next question.
  void nextQuestion() {
    if (_currentIndex < _items.length - 1) {
      _currentIndex++;
      _showCorrectAnswer = false;
      _isCorrect = false;
      _hasAttemptedCurrentQuestion = false;
      notifyListeners();
    } else {
      // Reached the end
      _isCompleted = true;
      notifyListeners();
    }
  }

  /// Resets the current question state (for retry).
  void resetCurrentQuestion() {
    _showCorrectAnswer = false;
    _isCorrect = false;
    notifyListeners();
  }

  /// Restarts the practice session with new items.
  Future<void> restart() async {
    _currentIndex = 0;
    _correctCount = 0;
    _isCompleted = false;
    _showCorrectAnswer = false;
    _isCorrect = false;
    _hasAttemptedCurrentQuestion = false;
    notifyListeners();
    await loadItems();
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
