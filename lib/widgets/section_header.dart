// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';

/// A reusable section header widget with optional icon.
///
/// Provides consistent styling for section titles across the application,
/// ensuring uniform typography and spacing. It supports an optional leading
/// icon to visually distinguish different content areas.
///
/// * [title]: The text string to display as the header.
/// * [icon]: Optional icon data to display before the title.
/// * [bottomPadding]: The amount of vertical space below the header (default 16).
class SectionHeader extends StatelessWidget {
  /// The title text to display.
  final String title;

  /// Optional icon to display before the title.
  final IconData? icon;

  /// Optional bottom padding. Defaults to 16.
  final double bottomPadding;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.bottomPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
