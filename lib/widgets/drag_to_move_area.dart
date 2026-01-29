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

/// A widget that enables window dragging behavior without maximize-on-double-tap.
///
/// This custom implementation wraps the content in a gesture detector that
/// communicates with the window manager to initiate window movement when
/// dragged. Unlike standard title bars, it overrides the double-tap behavior
/// to prevent maximizing the window, which is useful for custom app bars.
///
/// * [child]: The widget that should trigger the drag behavior.
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
