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
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';

/// Practice mode types for different learning scenarios.
enum PracticeMode {
  diaryEntries('Diary Quiz', 'Practice words and phrases from your diary'),
  kanji('Kanji Quiz', 'Practice kanji characters and their meanings');

  const PracticeMode(this.label, this.description);
  final String label;
  final String description;
}

/// Quiz question mode - what type of question to ask.
enum QuizQuestionMode {
  /// Show meaning, select Japanese answer
  meaningToJapanese,

  /// Show Japanese, select meaning answer
  japaneseToMeaning,
}

/// Represents a single quiz question with multiple choice answers.
///
/// This class holds all the data needed to display a quiz question:
/// - The prompt (question) to show the user
/// - The correct answer
/// - Three wrong answers (distractors)
/// - Optional metadata like furigana for display
class QuizQuestion {
  /// The question text shown to the user.
  final String prompt;

  /// The correct answer.
  final String correctAnswer;

  /// List of all answer options (shuffled, includes correct answer).
  final List<String> answerOptions;

  /// The index of the correct answer in [answerOptions].
  final int correctAnswerIndex;

  /// Optional furigana reading for the correct answer.
  final String? furigana;

  /// The question mode (meaning->japanese or japanese->meaning).
  final QuizQuestionMode questionMode;

  /// The practice mode this question belongs to.
  final PracticeMode practiceMode;

  QuizQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.answerOptions,
    required this.correctAnswerIndex,
    this.furigana,
    required this.questionMode,
    required this.practiceMode,
  });

  /// Creates a quiz question from a diary entry with distractor entries.
  ///
  /// [entry] - The diary entry for the correct answer
  /// [distractors] - Three other entries to use as wrong answers
  /// [questionMode] - Whether to ask meaning->japanese or japanese->meaning
  factory QuizQuestion.fromDiaryEntry({
    required DiaryEntry entry,
    required List<DiaryEntry> distractors,
    required QuizQuestionMode questionMode,
  }) {
    final random = Random();

    String prompt;
    String correctAnswer;
    List<String> wrongAnswers;

    if (questionMode == QuizQuestionMode.meaningToJapanese) {
      prompt = entry.meaning;
      correctAnswer = entry.japanese;
      wrongAnswers = distractors.map((d) => d.japanese).toList();
    } else {
      prompt = entry.japanese;
      correctAnswer = entry.meaning;
      wrongAnswers = distractors.map((d) => d.meaning).toList();
    }

    // Combine and shuffle answers
    final allAnswers = [correctAnswer, ...wrongAnswers];
    allAnswers.shuffle(random);

    return QuizQuestion(
      prompt: prompt,
      correctAnswer: correctAnswer,
      answerOptions: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      furigana: entry.furigana,
      questionMode: questionMode,
      practiceMode: PracticeMode.diaryEntries,
    );
  }

  /// Creates a quiz question from kanji data with distractor kanji.
  ///
  /// [kanji] - The kanji for the correct answer
  /// [distractors] - Three other kanji to use as wrong answers
  /// [questionMode] - Whether to ask meaning->kanji or kanji->meaning
  factory QuizQuestion.fromKanji({
    required KanjiData kanji,
    required List<KanjiData> distractors,
    required QuizQuestionMode questionMode,
  }) {
    final random = Random();

    String prompt;
    String correctAnswer;
    List<String> wrongAnswers;

    if (questionMode == QuizQuestionMode.meaningToJapanese) {
      prompt = kanji.meanings;
      correctAnswer = kanji.kanji;
      wrongAnswers = distractors.map((d) => d.kanji).toList();
    } else {
      prompt = kanji.kanji;
      correctAnswer = kanji.meanings;
      wrongAnswers = distractors.map((d) => d.meanings).toList();
    }

    // Combine and shuffle answers
    final allAnswers = [correctAnswer, ...wrongAnswers];
    allAnswers.shuffle(random);

    return QuizQuestion(
      prompt: prompt,
      correctAnswer: correctAnswer,
      answerOptions: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      furigana: kanji.readingsKun.isNotEmpty
          ? kanji.readingsKun.split(',').first.trim()
          : kanji.readingsOn.split(',').first.trim(),
      questionMode: questionMode,
      practiceMode: PracticeMode.kanji,
    );
  }
}

