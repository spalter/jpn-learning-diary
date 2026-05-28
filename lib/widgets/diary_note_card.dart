// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/diary_note.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/edit_diary_entry_dialog.dart'
    show EditDiaryEntryDialog, EditDiaryEntryResult;
import 'package:jpn_learning_diary/widgets/ruby_text.dart';

class DiaryNoteCard extends StatefulWidget {
  final DiaryNote note;
  final void Function(DiaryNote updatedNote)? onNoteUpdated;
  final void Function(int noteId)? onNoteDeleted;
  final bool showFurigana;

  const DiaryNoteCard({
    super.key,
    required this.note,
    this.onNoteUpdated,
    this.onNoteDeleted,
    this.showFurigana = false,
  });

  @override
  State<DiaryNoteCard> createState() => _DiaryNoteCardState();
}

class _DiaryNoteCardState extends State<DiaryNoteCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AppCard(
        style: AppCardStyle.minimal, // distinct from minimal for notes
        margin: const EdgeInsets.only(bottom: 12, right: 16),
        padding: const EdgeInsets.all(16),
        onTap: () => _handleCopyToClipboard(context),
        onLongPress: () => _handleEditNote(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(context),
            const SizedBox(height: 8),
            _buildJapaneseContent(context, showFurigana: widget.showFurigana),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final useHoverColor = _isHovering;
    final textColor = useHoverColor
        ? Theme.of(context).colorScheme.primary
        : null;

    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
    );

    final hasRubyPattern = RubyText.containsRubyPattern(widget.note.title);

    if (widget.showFurigana && hasRubyPattern) {
      return RubyText(
        text: widget.note.title,
        textStyle: textStyle,
        rubyStyle: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
          height: 1.0,
        ),
      );
    }

    final displayText = hasRubyPattern
        ? RubyText.stripRubyPatterns(widget.note.title)
        : widget.note.title;

    return Text(
      displayText,
      style: textStyle,
    );
  }

  Widget _buildJapaneseContent(
    BuildContext context, {
    required bool showFurigana,
  }) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(height: 1.5);

    final hasRubyPattern = RubyText.containsRubyPattern(
      widget.note.contentJapanese,
    );

    if (showFurigana && hasRubyPattern) {
      return RubyText(
        text: widget.note.contentJapanese,
        textStyle: textStyle,
        rubyStyle: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.primary,
          height: 1.0,
        ),
      );
    }

    final displayText = hasRubyPattern
        ? RubyText.stripRubyPatterns(widget.note.contentJapanese)
        : widget.note.contentJapanese;

    return Text(displayText, style: textStyle);
  }

  Future<void> _handleCopyToClipboard(BuildContext context) async {
    final cleanText = RubyText.stripRubyPatterns(widget.note.contentJapanese);
    await Clipboard.setData(ClipboardData(text: cleanText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Text copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleEditNote(BuildContext context) async {
    final result = await showDialog<EditDiaryEntryResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.surface.withAlpha(200),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: EditDiaryEntryDialog(
          note: widget.note,
        ), // We will update the dialog to support Note
      ),
    );

    if (result == null) return;

    if (result.wasDeleted && widget.onNoteDeleted != null) {
      widget.onNoteDeleted!(widget.note.id!);
    } else if (result.updatedNote != null && widget.onNoteUpdated != null) {
      widget.onNoteUpdated!(result.updatedNote!);
    }
  }
}
