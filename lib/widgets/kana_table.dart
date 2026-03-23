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

/// A minimal table widget for displaying Japanese characters.
///
/// Displays characters in a structured grid with borders, focusing on
/// readability and overview rather than interactive cards.
class KanaTable extends StatelessWidget {
  /// The title of the table.
  final String title;

  /// The flat list of characters to display.
  final List<CharacterData> characters;

  /// Number of columns in the table.
  final int crossAxisCount;

  const KanaTable({
    super.key,
    required this.title,
    required this.characters,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    // Break characters into rows
    final rows = <TableRow>[];
    
    // Process characters in chunks equal to crossAxisCount
    for (int i = 0; i < characters.length; i += crossAxisCount) {
      // Calculate the chunk size safely
      final remaining = characters.length - i;
      final chunkSize = remaining < crossAxisCount ? remaining : crossAxisCount;
      
      final chunk = characters.sublist(i, i + chunkSize).toList();
      
      // If the row is incomplete, pad it with empty characters
      if (chunk.length < crossAxisCount) {
        chunk.addAll(
          List.generate(
            crossAxisCount - chunk.length, 
            (_) => CharacterData.empty,
          ),
        );
      }

      rows.add(TableRow(
        children: chunk.map((char) => _buildCell(context, char)).toList(),
      ));
    }

    final borderColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.3);
    final borderRadius = BorderRadius.circular(8.0);
    final isMobile = Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android;

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Table content
          Table(
            border: TableBorder(
              top: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
              horizontalInside: BorderSide(color: borderColor),
              // No outer vertical border on mobile
            ),
            // On mobile, let columns flex to fill width instead of fixed
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ],
      );
    }

    // Calculate fixed width to constrain the container
    // We add 2px to account for the left and right border width (1px each)
    // This ensures the title bar only spans the table width.
    final tableWidth = (crossAxisCount * 64.0) + 2.0;

    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // Table content
            Table(
              border: TableBorder(
                top: BorderSide(color: borderColor),
                horizontalInside: BorderSide(color: borderColor),
                verticalInside: BorderSide(color: borderColor),
              ),
              defaultColumnWidth: const FixedColumnWidth(64),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, CharacterData char) {
    if (char.isEmpty) {
      // Use AspectRatio to enforce square shape even for empty cells
      return const AspectRatio(aspectRatio: 1.0);
    }

    final theme = Theme.of(context);
    
    return AspectRatio(
      aspectRatio: 1.0,
      child: InkWell(
        onTap: () => _copyToClipboard(context, char),
        hoverColor: theme.colorScheme.primary.withAlpha(25),
        splashColor: theme.colorScheme.primary.withAlpha(40),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                char.character,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                char.romanization,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
