// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';

/// Practice mode types for different learning scenarios.
enum PracticeMode {
  diaryEntries('Diary Entries', 'Practice words and phrases from your diary'),
  kanji('Kanji', 'Practice kanji characters and their meanings');

  const PracticeMode(this.label, this.description);
  final String label;
  final String description;
}

/// Abstract practice item that can represent different types of content.
///
/// This class provides a unified interface for practice questions, allowing
/// the same UI and logic to work with different data sources (diary entries,
/// kanji, etc.).
///
/// Properties:
/// - [prompt]: The question shown to the user (e.g., English meaning)
/// - [correctAnswer]: The expected answer (e.g., Japanese text or kanji)
/// - [furigana]: Optional reading guide shown when answer is incorrect
/// - [mode]: The type of practice this item represents
class PracticeItem {
  /// The question text shown to the user.
  final String prompt;

  /// The correct answer the user should provide.
  final String correctAnswer;

  /// Optional reading guide (furigana) for the correct answer.
  final String? furigana;

  /// The practice mode this item belongs to.
  final PracticeMode mode;

  PracticeItem({
    required this.prompt,
    required this.correctAnswer,
    this.furigana,
    required this.mode,
  });

  /// Creates a practice item from a diary entry.
  ///
  /// The diary entry's English meaning becomes the prompt, and the user
  /// must type the Japanese text as the answer.
  factory PracticeItem.fromDiaryEntry(DiaryEntry entry) {
    return PracticeItem(
      prompt: entry.meaning,
      correctAnswer: entry.japanese,
      furigana: entry.furigana,
      mode: PracticeMode.diaryEntries,
    );
  }

  /// Creates a practice item from kanji data.
  ///
  /// The kanji's English meanings become the prompt, and the user must type
  /// the kanji character as the answer. Kun-yomi reading is preferred for
  /// furigana, falling back to on-yomi if kun-yomi is not available.
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

/// Practice mode where users type Japanese text for given English meanings.
///
/// This widget provides an interactive quiz interface where users are shown
/// English prompts and must type the corresponding Japanese text. It supports
/// multiple practice scenarios through the [mode] parameter:
///
/// - [PracticeMode.diaryEntries]: Practice words/phrases from diary entries
/// - [PracticeMode.kanji]: Practice kanji characters from diary entries
///
/// Features:
/// - Shows 10 random questions per session
/// - Tracks first-attempt accuracy
/// - Provides immediate feedback with correct answers
/// - Displays furigana reading guides when incorrect
/// - Shows completion summary with percentage score
class PracticeModePage extends StatefulWidget {
  /// The type of practice content to quiz on.
  final PracticeMode mode;

  const PracticeModePage({super.key, this.mode = PracticeMode.diaryEntries});

  @override
  State<PracticeModePage> createState() => _PracticeModePageState();
}

class _PracticeModePageState extends State<PracticeModePage> {
  /// Future that loads the practice items from the database.
  late Future<List<PracticeItem>> _itemsFuture;

  /// The list of practice items for the current session.
  List<PracticeItem> _practiceItems = [];

  /// Index of the currently displayed question (0-based).
  int _currentIndex = 0;

  /// Controls the text input field for user answers.
  final TextEditingController _answerController = TextEditingController();

  /// Manages focus for the answer input field.
  final FocusNode _answerFocusNode = FocusNode();

  /// Whether to display the correct answer (shown after wrong attempt).
  bool _showCorrectAnswer = false;

  /// Whether the user's most recent answer was correct.
  bool _isCorrect = false;

  /// Count of questions answered correctly on the first attempt.
  int _correctCount = 0;

  /// Whether the practice session has been completed.
  bool _isCompleted = false;

