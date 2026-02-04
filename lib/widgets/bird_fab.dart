// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/widgets/edit_diary_entry_dialog.dart'
    show EditDiaryEntryDialog, EditDiaryEntryResult;
import 'package:jpn_learning_diary/widgets/styled_tooltip.dart';

/// A floating action button featuring the bird mascot.
///
/// This widget provides a friendly primary action button for the app, typically
/// used to create new entries. It features a custom image asset of the bird
/// mascot and applies a subtle bobbing animation when hovered over, adding
/// character to the interface.
///
/// * [onEntryCreated]: Optional callback with the new entry when successfully created.
class BirdFab extends StatefulWidget {
  /// Optional callback when a diary entry is successfully created.
  final void Function(DiaryEntry newEntry)? onEntryCreated;

  const BirdFab({super.key, this.onEntryCreated});

  @override
  State<BirdFab> createState() => _BirdFabState();
}

class _BirdFabState extends State<BirdFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovering = false;

  static const _tooltipMessages = [
    'Let\'s add a new diary entry!',
    'Time to write in your diary!',
    'What did you learn today?',
    'Let\'s document your progress!',
    'Add a new entry to your journey!',
    'Capture today\'s learning moments!',
    'Share what\'s on your mind!',
    'メモを取ろう！',
    '今日は何を学んだ？',
  ];

  String _tooltipMessage = _tooltipMessages[0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Bobbing animation: scale up then back to normal
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.20,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.20,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    if (!_isHovering) {
      _isHovering = true;
      setState(() {
        _tooltipMessage =
            _tooltipMessages[Random().nextInt(_tooltipMessages.length)];
      });
      _controller.forward(from: 0);
    }
  }

  void _onHoverEnd() {
    _isHovering = false;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: GestureDetector(
        onTap: () => _handleAddEntry(context),
        child: StyledTooltip(
          message: _tooltipMessage,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Image.asset(
              'lib/assets/bird_plus.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddEntry(BuildContext context) async {
    final result = await showDialog<EditDiaryEntryResult>(
      context: context,
      builder: (context) => const EditDiaryEntryDialog(),
    );

    if (result?.updatedEntry != null && widget.onEntryCreated != null) {
      widget.onEntryCreated!(result!.updatedEntry!);
    }
  }
}
