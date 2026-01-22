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
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/repositories/jmdict_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';

/// Practice mode types for different learning scenarios.
enum PracticeMode {
  diaryEntries('Diary Quiz', 'Practice words and phrases from your diary'),
  kanji('Kanji Quiz', 'Practice kanji characters and their meanings'),
  jmdict('Vocabulary Quiz', 'Practice common Japanese vocabulary');

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
  /// The question text shown to the user (clean, without ruby patterns).
  final String prompt;

  /// The raw prompt text with ruby patterns intact (for furigana display).
  final String? rawPrompt;

  /// The correct answer.
  final String correctAnswer;

  /// List of all answer options (shuffled, includes correct answer).
  /// Clean text without ruby patterns.
  final List<String> answerOptions;

  /// List of raw answer options with ruby patterns intact (for furigana display).
  /// Indices correspond to [answerOptions].
  final List<String>? rawAnswerOptions;

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
    this.rawPrompt,
    required this.correctAnswer,
    required this.answerOptions,
    this.rawAnswerOptions,
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
  ///
  /// Ruby text patterns (e.g., `[漢字](かんじ)`) are automatically stripped
  /// from Japanese text to show clean text in the quiz. The original text
  /// is preserved in [rawPrompt] and [rawAnswerOptions] for furigana display.
  factory QuizQuestion.fromDiaryEntry({
    required DiaryEntry entry,
    required List<DiaryEntry> distractors,
    required QuizQuestionMode questionMode,
  }) {
    final random = Random();

    // Strip ruby patterns from Japanese text for clean quiz display
    String cleanJapanese(String text) {
      return JapaneseTextUtils.containsRubyPattern(text)
          ? JapaneseTextUtils.stripRubyPatterns(text)
          : text;
    }

    String prompt;
    String? rawPrompt;
    String correctAnswer;
    List<String> wrongAnswers;
    List<String>? rawWrongAnswers;

    if (questionMode == QuizQuestionMode.meaningToJapanese) {
      prompt = entry.meaning;
      rawPrompt = null; // Meaning doesn't have ruby
      correctAnswer = cleanJapanese(entry.japanese);
      wrongAnswers = distractors.map((d) => cleanJapanese(d.japanese)).toList();
      rawWrongAnswers = distractors.map((d) => d.japanese).toList();
    } else {
      prompt = cleanJapanese(entry.japanese);
      rawPrompt = entry.japanese; // Keep original for furigana
      correctAnswer = entry.meaning;
      wrongAnswers = distractors.map((d) => d.meaning).toList();
      rawWrongAnswers = null; // Meanings don't have ruby
    }

    // Combine and shuffle answers - need to track raw versions too
    final indices = [0, 1, 2, 3];
    indices.shuffle(random);

    final allAnswers = [correctAnswer, ...wrongAnswers];
    final shuffledAnswers = indices.map((i) => allAnswers[i]).toList();

    List<String>? shuffledRawAnswers;
    if (questionMode == QuizQuestionMode.meaningToJapanese) {
      final allRawAnswers = [entry.japanese, ...rawWrongAnswers!];
      shuffledRawAnswers = indices.map((i) => allRawAnswers[i]).toList();
    }

    return QuizQuestion(
      prompt: prompt,
      rawPrompt: rawPrompt,
      correctAnswer: correctAnswer,
      answerOptions: shuffledAnswers,
      rawAnswerOptions: shuffledRawAnswers,
      correctAnswerIndex: indices.indexOf(0),
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

  /// Creates a quiz question from a JMdict entry with distractor entries.
  ///
  /// [entry] - The JMdict entry for the correct answer
  /// [distractors] - Three other entries to use as wrong answers
  /// [questionMode] - Whether to ask meaning->japanese or japanese->meaning
  factory QuizQuestion.fromJMdictEntry({
    required JMdictEntry entry,
    required List<JMdictEntry> distractors,
    required QuizQuestionMode questionMode,
  }) {
    final random = Random();

    // Get primary form (kanji if available, otherwise reading)
    final japaneseForm = entry.primaryForm;
    // Get first gloss as meaning
    final meaning = entry.allGlosses.isNotEmpty
        ? entry.allGlosses.first
        : 'No meaning available';

    String prompt;
    String correctAnswer;
    List<String> wrongAnswers;

    if (questionMode == QuizQuestionMode.meaningToJapanese) {
      prompt = meaning;
      correctAnswer = japaneseForm;
      wrongAnswers = distractors.map((d) => d.primaryForm).toList();
    } else {
      prompt = japaneseForm;
      correctAnswer = meaning;
      wrongAnswers = distractors
          .map((d) => d.allGlosses.isNotEmpty ? d.allGlosses.first : '')
          .where((m) => m.isNotEmpty)
          .toList();
    }

    // Combine and shuffle answers
    final allAnswers = [correctAnswer, ...wrongAnswers];
    allAnswers.shuffle(random);

    return QuizQuestion(
      prompt: prompt,
      correctAnswer: correctAnswer,
      answerOptions: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      furigana: entry.primaryReading,
      questionMode: questionMode,
      practiceMode: PracticeMode.jmdict,
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
  final JMdictRepository _jmdictRepository;
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
    JMdictRepository? jmdictRepository,
  }) : _diaryRepository = diaryRepository ?? DiaryRepository(),
       _kanjiRepository = kanjiRepository ?? KanjiRepository(),
       _jmdictRepository = jmdictRepository ?? JMdictRepository();

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
      final maxQuestions = await AppPreferences.getQuizQuestionCount();

      switch (mode) {
        case PracticeMode.diaryEntries:
          final allEntries = await _diaryRepository.getAllEntries();

          if (allEntries.length >= 4) {
            final shuffled = List<DiaryEntry>.from(allEntries)..shuffle(random);
            final questionCount = min(maxQuestions, allEntries.length);

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
            count: maxQuestions * 4, // Get more to have enough distractors
          );

          if (kanjiList.length >= 4) {
            final shuffled = List<KanjiData>.from(kanjiList)..shuffle(random);
            final questionCount = min(maxQuestions, kanjiList.length);

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

        case PracticeMode.jmdict:
          final jmdictEntries = await _jmdictRepository.getRandomCommonEntries(
            count: maxQuestions * 4, // Get more to have enough distractors
          );

          if (jmdictEntries.length >= 4) {
            final shuffled = List<JMdictEntry>.from(jmdictEntries)
              ..shuffle(random);
            final questionCount = min(maxQuestions, jmdictEntries.length);

            for (int i = 0; i < questionCount; i++) {
              final entry = shuffled[i];
              // Get 3 distractors (different from current entry)
              final distractors =
                  jmdictEntries.where((e) => e.entSeq != entry.entSeq).toList()
                    ..shuffle(random);
              final selectedDistractors = distractors.take(3).toList();

              // Randomly choose question mode
              final questionMode = random.nextBool()
                  ? QuizQuestionMode.meaningToJapanese
                  : QuizQuestionMode.japaneseToMeaning;

              questions.add(
                QuizQuestion.fromJMdictEntry(
                  entry: entry,
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
