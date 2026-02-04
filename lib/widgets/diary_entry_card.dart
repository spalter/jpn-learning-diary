// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/edit_diary_entry_dialog.dart'
    show EditDiaryEntryDialog, EditDiaryEntryResult;
import 'package:jpn_learning_diary/widgets/ruby_text.dart';

/// Card widget for displaying a single diary entry.
///
/// This widget presents a learned phrase or word with its Japanese text,
/// furigana reading, romaji transliteration, English meaning, and optional
/// notes. Users can tap to copy the text, double-tap for custom actions, or
/// long-press to edit the entry.
///
/// * [entry]: The diary entry data object containing text and meanings.
/// * [onEntryUpdated]: Callback with updated entry when the entry is modified.
/// * [onEntryDeleted]: Callback with entry ID when the entry is deleted.
class DiaryEntryCard extends StatefulWidget {
  /// The diary entry to display.
  final DiaryEntry entry;

  /// Callback when the entry is updated, passes the updated entry.
  final void Function(DiaryEntry updatedEntry)? onEntryUpdated;

  /// Callback when the entry is deleted, passes the entry ID.
  final void Function(int entryId)? onEntryDeleted;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Controls whether the card uses a bordered style with visible edges.
  ///
  /// When false (the default), the card uses a minimal flat appearance that
  /// works well in list views. When true, adds borders and hover effects.
  final bool useBorderedStyle;

  /// Creates a diary entry card.
  ///
  /// The [entry] parameter is required and contains all the information
  /// to be displayed in the card.
  const DiaryEntryCard({
    super.key,
    required this.entry,
    this.onEntryUpdated,
    this.onEntryDeleted,
    this.onTap,
    this.useBorderedStyle = false,
  });

  @override
  State<DiaryEntryCard> createState() => _DiaryEntryCardState();
}

/// Internal state for [DiaryEntryCard] that manages hover and preferences.
///
/// Tracks the mouse hover state for visual feedback and loads user preferences
/// for showing or hiding romaji and furigana.
class _DiaryEntryCardState extends State<DiaryEntryCard> {
  /// Whether the mouse is currently hovering over this card.
  bool _isHovering = false;

  /// Builds the card with content adapted to user display preferences.
  ///
  /// Loads romaji and furigana visibility settings asynchronously and renders
  /// the card content accordingly, with gesture handlers for interactions.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<bool>>(
      future: Future.wait([
        AppPreferences.getShowRomaji(),
        AppPreferences.getShowFurigana(),
      ]),
      builder: (context, snapshot) {
        final showRomaji = snapshot.data?[0] ?? true;
        final showFurigana = snapshot.data?[1] ?? true;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AppCard(
            style: widget.useBorderedStyle
                ? AppCardStyle.bordered
                : AppCardStyle.minimal,
            margin: const EdgeInsets.only(bottom: 12, right: 16),
            padding: const EdgeInsets.all(16),
            onTap: () => _handleCopyToClipboard(context),
            onDoubleTap: widget.onTap,
            onLongPress: () => _handleEditEntry(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(context, showFurigana: showFurigana),
                if (showRomaji) ...[
                  const SizedBox(height: 8),
                  _buildRomaji(context),
                ],
                const SizedBox(height: 8),
                _buildMeaning(context),
                if (_hasNotes) ...[
                  const SizedBox(height: 8),
                  _buildNotes(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the header row containing the Japanese text with optional furigana.
  Widget _buildHeaderRow(BuildContext context, {required bool showFurigana}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildJapaneseText(context, showFurigana: showFurigana),
        ),
      ],
    );
  }

  /// Builds the Japanese text display with optional inline furigana.
  ///
  /// Priority order for furigana display:
  /// 1. Legacy furigana field - if set and different from Japanese text, use it
  /// 2. Inline ruby patterns - parse `[kanji](reading)` or `「kanji」（reading）`
  /// 3. No furigana - display Japanese text as-is
  ///
  /// Applies a hover color effect when in minimal style mode.
  Widget _buildJapaneseText(
    BuildContext context, {
    required bool showFurigana,
  }) {
    // Apply hover color effect only in list mode (minimal style)
    final useHoverColor = !widget.useBorderedStyle && _isHovering;
    final textColor = useHoverColor
        ? Theme.of(context).colorScheme.primary
        : null;

    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
    );

    // Check if text contains ruby patterns [kanji](reading)
    final hasRubyPattern = RubyText.containsRubyPattern(widget.entry.japanese);

    // Priority 1: Use legacy furigana field if available
    if (_hasFurigana) {
      // Strip any ruby patterns from display text when using legacy furigana
      final displayText = hasRubyPattern
          ? RubyText.stripRubyPatterns(widget.entry.japanese)
          : widget.entry.japanese;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFurigana) _buildFurigana(context),
          Text(
            displayText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ],
      );
    }

    // Priority 2: Use inline ruby patterns if present
    if (showFurigana && hasRubyPattern) {
      return RubyText(
        text: widget.entry.japanese,
        textStyle: textStyle,
        rubyStyle: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
          height: 1.0,
        ),
      );
    }

    // Priority 3: No furigana - display text as-is (strip patterns if present)
    final displayText = hasRubyPattern
        ? RubyText.stripRubyPatterns(widget.entry.japanese)
        : widget.entry.japanese;

    return Text(
      displayText,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );
  }

  /// Builds the small furigana reading text positioned above the Japanese.
  Widget _buildFurigana(BuildContext context) {
    return Text(
      widget.entry.furigana!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Builds the italicized romaji transliteration text.
  Widget _buildRomaji(BuildContext context) {
    return Text(
      widget.entry.romaji,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Builds the English meaning text with medium font weight.
  Widget _buildMeaning(BuildContext context) {
    return Text(
      widget.entry.meaning,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  /// Builds the optional notes section with subdued styling.
  Widget _buildNotes(BuildContext context) {
    return Text(
      widget.entry.notes!,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Returns true if the entry has furigana that differs from the Japanese text.
  bool get _hasFurigana =>
      widget.entry.furigana != null &&
      widget.entry.furigana != widget.entry.japanese;

  /// Returns true if the entry has non-empty notes.
  bool get _hasNotes =>
      widget.entry.notes != null && widget.entry.notes!.isNotEmpty;

  /// Copies the Japanese text to the system clipboard and shows a snackbar.
  /// Ruby text patterns are stripped before copying.
  Future<void> _handleCopyToClipboard(BuildContext context) async {
    final cleanText = RubyText.stripRubyPatterns(widget.entry.japanese);
    await Clipboard.setData(ClipboardData(text: cleanText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $cleanText'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Opens the edit dialog and notifies the parent of changes.
  Future<void> _handleEditEntry(BuildContext context) async {
    final result = await showDialog<EditDiaryEntryResult>(
      context: context,
      builder: (context) => EditDiaryEntryDialog(entry: widget.entry),
    );

    if (result == null) return;

    if (result.wasDeleted && widget.onEntryDeleted != null) {
      widget.onEntryDeleted!(widget.entry.id!);
    } else if (result.updatedEntry != null && widget.onEntryUpdated != null) {
      widget.onEntryUpdated!(result.updatedEntry!);
    }
  }
}
