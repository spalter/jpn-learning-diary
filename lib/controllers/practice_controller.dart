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
/// - Raw text with ruby patterns for furigana display
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
      questionMode: questionMode,
      practiceMode: PracticeMode.jmdict,
    );
  }
}

/// Self-assessment rating for practice questions.
enum PracticeRating {
  /// Did not know the answer at all.
  again,

  /// Knew the answer but it was difficult.
  hard,

  /// Knew the answer well.
  good,

  /// Knew the answer perfectly / too easy.
  easy,
}

/// Controller for the practice/quiz mode.
///
/// Manages quiz state including loading questions, tracking answers,
/// scoring, and navigation between questions.
///
/// Questions are presented one at a time. The user taps to reveal the
/// correct answer, then self-assesses with Again/Hard/Good/Easy.
/// Again, Hard, and Good move the question to the end of the deck.
/// Easy removes it. The session ends when the deck is empty.
class PracticeController extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final KanjiRepository _kanjiRepository;
  final JMdictRepository _jmdictRepository;
  final PracticeMode mode;

  /// The active review deck (queue of questions to review).
  List<QuizQuestion> _deck = [];

  /// Total number of entries initially in the deck.
  int _initialDeckSize = 0;

  /// Whether the current question is showing its answer.
  bool _isRevealed = false;

  /// Whether the practice session has been completed.
  bool _isCompleted = false;

  /// Loading state.
  bool _isLoading = false;

  /// Error message if loading failed.
  String? _errorMessage;

  /// Cumulative count of each rating during the session.
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;

  /// Whether each question has been seen at least once.
  final Set<int> _seenIndices = {};

  PracticeController({
    required this.mode,
    DiaryRepository? diaryRepository,
    KanjiRepository? kanjiRepository,
    JMdictRepository? jmdictRepository,
  }) : _diaryRepository = diaryRepository ?? DiaryRepository(),
       _kanjiRepository = kanjiRepository ?? KanjiRepository(),
       _jmdictRepository = jmdictRepository ?? JMdictRepository();

  // Getters
  bool get isRevealed => _isRevealed;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Whether there are enough questions to run a quiz.
  bool get hasQuestions => _deck.isNotEmpty;

  /// The current question being displayed, or null if none.
  QuizQuestion? get currentQuestion => _deck.isNotEmpty ? _deck[0] : null;

  /// Total number of entries in the session.
  int get totalCards => _initialDeckSize;

  /// Number of entries remaining in the deck.
  int get remainingCards => _deck.length;

  /// Number of new (unseen) entries still in the deck.
  int get newCards =>
      _deck.where((q) => !_seenIndices.contains(q.hashCode)).length;

  /// Number of entries that have been rated but are still in the deck.
  int get reviewingCards =>
      _deck.where((q) => _seenIndices.contains(q.hashCode)).length;

  /// Number of entries completed (removed via Easy).
  int get completedCards => _easyCount;

  /// Rating count getters for the completion summary.
  int get againCount => _againCount;
  int get hardCount => _hardCount;
  int get goodCount => _goodCount;
  int get easyCount => _easyCount;

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
              final distractors =
                  allEntries.where((e) => e.id != entry.id).toList()
                    ..shuffle(random);
              final selectedDistractors = distractors.take(3).toList();

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
            count: maxQuestions * 4,
          );

          if (kanjiList.length >= 4) {
            final shuffled = List<KanjiData>.from(kanjiList)..shuffle(random);
            final questionCount = min(maxQuestions, kanjiList.length);

            for (int i = 0; i < questionCount; i++) {
              final kanji = shuffled[i];
              final distractors =
                  kanjiList.where((k) => k.kanji != kanji.kanji).toList()
                    ..shuffle(random);
              final selectedDistractors = distractors.take(3).toList();

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
            count: maxQuestions * 4,
          );

          if (jmdictEntries.length >= 4) {
            final shuffled = List<JMdictEntry>.from(jmdictEntries)
              ..shuffle(random);
            final questionCount = min(maxQuestions, jmdictEntries.length);

            for (int i = 0; i < questionCount; i++) {
              final entry = shuffled[i];
              final distractors =
                  jmdictEntries.where((e) => e.entSeq != entry.entSeq).toList()
                    ..shuffle(random);
              final selectedDistractors = distractors.take(3).toList();

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

      _deck = List<QuizQuestion>.from(questions);
      _initialDeckSize = _deck.length;
      _resetSessionState();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load questions: $e';
      _deck = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets session state for a new review.
  void _resetSessionState() {
    _isRevealed = false;
    _isCompleted = false;
    _againCount = 0;
    _hardCount = 0;
    _goodCount = 0;
    _easyCount = 0;
    _seenIndices.clear();
  }

  /// Reveals the answer for the current question.
  void revealAnswer() {
    if (_isRevealed || currentQuestion == null) return;
    _isRevealed = true;
    notifyListeners();
  }

  /// Rates the current question.
  ///
  /// Easy removes the question from the deck. Again, Hard, and Good move
  /// the question to the end of the deck. The session completes when the
  /// deck is empty.
  void rateQuestion(PracticeRating rating) {
    if (!_isRevealed || _deck.isEmpty) return;

    final question = _deck.removeAt(0);
    _seenIndices.add(question.hashCode);

    switch (rating) {
      case PracticeRating.again:
        _againCount++;
        _deck.add(question);
        break;
      case PracticeRating.hard:
        _hardCount++;
        _deck.add(question);
        break;
      case PracticeRating.good:
        _goodCount++;
        _deck.add(question);
        break;
      case PracticeRating.easy:
        _easyCount++;
        break;
    }

    _isRevealed = false;

    if (_deck.isEmpty) {
      _isCompleted = true;
    }

    notifyListeners();
  }

  /// Resets and restarts the quiz with new random questions.
  Future<void> restart() async {
    _deck = [];
    _resetSessionState();
    notifyListeners();

    await loadQuestions();
  }
}
