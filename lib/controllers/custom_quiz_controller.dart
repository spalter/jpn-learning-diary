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
  factory CustomQuizQuestion.fromEntry(CustomQuizEntry entry) {
    final random = Random();

    // Get all answers and shuffle them
    final allAnswers = List<String>.from(entry.allAnswers)..shuffle(random);

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
      _processEntries(entries);
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
      _processEntries(entries);
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
  void loadFromString(String csvContent, {String sourceName = 'Custom Quiz'}) {
    _isLoading = true;
    _errorMessage = null;
    _sourceName = sourceName;
    notifyListeners();

    try {
      final entries = CustomQuizService.loadFromString(csvContent);
      _processEntries(entries);
    } catch (e) {
      _errorMessage = 'Failed to parse quiz: $e';
      _questions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Processes loaded entries into quiz questions.
  void _processEntries(List<CustomQuizEntry> entries) {
    _loadedEntries = entries;

    if (entries.length < 4) {
      _errorMessage = 'Not enough questions. Need at least 4 entries.';
      _questions = [];
      return;
    }

    final random = Random();

    // Shuffle and take up to 10 questions
    final shuffled = List<CustomQuizEntry>.from(entries)..shuffle(random);
    final selectedEntries = shuffled.take(min(10, entries.length)).toList();

    _questions = selectedEntries
        .map((entry) => CustomQuizQuestion.fromEntry(entry))
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

  /// Handles when the user selects an answer option.
  ///
  /// If the user hasn't answered yet:
  /// - Records the selected answer
  /// - Marks the question as answered
  /// - Increments correct count if correct
  void selectAnswer(int index) {
    if (_hasAnswered || currentQuestion == null) return;

    final isCorrect = index == currentQuestion!.correctAnswerIndex;

    _selectedAnswerIndex = index;
    _hasAnswered = true;
    if (isCorrect) {
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
  void restart() {
    _processEntries(_loadedEntries);
    notifyListeners();
  }
}
