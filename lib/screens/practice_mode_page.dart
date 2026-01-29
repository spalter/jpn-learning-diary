// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/controllers/practice_controller.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/widgets/ruby_text.dart';
import 'package:jpn_learning_diary/widgets/quiz_option_button.dart';
import 'package:provider/provider.dart';

// Re-export from controller for backwards compatibility
export 'package:jpn_learning_diary/controllers/practice_controller.dart'
    show PracticeMode, QuizQuestionMode, QuizQuestion;

/// Multiple-choice quiz mode for practicing Japanese vocabulary and kanji.
///
/// This widget provides an interactive quiz interface where users are shown
/// a prompt and must select the correct answer from 4 options. It supports
/// multiple practice scenarios through the [mode] parameter:
///
/// - [PracticeMode.diaryEntries]: Practice words/phrases from diary entries
/// - [PracticeMode.kanji]: Practice kanji characters from diary entries
class PracticeModePage extends StatefulWidget {
  /// The type of practice content to quiz on.
  final PracticeMode mode;

  const PracticeModePage({super.key, this.mode = PracticeMode.diaryEntries});

  @override
  State<PracticeModePage> createState() => _PracticeModePageState();
}

class _PracticeModePageState extends State<PracticeModePage> {
  late PracticeController _controller;
  bool _showFurigana = true;

  @override
  void initState() {
    super.initState();
    _controller = PracticeController(mode: widget.mode);
    _controller.loadQuestions();
    _loadFuriganaSetting();
  }

