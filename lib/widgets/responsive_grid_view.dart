// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';

/// A responsive grid view that automatically adjusts column counts.
///
/// This widget ensures cards are always large enough to display their content
/// properly by dynamically calculating the number of columns based on the
/// available width and a minimum card width constraint. It fits as many
/// columns as possible while maintaining the specified aspect ratio.
///
/// * [itemCount]: The total number of items in the grid.
/// * [itemBuilder]: Function that builds a widget for a given index.
/// * [minCardWidth]: The minimum width in logical pixels for each grid item (default 280).
/// * [childAspectRatio]: The ratio of cross-axis to main-axis extent of each child (default 4/3).
class ResponsiveGridView extends StatelessWidget {
  /// The items to display in the grid.
  final int itemCount;

  /// Builder function for creating each grid item.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Minimum width for each card to ensure content displays properly.
  /// Defaults to 280px.
  final double minCardWidth;

  /// Aspect ratio for each card (width / height).
  /// Defaults to 4/3 (cards are slightly wider than tall).
  final double childAspectRatio;

  /// Padding around the entire grid.
  /// Defaults to 8px on all sides.
  final EdgeInsetsGeometry padding;

  /// Spacing between cards horizontally.
  /// Defaults to 8px.
  final double crossAxisSpacing;

  /// Spacing between cards vertically.
  /// Defaults to 8px.
  final double mainAxisSpacing;

  const ResponsiveGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minCardWidth = 280.0,
    this.childAspectRatio = 4 / 3,
    this.padding = const EdgeInsets.all(8),
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = calculateCrossAxisCount(
          constraints.maxWidth,
          minCardWidth,
          crossAxisSpacing,
          padding,
        );

        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }

  /// Calculates how many cards can fit across the available width.
  ///
  /// Based on the minimum card width, this determines the optimal number of
  /// columns that can fit while maintaining the specified aspect ratio.
  /// 
  /// This is a public static method so it can be reused in other contexts
  /// like SliverGrid layouts.
  static int calculateCrossAxisCount(
    double availableWidth,
    double minCardWidth,
    double spacing,
    EdgeInsetsGeometry padding,
  ) {
    // Calculate total horizontal padding
    final horizontalPadding = padding is EdgeInsets
        ? padding.left + padding.right
        : 16.0; // Default fallback

    // Calculate available width for cards (excluding padding)
    final double usableWidth = availableWidth - horizontalPadding;

    // Calculate how many cards can fit
    // Formula: (width + spacing) fits N cards, minus one spacing at the end
    final int count = ((usableWidth + spacing) / (minCardWidth + spacing)).floor();

    // Ensure at least 1 column
    return count < 1 ? 1 : count;
  }
}
