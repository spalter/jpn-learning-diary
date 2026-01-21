// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/models/custom_quiz_entry.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/custom_quiz_service.dart';

/// Represents a single custom quiz question with shuffled answer options.
class CustomQuizQuestion {
  /// The question text shown to the user.
  final String prompt;

  /// The correct answer.
  final String correctAnswer;

  /// List of all answer options (shuffled, includes correct answer).
  final List<String> answerOptions;

  /// The index of the correct answer in [answerOptions].
  final int correctAnswerIndex;

  /// The original quiz entry this question was created from.
  final CustomQuizEntry entry;

  CustomQuizQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.answerOptions,
    required this.correctAnswerIndex,
    required this.entry,
  });

  /// Creates a quiz question from a CustomQuizEntry with shuffled answers.
  ///
  /// If [entry] has predefined answers, uses those.
  /// If [entry] only has a correct answer, randomly selects 3 wrong answers
  /// from [allEntries] (excluding the current entry).
  factory CustomQuizQuestion.fromEntry(
    CustomQuizEntry entry, {
    List<CustomQuizEntry>? allEntries,
  }) {
    final random = Random();
    List<String> allAnswers;

    // Use predefined answers if available
    if (entry.hasPredefinedAnswers) {
      allAnswers = List<String>.from(entry.allAnswers!)..shuffle(random);
    } else {
      // Generate random wrong answers from other entries
      if (allEntries == null || allEntries.length < 4) {
        throw ArgumentError(
          'Need at least 4 total entries to generate random answers',
        );
      }

      // Get all possible answers from other entries (excluding this one)
      final otherAnswers = allEntries
          .where((e) => e.id != entry.id)
          .map((e) => e.correctAnswer)
          .toList();

      if (otherAnswers.length < 3) {
        throw ArgumentError(
          'Need at least 3 other entries to generate random wrong answers',
        );
      }

      // Shuffle and take 3 random wrong answers
      otherAnswers.shuffle(random);
      final wrongAnswers = otherAnswers.take(3).toList();

      // Combine and shuffle all answers
      allAnswers = [entry.correctAnswer, ...wrongAnswers]..shuffle(random);
    }

    return CustomQuizQuestion(
      prompt: entry.question,
      correctAnswer: entry.correctAnswer,
      answerOptions: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(entry.correctAnswer),
      entry: entry,
    );
  }
}

/// Controller for the custom CSV-based quiz mode.
///
/// Manages quiz state including loading questions from CSV data,
/// tracking answers, scoring, and navigation between questions.
class CustomQuizController extends ChangeNotifier {
  /// The list of quiz questions for the current session.
  List<CustomQuizQuestion> _questions = [];

  /// Index of the currently displayed question (0-based).
  int _currentIndex = 0;

  /// The index of the answer the user selected, or -1 if none.
  int _selectedAnswerIndex = -1;

  /// Whether the user has answered the current question.
  bool _hasAnswered = false;

  /// Count of questions answered correctly.
  int _correctCount = 0;

  /// Whether the quiz session has been completed.
  bool _isCompleted = false;

  /// Loading state.
  bool _isLoading = false;

  /// Error message if loading failed.
  String? _errorMessage;

  /// The raw CSV entries loaded (for restarting).
  List<CustomQuizEntry> _loadedEntries = [];

  /// The source name/path of the loaded quiz.
  String _sourceName = '';

  // Getters
  List<CustomQuizQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get selectedAnswerIndex => _selectedAnswerIndex;
  bool get hasAnswered => _hasAnswered;
  int get correctCount => _correctCount;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get sourceName => _sourceName;

  /// Whether there are enough questions to run a quiz.
  bool get hasQuestions => _questions.isNotEmpty;

  /// The current question being displayed, or null if none.
  CustomQuizQuestion? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
      ? _questions[_currentIndex]
      : null;

  /// Total number of questions in the quiz.
  int get totalQuestions => _questions.length;

  /// Whether the current question is the last one.
  bool get isLastQuestion => _currentIndex >= _questions.length - 1;

  /// The percentage score (0-100).
  int get percentageScore => _questions.isEmpty
      ? 0
      : (_correctCount / _questions.length * 100).round();