/// Controller for the practice/quiz mode.
///
/// Manages quiz state including loading questions, tracking answers,
/// scoring, and navigation between questions.
class PracticeController extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final KanjiRepository _kanjiRepository;
  final PracticeMode mode;

  /// The list of quiz questions for the current session.
  List<QuizQuestion> _questions = [];

  /// Index of the currently displayed question (0-based).
  int _currentIndex = 0;

  /// The index of the answer the user selected, or -1 if none.
  int _selectedAnswerIndex = -1;

  /// Whether the user has answered the current question.
  bool _hasAnswered = false;

  /// Count of questions answered correctly.
  int _correctCount = 0;

  /// Whether the practice session has been completed.
  bool _isCompleted = false;

  /// Loading state.
  bool _isLoading = false;

  /// Error message if loading failed.
  String? _errorMessage;

  PracticeController({
    required this.mode,
    DiaryRepository? diaryRepository,
    KanjiRepository? kanjiRepository,
  }) : _diaryRepository = diaryRepository ?? DiaryRepository(),
       _kanjiRepository = kanjiRepository ?? KanjiRepository();

  // Getters
  List<QuizQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get selectedAnswerIndex => _selectedAnswerIndex;
  bool get hasAnswered => _hasAnswered;
  int get correctCount => _correctCount;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Whether there are enough questions to run a quiz.
  bool get hasQuestions => _questions.isNotEmpty;

  /// The current question being displayed, or null if none.
  QuizQuestion? get currentQuestion =>
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

  /// Loads quiz questions based on the selected mode.
  ///
  /// For each question, randomly selects either meaning→Japanese or
  /// Japanese→meaning mode, picks a random entry, and selects 3 other
  /// entries as distractors.
  Future<void> loadQuestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final random = Random();
      List<QuizQuestion> questions = [];

      switch (mode) {
        case PracticeMode.diaryEntries:
          final allEntries = await _diaryRepository.getAllEntries();

          if (allEntries.length >= 4) {
            final shuffled = List<DiaryEntry>.from(allEntries)..shuffle(random);
            final questionCount = min(10, allEntries.length);

            for (int i = 0; i < questionCount; i++) {
              final entry = shuffled[i];
              // Get 3 distractors (different from current entry)
              final distractors =
                  allEntries.where((e) => e.id != entry.id).toList()
                    ..shuffle(random);
              final selectedDistractors = distractors.take(3).toList();

              // Randomly choose question mode
              final questionMode = random.nextBool()
                  ? QuizQuestionMode.meaningToJapanese
                  : QuizQuestionMode.japaneseToMeaning;

              questions.add(
                QuizQuestion.fromDiaryEntry(
                  entry: entry,
                  distractors: selectedDistractors,
                  questionMode: questionMode,
                ),
              );
            }
          }
          break;

        case PracticeMode.kanji:
          final kanjiList = await _kanjiRepository.getRandomKanjiFromDiary(
            count: 40, // Get more to have enough distractors
          );

          if (kanjiList.length >= 4) {
            final shuffled = List<KanjiData>.from(kanjiList)..shuffle(random);
            final questionCount = min(10, kanjiList.length);

            for (int i = 0; i < questionCount; i++) {
              final kanji = shuffled[i];
              // Get 3 distractors (different from current kanji)
              final distractors =
                  kanjiList.where((k) => k.kanji != kanji.kanji).toList()
                    ..shuffle(random);
              final selectedDistractors = distractors.take(3).toList();

              // Randomly choose question mode
              final questionMode = random.nextBool()
                  ? QuizQuestionMode.meaningToJapanese
                  : QuizQuestionMode.japaneseToMeaning;

              questions.add(
                QuizQuestion.fromKanji(
                  kanji: kanji,
                  distractors: selectedDistractors,
                  questionMode: questionMode,
                ),
              );
            }
          }
          break;
      }

      _questions = questions;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load questions: $e';
      _questions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  Future<void> restart() async {
    _currentIndex = 0;
    _correctCount = 0;
    _selectedAnswerIndex = -1;
    _hasAnswered = false;
    _isCompleted = false;
    _questions = [];
    notifyListeners();

    await loadQuestions();
  }
}
