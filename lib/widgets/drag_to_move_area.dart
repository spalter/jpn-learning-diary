// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// A widget for drag to move window without double-tap to maximize.
///
/// This is a custom implementation that replicates [DragToMoveArea] from
/// window_manager but without the double-tap maximize behavior.
///
/// {@tool snippet}
///
/// The sample creates a draggable area for moving the window.
///
/// ```dart
/// DragOnlyMoveArea(
///   child: Container(
///     width: 300,
///     height: 32,
///     color: Colors.red,
///   ),
/// )
/// ```
/// {@end-tool}
class DragOnlyMoveArea extends StatelessWidget {
  const DragOnlyMoveArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        windowManager.startDragging();
      },
      // No onDoubleTap handler - deliberately omitted to prevent maximize
      child: child,
    );
  }
}
