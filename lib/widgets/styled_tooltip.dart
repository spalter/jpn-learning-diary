// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';

/// A tooltip widget styled to match the app's color scheme.
///
/// Wraps the standard Flutter Tooltip widget with specific decoration logic
/// to ensure it aligns with the application's visual theme, using surface
/// colors and appropriate text contrast.
///
/// * [message]: The text message to display inside the tooltip.
/// * [child]: The widget that triggers the tooltip on hover or long press.
/// * [verticalOffset]: The vertical distance between the widget and the tooltip.
/// * [waitDuration]: The length of time a pointer must hover before the tooltip is shown.
/// * [preferBelow]: Whether the tooltip should attempt to display below the widget.
class StyledTooltip extends StatelessWidget {
  /// The message to display in the tooltip.
  final String message;

  /// The widget that triggers the tooltip on hover.
  final Widget child;

  /// Optional vertical offset from the widget.
  final double? verticalOffset;

  /// Optional wait duration before showing the tooltip.
  final Duration? waitDuration;

  /// Whether the tooltip should prefer to appear below the widget.
  /// Defaults to true. Set to false to prefer showing above.
  final bool preferBelow;

  const StyledTooltip({
    super.key,
    required this.message,
    required this.child,
    this.verticalOffset,
    this.waitDuration,
    this.preferBelow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      verticalOffset: verticalOffset,
      waitDuration: waitDuration,
      preferBelow: preferBelow,
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
