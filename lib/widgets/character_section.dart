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
import 'package:jpn_learning_diary/models/character_data.dart';
import 'package:jpn_learning_diary/widgets/character_card.dart';

/// A reusable section widget that displays Japanese characters in a responsive grid.
///
/// This widget renders a collection of character cards that automatically adjust
/// their size based on available width, ranging from 70-84px while maintaining
/// a 0.7 aspect ratio for proper proportions. Tapping any card copies the
/// character to the clipboard.
///
/// * [title]: The header title for this section.
/// * [characters]: The list of character data objects to display.
/// * [characterTypeName]: The name of the character type (e.g., "hiragana") for toast messages.
class CharacterSection extends StatelessWidget {
  /// The title of the section.
  final String title;

  /// The list of characters to display.
  final List<CharacterData> characters;

  /// The name of the character type (e.g., "hiragana", "katakana") for clipboard notifications.
  final String characterTypeName;

  const CharacterSection({
    super.key,
    required this.title,
    required this.characters,
    required this.characterTypeName,
  });

  /// Builds the section with a title and responsive character grid.
  ///
  /// Uses LayoutBuilder to calculate optimal card dimensions based on the
  /// available width, ensuring cards fill the space while staying within
  /// readable size bounds.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive card size that adapts to window width.
            // Base size: 70x100, Max size: 84x120 (20% bigger).
            // This ensures characters remain readable at different window sizes.
            final availableWidth = constraints.maxWidth;
            const spacing = 8.0;

            // Determine how many cards can fit in a row at base size.
            int cardsPerRow = (availableWidth / (70 + spacing)).floor();
            cardsPerRow = cardsPerRow < 1 ? 1 : cardsPerRow;

            // Calculate optimal card width to fill available space.
            double cardWidth =
                (availableWidth - (cardsPerRow - 1) * spacing) / cardsPerRow;

            // Constrain between min (70px) and max (84px) to maintain readability.
            cardWidth = cardWidth.clamp(70.0, 84.0);

            // Maintain aspect ratio (70:100 = 0.7) for proper card proportions.
            double cardHeight = cardWidth / 0.7;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: characters.map((char) {
                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: CharacterCard(
                    character: char.character,
                    romanization: char.romanization,
                    onTap: () => _copyToClipboard(context, char),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Copies the tapped character to the clipboard and shows a confirmation snackbar.
  void _copyToClipboard(BuildContext context, CharacterData character) {
    Clipboard.setData(ClipboardData(text: character.character));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${character.character} (${character.romanization}) to clipboard',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
