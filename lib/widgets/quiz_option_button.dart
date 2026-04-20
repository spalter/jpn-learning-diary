// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/ruby_text.dart';

/// A specialized button widget for multiple-choice quiz answers.
///
/// This widget renders a single option in a quiz, handling all visual states
/// related to selection and correctness. It adapts its appearance based on the
/// current quiz state (unanswered, selected, correct/incorrect) and provides
/// immediate visual feedback.
///
/// * [index]: The index of this option in the list.
/// * [text]: The answer text to display.
/// * [rawText]: Optional raw text value (e.g. for text-to-speech).
/// * [isSelected]: Whether this option is currently selected by the user.
/// * [hasAnswered]: Whether the question has been answered (locks interaction).
/// * [isCorrectAnswer]: Whether this option is the correct answer.
/// * [isJapanese]: Whether the text should be treated as Japanese (affects fonts).
/// * [showFurigana]: Whether to display furigana readings above the text.
/// * [onTap]: Callback triggered when the button is tapped.
class QuizOptionButton extends StatelessWidget {
  final int index;
  final String text;
  final String? rawText;
  final bool isSelected;
  final bool hasAnswered;
  final bool isCorrectAnswer;
  final bool isJapanese;
  final bool showFurigana;
  final VoidCallback? onTap;

  const QuizOptionButton({
    super.key,
    required this.index,
    required this.text,
    this.rawText,
    required this.isSelected,
    required this.hasAnswered,
    required this.isCorrectAnswer,
    required this.isJapanese,
    required this.showFurigana,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on state
    Color? iconColor;
    Color? textColor;
    IconData? resultIcon;

    if (hasAnswered) {
      if (isCorrectAnswer) {
        iconColor = Colors.green;
        textColor = Colors.green[700];
        resultIcon = Icons.check_circle;
      } else if (isSelected) {
        iconColor = Colors.red;
        textColor = Colors.red[700];
        resultIcon = Icons.cancel;
      } else {
        textColor = Theme.of(context).colorScheme.onSurface.withAlpha(128);
      }
    } else if (isSelected) {
      iconColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.primary;
    }

    // AppCard functionality inline to avoid circular dependency if AppCard is complex
    // Assuming simple card styling here
    return MouseRegion(
      cursor: hasAnswered ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: hasAnswered ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withAlpha(20)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor.withAlpha(80),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Answer letter (A, B, C, D)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? Theme.of(context).colorScheme.primary)
                      .withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: iconColor ?? Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Answer text
              Expanded(child: _buildAnswerText(context, textColor)),
              // Result icon
              if (resultIcon != null)
                Icon(resultIcon, color: iconColor, size: 28)
              else
                const SizedBox(width: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerText(BuildContext context, Color? textColor) {
    final shouldShowFurigana =
        showFurigana &&
        isJapanese &&
        rawText != null &&
        RubyText.containsRubyPattern(rawText!);

    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: textColor ?? Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.bold,
      fontSize: isJapanese ? 20 : 16,
    );

    if (shouldShowFurigana) {
      return RubyText(text: rawText!, textStyle: textStyle);
    }

    return Text(text, style: textStyle, textAlign: TextAlign.left);
  }
}
