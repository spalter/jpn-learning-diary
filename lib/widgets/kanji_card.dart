import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/data/kanji_data.dart';

/// Card widget for displaying a single kanji entry.
///
/// Shows the kanji character, meanings, readings, stroke count,
/// grade level, and other relevant information in a flat design
/// matching the diary entry card style.
class KanjiCard extends StatefulWidget {
  /// The kanji data to display.
  final KanjiData kanji;

  /// Creates a kanji card.
  ///
  /// The [kanji] parameter is required and contains all the information
  /// to be displayed in the card.
  const KanjiCard({
    super.key,
    required this.kanji,
  });

  @override
  State<KanjiCard> createState() => _KanjiCardState();
}

class _KanjiCardState extends State<KanjiCard> {
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
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              width: 2,
            ),
          ),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          // Tapping the card copies the kanji character to clipboard.
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.kanji.kanji));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: ${widget.kanji.kanji}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kanji character and metadata
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large kanji character
                    Text(
                      widget.kanji.kanji,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isHovering
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(width: 16),
                    // Metadata badges
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge(
                            context,
                            '${widget.kanji.strokes} strokes',
                            Icons.draw,
                          ),
                          if (widget.kanji.grade != null)
                            _buildBadge(
                              context,
                              'Grade ${widget.kanji.grade}',
                              Icons.school,
                            ),
                          if (widget.kanji.jlptNew != null)
                            _buildBadge(
                              context,
                              'JLPT N${widget.kanji.jlptNew}',
                              Icons.flag,
                            ),
                          if (widget.kanji.freq != null)
                            _buildBadge(
                              context,
                              '#${widget.kanji.freq}',
                              Icons.trending_up,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Meanings
                _buildSection(
                  context,
                  'Meanings',
                  widget.kanji.meanings,
                  Icons.translate,
                ),
                const SizedBox(height: 12),
                
                // On readings
                _buildSection(
                  context,
                  'On readings (音読み)',
                  widget.kanji.readingsOn,
                  Icons.volume_up,
                ),
                const SizedBox(height: 12),
                
                // Kun readings
                _buildSection(
                  context,
                  'Kun readings (訓読み)',
                  widget.kanji.readingsKun,
                  Icons.speaker_notes,
                ),
                
                // WaniKani info if available
                if (widget.kanji.wkLevel != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'WaniKani Level ${widget.kanji.wkLevel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
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

  Widget _buildBadge(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
