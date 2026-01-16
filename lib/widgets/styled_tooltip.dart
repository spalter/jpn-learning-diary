// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';

/// A tooltip widget styled to match the app's colorscheme.
///
/// Wraps the standard [Tooltip] widget with consistent styling using
/// the current theme's surface and primary colors.
class StyledTooltip extends StatelessWidget {
  /// The message to display in the tooltip.
  final String message;

  /// The widget that triggers the tooltip on hover.
  final Widget child;

  /// Optional vertical offset from the widget.
  final double? verticalOffset;

  /// Optional wait duration before showing the tooltip.
  final Duration? waitDuration;

  const StyledTooltip({
    super.key,
    required this.message,
    required this.child,
    this.verticalOffset,
    this.waitDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      verticalOffset: verticalOffset,
      waitDuration: waitDuration,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(100),
        ),
      ),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      ),
      child: child,
    );
  }
}
