import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/edit_diary_entry_dialog.dart';

/// Card widget for displaying a single diary entry.
///
/// Shows the Japanese text, furigana reading, romaji, English meaning,
/// and optional notes for a learned phrase or word. Cards are interactive
/// and display the date when the entry was added.
class DiaryEntryCard extends StatefulWidget {
  /// The diary entry to display.
  final DiaryEntry entry;

  /// Callback when the entry is updated.
  final VoidCallback? onUpdate;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to use a bordered card style with hover effects.
  /// Defaults to false for a minimal appearance.
  final bool useBorderedStyle;

  /// Creates a diary entry card.
  ///
  /// The [entry] parameter is required and contains all the information
  /// to be displayed in the card.
  const DiaryEntryCard({
    super.key,
    required this.entry,
    this.onUpdate,
    this.onTap,
    this.useBorderedStyle = false,
  });

  @override
  State<DiaryEntryCard> createState() => _DiaryEntryCardState();
}

class _DiaryEntryCardState extends State<DiaryEntryCard> {
  bool _isHovering = false;

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
            style: widget.useBorderedStyle ? AppCardStyle.bordered : AppCardStyle.minimal,
            margin: const EdgeInsets.only(bottom: 12, right: 16),
            padding: const EdgeInsets.all(16),
            onTap: () => _handleCopyToClipboard(context),
            onDoubleTap: widget.onTap,
            onLongPress: () => _handleEditEntry(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(context, showFurigana: showFurigana),
                if (showRomaji) ...[const SizedBox(height: 8), _buildRomaji(context)],
                const SizedBox(height: 8),
                _buildMeaning(context),
                if (_hasNotes) ...[const SizedBox(height: 8), _buildNotes(context)],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the header row with Japanese text, furigana, and date badge
  Widget _buildHeaderRow(BuildContext context, {required bool showFurigana}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: _buildJapaneseText(context, showFurigana: showFurigana))],
    );
  }

  /// Builds the Japanese text with optional furigana
  Widget _buildJapaneseText(BuildContext context, {required bool showFurigana}) {
    // Apply hover color effect only in list mode (minimal style)
    final useHoverColor = !widget.useBorderedStyle && _isHovering;
    final textColor = useHoverColor ? Theme.of(context).colorScheme.primary : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFurigana && _hasFurigana) _buildFurigana(context),
        Text(
          widget.entry.japanese,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  /// Builds the furigana text above the Japanese text
  Widget _buildFurigana(BuildContext context) {
    return Text(
      widget.entry.furigana!,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Builds the romaji text
  Widget _buildRomaji(BuildContext context) {
    return Text(
      widget.entry.romaji,
      style: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Builds the English meaning text
  Widget _buildMeaning(BuildContext context) {
    return Text(
      widget.entry.meaning,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  /// Builds the notes section if available
  Widget _buildNotes(BuildContext context) {
    return Text(
      widget.entry.notes!,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Checks if the entry has furigana that differs from the Japanese text
  bool get _hasFurigana =>
      widget.entry.furigana != null && widget.entry.furigana != widget.entry.japanese;

  /// Checks if the entry has notes
  bool get _hasNotes => widget.entry.notes != null && widget.entry.notes!.isNotEmpty;

  /// Handles copying the Japanese text to clipboard
  Future<void> _handleCopyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.entry.japanese));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${widget.entry.japanese}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handles opening the edit dialog for the entry
  Future<void> _handleEditEntry(BuildContext context) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => EditDiaryEntryDialog(entry: widget.entry),
    );
    // Refresh the parent list if entry was modified.
    if (updated == true && widget.onUpdate != null) {
      widget.onUpdate!();
    }
  }
}
