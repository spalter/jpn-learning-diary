// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';

/// A reusable card widget for displaying Japanese characters.
///
/// This widget is used to display individual hiragana, katakana, and kanji
/// characters with their romanization. It supports selection states and
/// user interaction, serving as the building block for character grids.
///
/// * [character]: The Japanese character to display (e.g., 'あ').
/// * [romanization]: The romanized reading of the character (e.g., 'a').
/// * [onTap]: Callback triggered when the card is tapped.
/// * [isSelected]: Whether the card is currently selected/highlighted.
class CharacterCard extends StatelessWidget {
  /// The Japanese character to display (e.g., 'あ', 'ア', '漢').
  final String character;

  /// The romanized version of the character (e.g., 'a', 'ka', 'kan').
  final String romanization;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Whether the card is selected/highlighted.
  final bool isSelected;

  const CharacterCard({
    super.key,
    required this.character,
    required this.romanization,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.bordered(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            character,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            romanization,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