  /// Whether the user has made at least one attempt on the current question.
  bool _hasAttemptedCurrentQuestion = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadRandomItems();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  /// Loads 10 random items for practice based on the selected mode.
  ///
  /// Dispatches to the appropriate loading method based on [widget.mode]:
  /// - [PracticeMode.diaryEntries]: Loads from diary entries
  /// - [PracticeMode.kanji]: Loads kanji that appear in diary entries
  ///
  /// Updates [_practiceItems] state and returns the loaded items.
  Future<List<PracticeItem>> _loadRandomItems() async {
    List<PracticeItem> items = [];
    final diaryRepository = DiaryRepository();
    final kanjiRepository = KanjiRepository();

    switch (widget.mode) {
      case PracticeMode.diaryEntries:
        final allEntries = await diaryRepository.getAllEntries();
        if (allEntries.isNotEmpty) {
          final random = Random();
          final shuffled = List<DiaryEntry>.from(allEntries)..shuffle(random);
          items = shuffled
              .take(10)
              .map((e) => PracticeItem.fromDiaryEntry(e))
              .toList();
        }
        break;

      case PracticeMode.kanji:
        final kanjiList = await kanjiRepository.getRandomKanjiFromDiary(
          count: 10,
        );
        items = kanjiList.map((k) => PracticeItem.fromKanji(k)).toList();
        break;
    }

    setState(() {
      _practiceItems = items;
    });

    return items;
  }