  /// Loads quiz questions from a bundled asset file.
  ///
  /// [assetPath] - Path to the CSV file in assets
  Future<void> loadFromAsset(String assetPath) async {
    _isLoading = true;
    _errorMessage = null;
    _sourceName = assetPath.split('/').last;
    notifyListeners();

    try {
      final entries = await CustomQuizService.loadFromAsset(assetPath);
      await _processEntries(entries);
    } catch (e) {
      _errorMessage = 'Failed to load quiz: $e';
      _questions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads quiz questions from a file path in the quizzes directory.
  ///
  /// [filePath] - Full path to the CSV file
  /// [sourceName] - A display name for the quiz
  Future<void> loadFromFile(String filePath, {String? sourceName}) async {
    _isLoading = true;
    _errorMessage = null;
    _sourceName = sourceName ?? filePath.split('/').last.split('\\').last;
    notifyListeners();

    try {
      final entries = await CustomQuizService.loadFromFile(filePath);
      await _processEntries(entries);
    } catch (e) {
      _errorMessage = 'Failed to load quiz: $e';
      _questions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads quiz questions from a raw CSV string.
  ///
  /// [csvContent] - The CSV content to parse
  /// [sourceName] - A display name for the quiz source
  Future<void> loadFromString(
    String csvContent, {
    String sourceName = 'Custom Quiz',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _sourceName = sourceName;
    notifyListeners();

    try {
      final entries = CustomQuizService.loadFromString(csvContent);
      await _processEntries(entries);
    } catch (e) {
      _errorMessage = 'Failed to parse quiz: $e';
      _questions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Processes loaded entries into quiz questions.
  Future<void> _processEntries(List<CustomQuizEntry> entries) async {
    _loadedEntries = entries;

    if (entries.length < 4) {
      _errorMessage = 'Not enough questions. Need at least 4 entries.';
      _questions = [];
      return;
    }

    final random = Random();
    final maxQuestions = await AppPreferences.getQuizQuestionCount();

    // Shuffle and take up to the configured question count
    final shuffled = List<CustomQuizEntry>.from(entries)..shuffle(random);
    final selectedEntries = shuffled
        .take(min(maxQuestions, entries.length))
        .toList();

    _questions = selectedEntries
        .map(
          (entry) => CustomQuizQuestion.fromEntry(
            entry,
            allEntries:
                entries, // Pass all entries for random answer generation
          ),
        )
        .toList();

    _resetQuizState();
  }

  /// Resets quiz state for a new session.
  void _resetQuizState() {
    _currentIndex = 0;
    _selectedAnswerIndex = -1;
    _hasAnswered = false;
    _correctCount = 0;
    _isCompleted = false;
  }

  /// Whether the last committed answer was correct.
  bool _lastAnswerCorrect = false;

  /// Whether the last committed answer was correct.
  bool get lastAnswerCorrect => _lastAnswerCorrect;

  /// Whether an answer is currently selected (but not yet committed).
  bool get hasSelection => _selectedAnswerIndex >= 0;

  /// Handles when the user selects an answer option.
  ///
  /// This only selects the answer visually without committing it.
  /// The user must call [commitAnswer] to finalize their choice.
  void selectAnswer(int index) {
    if (_hasAnswered || currentQuestion == null) return;

    _selectedAnswerIndex = index;
    notifyListeners();
  }

  /// Commits the currently selected answer.
  ///
  /// This finalizes the user's choice:
  /// - Marks the question as answered
  /// - Checks if the answer is correct
  /// - Increments correct count if correct
  void commitAnswer() {
    if (_hasAnswered || _selectedAnswerIndex < 0 || currentQuestion == null) {
      return;
    }

    _lastAnswerCorrect =
        _selectedAnswerIndex == currentQuestion!.correctAnswerIndex;
    _hasAnswered = true;
    if (_lastAnswerCorrect) {
      _correctCount++;
    }
    notifyListeners();
  }

  /// Moves to the next question or completes the quiz.
  void moveToNext() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedAnswerIndex = -1;
      _hasAnswered = false;
    } else {
      _isCompleted = true;
    }
    notifyListeners();
  }

  /// Resets and restarts the quiz with new random questions.
  Future<void> restart() async {
    await _processEntries(_loadedEntries);
    notifyListeners();
  }
}
