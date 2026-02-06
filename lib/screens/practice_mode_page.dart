// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/controllers/practice_controller.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/widgets/ruby_text.dart';
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
  final FocusNode _focusNode = FocusNode();

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
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Handles keyboard shortcuts: Space=reveal, 1-4=ratings.
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (!_controller.isRevealed) {
        _controller.revealAnswer();
      }
    } else if (_controller.isRevealed) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _controller.rateQuestion(PracticeRating.again);
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        _controller.rateQuestion(PracticeRating.hard);
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        _controller.rateQuestion(PracticeRating.good);
      } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
        _controller.rateQuestion(PracticeRating.easy);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<PracticeController>(
        builder: (context, controller, child) {
          return KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Scaffold(
              appBar: LearningModeAppBar(title: widget.mode.label),
              backgroundColor: AppTheme.scaffoldBackground(context),
              floatingActionButton: const BirdFab(),
              body: _buildBody(context, controller),
            ),
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

    if (!controller.hasQuestions && !controller.isCompleted) {
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

  /// Builds the main quiz screen with question, answer reveal, and rating buttons.
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
                _buildQuestionCard(context, currentQuestion, controller),
                const SizedBox(height: 32),
                if (controller.isRevealed)
                  _buildRatingButtons(context, controller)
                else
                  _buildRevealButton(context, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the progress indicator showing new/reviewing/completed counts.
  Widget _buildProgressIndicator(
    BuildContext context,
    PracticeController controller,
  ) {
    return Center(
      child: Text(
        '${controller.newCards} / ${controller.reviewingCards} / ${controller.completedCards}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the question card with prompt and answer.
  Widget _buildQuestionCard(
    BuildContext context,
    QuizQuestion question,
    PracticeController controller,
  ) {
    final isJapanesePrompt =
        question.questionMode == QuizQuestionMode.japaneseToMeaning;

    final shouldShowPromptFurigana =
        _showFurigana &&
        isJapanesePrompt &&
        question.rawPrompt != null &&
        RubyText.containsRubyPattern(question.rawPrompt!);

    final promptStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: isJapanesePrompt ? 36 : 24,
    );

    // Answer styling
    final isJapaneseAnswer = !isJapanesePrompt;
    final shouldShowAnswerFurigana =
        _showFurigana &&
        isJapaneseAnswer &&
        question.rawAnswerOptions != null &&
        question.rawAnswerOptions!.isNotEmpty &&
        RubyText.containsRubyPattern(
          question.rawAnswerOptions![question.correctAnswerIndex],
        );

    final answerStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: isJapaneseAnswer ? 36 : 24,
    );

    return GestureDetector(
      onTap: () {
        if (!controller.isRevealed) {
          controller.revealAnswer();
        }
      },
      child: Container(
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
            // Prompt
            if (shouldShowPromptFurigana)
              RubyText(text: question.rawPrompt!, textStyle: promptStyle)
            else
              Text(question.prompt, style: promptStyle),

            // Divider and answer (shown after reveal)
            if (controller.isRevealed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Divider(
                  color:
                      Theme.of(context).colorScheme.primary.withAlpha(80),
                ),
              ),
              if (shouldShowAnswerFurigana)
                RubyText(
                  text: question
                      .rawAnswerOptions![question.correctAnswerIndex],
                  textStyle: answerStyle,
                )
              else
                Text(question.correctAnswer, style: answerStyle),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the "Tap to reveal" button.
  Widget _buildRevealButton(
    BuildContext context,
    PracticeController controller,
  ) {
    return Center(
      child: TextButton.icon(
        onPressed: controller.revealAnswer,
        icon: const Icon(Icons.visibility),
        label: const Text('Show Answer'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the rating buttons row (Again, Hard, Good, Easy).
  Widget _buildRatingButtons(
    BuildContext context,
    PracticeController controller,
  ) {
    return Column(
      children: [
        Text(
          'How well did you know this?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Again',
                color: Colors.red,
                onTap: () => controller.rateQuestion(PracticeRating.again),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Hard',
                color: Colors.orange,
                onTap: () => controller.rateQuestion(PracticeRating.hard),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Good',
                color: Colors.green,
                onTap: () => controller.rateQuestion(PracticeRating.good),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Easy',
                color: Colors.blue,
                onTap: () => controller.rateQuestion(PracticeRating.easy),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a single rating button.
  Widget _buildRatingButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color.withAlpha(20),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withAlpha(100)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Builds the completion screen shown after all questions are answered.
  Widget _buildCompletionScreen(
    BuildContext context,
    PracticeController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Practice Complete!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildRatingSummary(context, controller),
            const SizedBox(height: 32),
            _buildCompletionButtons(context, controller),
          ],
        ),
      ),
    );
  }

  /// Builds the rating summary table for the completion screen.
  Widget _buildRatingSummary(
    BuildContext context,
    PracticeController controller,
  ) {
    return Column(
      children: [
        _buildSummaryRow(context, 'Again', controller.againCount, Colors.red),
        const SizedBox(height: 8),
        _buildSummaryRow(context, 'Hard', controller.hardCount, Colors.orange),
        const SizedBox(height: 8),
        _buildSummaryRow(context, 'Good', controller.goodCount, Colors.green),
        const SizedBox(height: 8),
        _buildSummaryRow(context, 'Easy', controller.easyCount, Colors.blue),
      ],
    );
  }

  /// Builds a single summary row.
  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
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
