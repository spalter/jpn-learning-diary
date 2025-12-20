import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';
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
    this.useBorderedStyle = false,
  });

  @override
  State<DiaryEntryCard> createState() => _DiaryEntryCardState();
}

class _DiaryEntryCardState extends State<DiaryEntryCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 16),
        decoration: widget.useBorderedStyle
            ? _buildBorderedCardDecoration(context)
            : _buildMinimalCardDecoration(context),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          focusColor: Theme.of(context).colorScheme.primary.withAlpha(30),
          hoverColor: Colors.transparent,
          onTap: _handleCopyToClipboard,
          onLongPress: _handleEditEntry,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(context),
                const SizedBox(height: 8),
                _buildRomaji(context),
                const SizedBox(height: 8),
                _buildMeaning(context),
                if (_hasNotes) ...[
                  const SizedBox(height: 8),
                  _buildNotes(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a bordered card decoration with rounded corners and hover effects.
  ///
  /// This variant provides a more prominent card appearance with:
  /// - Rounded border with adjustable opacity based on hover state
  /// - Border radius for smooth corners
  /// - Subtle background color on hover
  BoxDecoration _buildBorderedCardDecoration(BuildContext context) {
    return BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withAlpha(
          _isHovering ? 180 : 80,
        ),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
      color: _isHovering
          ? Theme.of(context).colorScheme.primary.withAlpha(10)
          : null,
    );
  }

  /// Builds a minimal card decoration without visible borders.
  ///
  /// This variant provides a clean, simple appearance with:
  /// - Transparent bottom border (maintains spacing)
  /// - No border radius
  /// - No background color changes
  BoxDecoration _buildMinimalCardDecoration(BuildContext context) {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.primary.withAlpha(0),
          width: 2,
        ),
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
          widget.entry.japanese,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _isHovering ? Theme.of(context).colorScheme.primary : null,
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
      widget.entry.furigana != null &&
      widget.entry.furigana != widget.entry.japanese;

  /// Checks if the entry has notes
  bool get _hasNotes =>
      widget.entry.notes != null && widget.entry.notes!.isNotEmpty;

  /// Handles copying the Japanese text to clipboard
  Future<void> _handleCopyToClipboard() async {
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
  Future<void> _handleEditEntry() async {
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