  Future<void> _loadFuriganaSetting() async {
    final showFurigana = await AppPreferences.getShowFurigana();
    if (mounted) {
      setState(() {
        _showFurigana = showFurigana;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<PracticeController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: LearningModeAppBar(title: widget.mode.label),
            backgroundColor: AppTheme.scaffoldBackground(context),
            floatingActionButton: const BirdFab(),
            body: _buildBody(context, controller),
          );
        },
      ),
    );
  }

  /// Builds the main body based on controller state.
  Widget _buildBody(BuildContext context, PracticeController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return Center(child: Text('Error: ${controller.errorMessage}'));
    }

    if (!controller.hasQuestions) {
      return _buildEmptyState(context);
    }

    if (controller.isCompleted) {
      return _buildCompletionScreen(context, controller);
    }

    return _buildQuizScreen(context, controller);
  }

  /// Builds the empty state when there's not enough data.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Not enough ${widget.mode.label.toLowerCase()} to practice with.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'You need at least 4 entries to start a quiz.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
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

  /// Builds the main quiz screen with question and answer buttons.
  Widget _buildQuizScreen(BuildContext context, PracticeController controller) {
    final currentQuestion = controller.currentQuestion!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressIndicator(context, controller),
                const SizedBox(height: 16),
                _buildQuestionCard(context, currentQuestion),
                const SizedBox(height: 32),
                _buildAnswerButtons(context, controller, currentQuestion),
                const SizedBox(height: 24),
                _buildActionButton(context, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the progress indicator row.
  Widget _buildProgressIndicator(
    BuildContext context,
    PracticeController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Question ${controller.currentIndex + 1} of ${controller.totalQuestions}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Score: ${controller.correctCount}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the question card with the prompt.
  Widget _buildQuestionCard(BuildContext context, QuizQuestion question) {
    final isJapanesePrompt =
        question.questionMode == QuizQuestionMode.japaneseToMeaning;

    // Determine if we should show furigana (only for Japanese prompts with ruby patterns)
    final shouldShowFurigana =
        _showFurigana &&
        isJapanesePrompt &&
        question.rawPrompt != null &&
        RubyText.containsRubyPattern(question.rawPrompt!);

    final textStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: isJapanesePrompt ? 36 : 24,
    );

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shouldShowFurigana)
            RubyText(text: question.rawPrompt!, textStyle: textStyle)
          else
            Text(question.prompt, style: textStyle, textAlign: TextAlign.left),
        ],
      ),
    );
  }

  /// Builds the 4 answer option buttons in a vertical list.
  Widget _buildAnswerButtons(
    BuildContext context,
    PracticeController controller,
    QuizQuestion question,
  ) {
    return Column(
      children: [
        _buildAnswerButton(context, controller, question, 0),
        const SizedBox(height: 12),
        _buildAnswerButton(context, controller, question, 1),
        const SizedBox(height: 12),
        _buildAnswerButton(context, controller, question, 2),
        const SizedBox(height: 12),
        _buildAnswerButton(context, controller, question, 3),
      ],
    );
  }

  /// Builds a single answer button with appropriate styling.
  Widget _buildAnswerButton(
    BuildContext context,
    PracticeController controller,
    QuizQuestion question,
    int index,
  ) {
    return QuizOptionButton(
      index: index,
      text: question.answerOptions[index],
      rawText: question.rawAnswerOptions?[index],
      isSelected: controller.selectedAnswerIndex == index,
      hasAnswered: controller.hasAnswered,
      isCorrectAnswer: index == question.correctAnswerIndex,
      isJapanese: question.questionMode == QuizQuestionMode.meaningToJapanese,
      showFurigana: _showFurigana,
      onTap: () => controller.selectAnswer(index),
    );
  }

  /// Builds the action button that changes based on quiz state.
  ///
  /// - Before answering: "Check Answer" button (disabled until selection)
  /// - After correct answer: Green "Next Question" button
  /// - After wrong answer: Red "Next Question" button
  /// - On last question after answering: "See Results" button
  Widget _buildActionButton(
    BuildContext context,
    PracticeController controller,
  ) {
    final hasAnswered = controller.hasAnswered;
    final hasSelection = controller.hasSelection;
    final isLastQuestion = controller.isLastQuestion;
    final isCorrect = controller.lastAnswerCorrect;

    // Determine button properties based on state
    String label;
    IconData icon;
    VoidCallback? onPressed;
    Color? backgroundColor;
    Color? foregroundColor;

    if (!hasAnswered) {
      // Before committing: show "Check Answer" button
      label = 'Check Answer';
      icon = Icons.check;
      onPressed = hasSelection ? controller.commitAnswer : null;
      backgroundColor = null; // Use default
      foregroundColor = null;
    } else if (isLastQuestion) {
      // After answering the last question
      label = 'See Results';
      icon = Icons.flag;
      onPressed = controller.moveToNext;
      backgroundColor = isCorrect ? Colors.green[700] : Colors.red[700];
      foregroundColor = Colors.white;
    } else {
      // After answering: show styled "Next Question" button
      label = 'Next Question';
      icon = Icons.arrow_forward;
      onPressed = controller.moveToNext;
      backgroundColor = isCorrect ? Colors.green[700] : Colors.red[700];
      foregroundColor = Colors.white;
    }

    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withAlpha(20),
          disabledForegroundColor: Theme.of(
            context,
          ).colorScheme.primary.withAlpha(100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: backgroundColor == null
                ? BorderSide(
                    color: hasSelection
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withAlpha(60),
                  )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Builds the completion screen shown after all questions are answered.
  Widget _buildCompletionScreen(
    BuildContext context,
    PracticeController controller,
  ) {
    final percentage = controller.percentageScore;

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
            _buildScoreText(context, controller),
            const SizedBox(height: 8),
            _buildPercentageText(context, percentage),
            const SizedBox(height: 32),
            _buildCompletionButtons(context, controller),
          ],
        ),
      ),
    );
  }

  /// Builds the completion screen icon based on score.
  Widget _buildCompletionIcon(BuildContext context, int percentage) {
    IconData icon;
    Color color;

    if (percentage >= 80) {
      icon = Icons.emoji_events;
      color = Theme.of(context).colorScheme.primary;
    } else if (percentage >= 60) {
      icon = Icons.celebration;
      color = Theme.of(context).colorScheme.primary;
    } else {
      icon = Icons.thumb_up;
      color = Theme.of(context).colorScheme.secondary;
    }

    return Icon(icon, size: 80, color: color);
  }

  /// Builds the completion title.
  Widget _buildCompletionTitle(BuildContext context) {
    return Text(
      'Quiz Complete!',
      style: Theme.of(
        context,
      ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Builds the score text showing fraction.
  Widget _buildScoreText(BuildContext context, PracticeController controller) {
    return Text(
      'You got ${controller.correctCount} out of ${controller.totalQuestions} correct',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  /// Builds the large percentage display.
  Widget _buildPercentageText(BuildContext context, int percentage) {
    Color color = Theme.of(context).colorScheme.primary;

    return Text(
      '$percentage%',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds the action buttons for completion screen.
  Widget _buildCompletionButtons(
    BuildContext context,
    PracticeController controller,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: controller.restart,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Dashboard'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