  /// Checks if the user's answer is correct and updates the UI accordingly.
  ///
  /// Compares the user's trimmed input with the correct answer:
  /// - If correct: Sets [_isCorrect] to true, increments [_correctCount]
  ///   (only on first attempt), and auto-advances after 500ms
  /// - If incorrect: Shows the correct answer and marks that an attempt
  ///   was made (subsequent attempts won't count toward score)
  ///
  /// Does nothing if practice items are empty or index is out of range.
  void _checkAnswer() {
    if (_practiceItems.isEmpty || _currentIndex >= _practiceItems.length) {
      return;
    }

    final currentItem = _practiceItems[_currentIndex];
    final userAnswer = _answerController.text.trim();
    final correctAnswer = currentItem.correctAnswer;

    if (userAnswer == correctAnswer) {
      setState(() {
        _isCorrect = true;
        // Only count if this is the first attempt
        if (!_hasAttemptedCurrentQuestion) {
          _correctCount++;
        }
      });

      // Move to next entry after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _moveToNext();
        }
      });
    } else {
      setState(() {
        _showCorrectAnswer = true;
        _isCorrect = false;
        _hasAttemptedCurrentQuestion = true;
      });
    }
  }

  /// Moves to the next item or completes the practice session.
  ///
  /// If more questions remain, advances [_currentIndex], clears the answer
  /// input, resets question state, and focuses the input field.
  ///
  /// If this was the last question, sets [_isCompleted] to true, triggering
  /// display of the completion screen with score summary.
  void _moveToNext() {
    if (_currentIndex < _practiceItems.length - 1) {
      setState(() {
        _currentIndex++;
        _answerController.clear();
        _showCorrectAnswer = false;
        _isCorrect = false;
        _hasAttemptedCurrentQuestion = false;
      });
      _answerFocusNode.requestFocus();
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  /// Resets and restarts the practice session with new random items.
  ///
  /// Resets all state variables to their initial values:
  /// - Clears score and progress
  /// - Loads a new set of random practice items
  /// - Returns to the first question
  /// - Focuses the answer input field
  ///
  /// This allows the user to practice again with different questions.
  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _answerController.clear();
      _showCorrectAnswer = false;
      _isCorrect = false;
      _isCompleted = false;
      _hasAttemptedCurrentQuestion = false;
      _itemsFuture = _loadRandomItems();
    });
    _answerFocusNode.requestFocus();
  }

  /// Builds the main practice mode UI.
  ///
  /// Uses a [FutureBuilder] to handle three states:
  /// - Loading: Shows a progress indicator
  /// - Error: Displays error message
  /// - Empty: Shows message when no items are available
  /// - Success: Shows either the practice screen or completion screen
  ///
  /// The app bar title includes the current practice mode label.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LearningModeAppBar(title: 'Practice: ${widget.mode.label}'),
      backgroundColor: AppTheme.scaffoldBackground(context),
      floatingActionButton: const BirdFab(),
      body: FutureBuilder<List<PracticeItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (_practiceItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.mode.label.toLowerCase()} to practice with.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (_isCompleted) {
            return _buildCompletionScreen(context);
          }

          return _buildPracticeScreen(context);
        },
      ),
    );
  }

  /// Builds the main practice screen with question and answer UI.
  ///
  /// Layout structure:
  /// - Progress indicator: Shows current question number and correct count
  /// - Question prompt: Large centered text showing what to translate
  /// - Answer input: Text field for Japanese input with auto-focus
  /// - Submit button: Triggers answer validation
  /// - Correct answer panel: Conditionally shown when answer is wrong,
  ///   displays the correct answer with furigana and a next button
  ///
  /// The content is centered with a max width of 800px for readability.
  Widget _buildPracticeScreen(BuildContext context) {
    final currentItem = _practiceItems[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressIndicator(context),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionPrompt(context, currentItem.prompt),
                  const SizedBox(height: 32),
                  _buildAnswerInput(context),
                  const SizedBox(height: 16),
                  _buildSubmitButton(context),
                  if (_showCorrectAnswer) ...[
                    const SizedBox(height: 24),
                    _buildCorrectAnswerPanel(context, currentItem),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the progress indicator row.
  Widget _buildProgressIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Question ${_currentIndex + 1} of ${_practiceItems.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Correct: $_correctCount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds the question prompt display.
  Widget _buildQuestionPrompt(BuildContext context, String prompt) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        prompt,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the answer input text field.
  Widget _buildAnswerInput(BuildContext context) {
    return TextField(
      controller: _answerController,
      focusNode: _answerFocusNode,
      autofocus: true,
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: _buildInputDecoration(context),
      onSubmitted: (_) => _checkAnswer(),
    );
  }

  /// Creates the input decoration for the answer field.
  InputDecoration _buildInputDecoration(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InputDecoration(
      labelText: 'Your answer',
      hintText: 'Type in Japanese...',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor.withAlpha(128)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      suffixIcon: _isCorrect
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
    );
  }

  /// Builds the submit answer button.
  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _checkAnswer,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Submit', style: TextStyle(fontSize: 18)),
    );
  }

  /// Builds the panel showing the correct answer after an incorrect attempt.
  Widget _buildCorrectAnswerPanel(BuildContext context, PracticeItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(180), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCorrectAnswerHeader(context),
            const SizedBox(height: 8),
            _buildCorrectAnswerText(context, item),
            const SizedBox(height: 12),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  /// Builds the header for the correct answer panel.
  Widget _buildCorrectAnswerHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, color: Colors.red[700]),
        const SizedBox(width: 8),
        Text(
          'Correct answer:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
        ),
      ],
    );
  }

  /// Builds the correct answer text with optional furigana.
  Widget _buildCorrectAnswerText(BuildContext context, PracticeItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.furigana != null && item.furigana != item.correctAnswer)
          Text(
            item.furigana!,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        Text(
          item.correctAnswer,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Builds the next/finish button in the correct answer panel.
  Widget _buildNextButton(BuildContext context) {
    final isLastQuestion = _currentIndex >= _practiceItems.length - 1;

    return ElevatedButton.icon(
      onPressed: _moveToNext,
      icon: const Icon(Icons.arrow_forward),
      label: Text(isLastQuestion ? 'Finish' : 'Next Question'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Builds the completion screen shown after all questions are answered.
  ///
  /// Displays:
  /// - Celebration icon (🎉 if ≥70%, 👍 if <70%)
  /// - "Practice Complete!" title
  /// - Score as fraction (e.g., "7 out of 10")
  /// - Percentage score in large text
  /// - Two action buttons:
  ///   - "Practice Again": Restarts with new questions
  ///   - "Back to Dashboard": Returns to main screen
  ///
  /// The score only counts first-attempt correct answers.
  Widget _buildCompletionScreen(BuildContext context) {
    final percentage = (_correctCount / _practiceItems.length * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCompletionIcon(context, percentage),
            const SizedBox(height: 24),
            _buildCompletionTitle(context),
            const SizedBox(height: 16),
            _buildScoreText(context),
            const SizedBox(height: 8),
            _buildPercentageText(context, percentage),
            const SizedBox(height: 32),
            _buildCompletionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds the completion screen icon based on score.
  Widget _buildCompletionIcon(BuildContext context, int percentage) {
    return Icon(
      percentage >= 70 ? Icons.celebration : Icons.thumb_up,
      size: 80,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  /// Builds the completion title.
  Widget _buildCompletionTitle(BuildContext context) {
    return Text(
      'Practice Complete!',
      style: Theme.of(
        context,
      ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Builds the score text showing fraction.
  Widget _buildScoreText(BuildContext context) {
    return Text(
      'You got $_correctCount out of ${_practiceItems.length} correct on first try',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  /// Builds the large percentage display.
  Widget _buildPercentageText(BuildContext context, int percentage) {
    return Text(
      '$percentage%',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds the action buttons for completion screen.
  Widget _buildCompletionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.refresh),
          label: const Text('Practice Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Dashboard'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}
