// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';

/// A wrapper widget that provides expandable and collapsible vertical layout.
///
/// This widget allows users to toggle the visibility of its content between a
/// minimized state and an expanded state. It is primarily used to manage screen
/// real estate in complex views like study pages, providing smooth height
/// transitions and a clean UI for hiding optional content.
///
/// * [child]: The content widget to be expanded or collapsed.
/// * [isCollapsed]: The current collapsed state of the widget.
/// * [onCollapseChanged]: Callback function triggered when the state toggles.
/// * [collapsedHeight]: The height of the widget when collapsed (default 40.0).
/// * [expandedHeight]: The height of the widget when expanded (default 200.0).
/// * [collapseIcon]: Optional custom icon widget for the toggle button.
class CollapsibleSection extends StatefulWidget {
  final Widget child;
  final bool isCollapsed;
  final ValueChanged<bool> onCollapseChanged;
  final double collapsedHeight;
  final double expandedHeight;
  final Widget? collapseIcon;

  const CollapsibleSection({
    super.key,
    required this.child,
    required this.isCollapsed,
    required this.onCollapseChanged,
    this.collapsedHeight = 40.0,
    this.expandedHeight = 200.0,
    this.collapseIcon,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary.withAlpha(80);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(
            minHeight: widget.collapsedHeight,
            maxHeight: widget.isCollapsed
                ? widget.collapsedHeight
                : widget.expandedHeight,
          ),
          child: widget.child,
        ),
        if (!widget.isCollapsed) _buildCollapseHandle(context, borderColor),
      ],
    );
  }

  Widget _buildCollapseHandle(BuildContext context, Color borderColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onCollapseChanged(true),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
