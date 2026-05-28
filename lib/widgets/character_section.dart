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
import 'package:jpn_learning_diary/widgets/kana_table.dart';

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

  /// Optional fixed column count for grid layout.
  /// If null, uses a responsive wrap layout.
  final int? crossAxisCount;

  const CharacterSection({
    super.key,
    required this.title,
    required this.characters,
    required this.characterTypeName,
    this.crossAxisCount,
  });

  /// Builds the section with a title and responsive character grid.
  ///
  /// uses either a GridView (if [crossAxisCount] is provided) or a LayoutBuilder + Wrap.
  @override
  Widget build(BuildContext context) {
    if (crossAxisCount != null) {
      return _buildFixedGrid(context);
    }

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
        _buildResponsiveWrap(context),
      ],
    );
  }

  Widget _buildFixedGrid(BuildContext context) {
    // If a fixed column count is requested, use the table view for a cleaner overview.
    // This provides the "minimal table" layout requested.
    return KanaTable(
      title: title,
      characters: characters,
      crossAxisCount: crossAxisCount!,
    );
  }

  Widget _buildResponsiveWrap(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive card size that adapts to window width.
        // Base size: 50x71 (smaller for grid), or keep logic?
        // Let's keep existing logic for Wrap.
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
            if (char.isEmpty) {
              return SizedBox(width: cardWidth, height: cardHeight);
            }
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
