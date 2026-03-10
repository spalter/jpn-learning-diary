// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';

/// A unified card widget that provides consistent styling across the app.
///
/// This widget acts as the foundational container for almost all list items
/// and content blocks in the application. It centralizes styling logic to
/// ensure a cohesive look and feel across different card types.
///
/// * [child]: The content to display inside the card.
/// * [style]: The visual style variant (bordered, minimal, elevated).
/// * [onTap]: Callback triggered when the card is tapped.
/// * [onDoubleTap]: Callback triggered on double-tap events.
/// * [onLongPress]: Callback triggered on long-press events.
class AppCard extends StatefulWidget {
  /// The child widget to display inside the card.
  final Widget child;

  /// The style variant of the card.
  final AppCardStyle style;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Optional callback when the card is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Optional callback when the card is long-pressed.
  final VoidCallback? onLongPress;

  /// Optional margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Optional padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Whether to show hover effects.
  final bool enableHoverEffects;

  /// Custom elevation for elevated cards. Only used when style is [AppCardStyle.elevated].
  final double? elevation;

  /// Whether the card is selected/highlighted.
  final bool isSelected;

  /// Creates a unified app card with consistent styling.
  const AppCard({
    super.key,
    required this.child,
    this.style = AppCardStyle.bordered,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.enableHoverEffects = true,
    this.elevation,
    this.isSelected = false,
  });

  /// Creates a bordered card with hover effects.
  const AppCard.bordered({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.margin,
    this.padding = const EdgeInsets.all(16),
  }) : style = AppCardStyle.bordered,
       enableHoverEffects = true,
       elevation = null,
       isSelected = false;

  /// Creates a minimal card without visible borders.
  const AppCard.minimal({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.margin,
    this.padding = const EdgeInsets.all(16),
  }) : style = AppCardStyle.minimal,
       enableHoverEffects = true,
       elevation = null,
       isSelected = false;

  /// Creates an elevated Material card.
  const AppCard.elevated({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
    this.isSelected = false,
  }) : style = AppCardStyle.elevated,
       enableHoverEffects = true;

  /// Creates a stat card for displaying statistics on dashboard.
  const AppCard.stat({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding = const EdgeInsets.all(24),
  }) : style = AppCardStyle.stat,
       enableHoverEffects = false,
       elevation = null,
       isSelected = false,
       onDoubleTap = null,
       onLongPress = null;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final hasInteraction =
        widget.onTap != null ||
        widget.onDoubleTap != null ||
        widget.onLongPress != null;

    Widget content = widget.child;

    // Wrap in padding if specified
    if (widget.padding != null) {
      content = Padding(padding: widget.padding!, child: content);
    }

    final decoration = _buildDecoration(context);

    Widget card;
    if (hasInteraction) {
      card = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            onLongPress: widget.onLongPress,
            focusColor: Theme.of(context).colorScheme.primary.withAlpha(30),
            hoverColor: widget.style == AppCardStyle.elevated
                ? null
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: content,
          ),
        ),
      );
    } else {
      card = Container(
        decoration: decoration,
        child: content,
      );
    }

    // Wrap in MouseRegion for hover effects
    if (widget.enableHoverEffects) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: card,
      );
    }

    // Apply margin if specified
    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    return card;
  }

  /// Builds the appropriate decoration based on the card style.
  Decoration _buildDecoration(BuildContext context) {
    switch (widget.style) {
      case AppCardStyle.bordered:
        return _buildBorderedDecoration(context);
      case AppCardStyle.minimal:
        return _buildMinimalDecoration(context);
      case AppCardStyle.elevated:
        return _buildElevatedDecoration(context);
      case AppCardStyle.stat:
        return _buildStatDecoration(context);
    }
  }

  /// Builds a bordered card decoration with rounded corners and hover effects.
  BoxDecoration _buildBorderedDecoration(BuildContext context) {
    // Determine border color and width based on selection and hover state
    final Color borderColor;
    final double borderWidth;

    if (widget.isSelected) {
      // Selected state: use solid primary color with thicker border
      borderColor = Theme.of(context).colorScheme.primary;
      borderWidth = 2.5;
    } else if (_isHovering) {
      borderColor = Theme.of(context).colorScheme.primary.withAlpha(180);
      borderWidth = 1;
    } else {
      borderColor = Theme.of(context).colorScheme.primary.withAlpha(80);
      borderWidth = 1;
    }

    return BoxDecoration(
      border: Border.all(color: borderColor, width: borderWidth),
      borderRadius: BorderRadius.circular(12),
      color: widget.isSelected
          ? Theme.of(context).colorScheme.primary.withAlpha(20)
          : (_isHovering
              ? Theme.of(context).colorScheme.primary.withAlpha(10)
              : null),
    );
  }

  /// Builds a minimal card decoration without visible borders.
  BoxDecoration _buildMinimalDecoration(BuildContext context) {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.primary.withAlpha(0),
          width: 2,
        ),
      ),
    );
  }

  /// Builds an elevated Material card decoration.
  BoxDecoration _buildElevatedDecoration(BuildContext context) {
    final elevation = widget.isSelected ? 8.0 : (widget.elevation ?? 2.0);
    final borderWidth = _isHovering ? 2.0 : 1.0;
    final borderColor = _isHovering
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primary.withAlpha(0);

    return BoxDecoration(
      color: widget.isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface.withAlpha(100),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.2 * elevation).round()),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation / 2),
        ),
      ],
    );
  }

  /// Builds a stat card decoration for dashboard statistics.
  BoxDecoration _buildStatDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withAlpha(80),
        width: 1,
      ),
    );
  }
}

/// Defines the visual style of an [AppCard].
enum AppCardStyle {
  /// A card with a visible border and hover effects.
  bordered,

  /// A minimal card without visible borders.
  minimal,

  /// An elevated Material card with shadow.
  elevated,

  /// A stat card for displaying statistics.
  stat,
}
