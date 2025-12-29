import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/edit_diary_entry_dialog.dart';

/// Card widget for displaying a single diary entry.
///
/// Shows the Japanese text, furigana reading, romaji, English meaning,
/// and optional notes for a learned phrase or word. Cards are interactive
/// and display the date when the entry was added.
class DiaryEntryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AppCard(
      style: useBorderedStyle ? AppCardStyle.bordered : AppCardStyle.minimal,
      margin: const EdgeInsets.only(bottom: 12, right: 16),
      padding: const EdgeInsets.all(16),
      onTap: () => _handleCopyToClipboard(context),
      onDoubleTap: onTap,
      onLongPress: () => _handleEditEntry(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(context),
          const SizedBox(height: 8),
          _buildRomaji(context),
          const SizedBox(height: 8),
          _buildMeaning(context),
          if (_hasNotes) ...[const SizedBox(height: 8), _buildNotes(context)],
        ],
      ),
    );
  }

  /// Builds the header row with Japanese text, furigana, and date badge
  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: _buildJapaneseText(context))],
    );
  }

  /// Builds the Japanese text with optional furigana
  Widget _buildJapaneseText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasFurigana) _buildFurigana(context),
        Text(
          entry.japanese,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Builds the furigana text above the Japanese text
  Widget _buildFurigana(BuildContext context) {
    return Text(
      entry.furigana!,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Builds the romaji text
  Widget _buildRomaji(BuildContext context) {
    return Text(
      entry.romaji,
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
      entry.meaning,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  /// Builds the notes section if available
  Widget _buildNotes(BuildContext context) {
    return Text(
      entry.notes!,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Checks if the entry has furigana that differs from the Japanese text
  bool get _hasFurigana =>
      entry.furigana != null && entry.furigana != entry.japanese;

  /// Checks if the entry has notes
  bool get _hasNotes => entry.notes != null && entry.notes!.isNotEmpty;

  /// Handles copying the Japanese text to clipboard
  Future<void> _handleCopyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: entry.japanese));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${entry.japanese}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handles opening the edit dialog for the entry
  Future<void> _handleEditEntry(BuildContext context) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => EditDiaryEntryDialog(entry: entry),
    );
    // Refresh the parent list if entry was modified.
    if (updated == true && onUpdate != null) {
      onUpdate!();
    }
  }
}
