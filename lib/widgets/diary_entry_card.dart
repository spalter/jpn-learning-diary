import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

  /// Creates a diary entry card.
  ///
  /// The [entry] parameter is required and contains all the information
  /// to be displayed in the card.
  const DiaryEntryCard({
    super.key,
    required this.entry,
    this.onUpdate,
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
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(0),
              width: 2,
            ),
          ),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          // Single tap: Copy Japanese text to clipboard.
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.entry.japanese));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: ${widget.entry.japanese}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          // Long press: Open edit dialog to modify or delete the entry.
          onLongPress: () async {
            final updated = await showDialog<bool>(
              context: context,
              builder: (context) => EditDiaryEntryDialog(entry: widget.entry),
            );
            // Refresh the parent list if entry was modified.
            if (updated == true && widget.onUpdate != null) {
              widget.onUpdate!();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Japanese text with furigana
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.entry.furigana != null && widget.entry.furigana != widget.entry.japanese)
                            Text(
                              widget.entry.furigana!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          Text(
                            widget.entry.japanese,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isHovering ? Theme.of(context).colorScheme.primary : null,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(widget.entry.dateAdded),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Romaji
                Text(
                  widget.entry.romaji,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Meaning
                Text(
                  widget.entry.meaning,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                
                // Notes (if available)
                if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.entry.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
