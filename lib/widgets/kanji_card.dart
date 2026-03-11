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
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card widget for displaying a single kanji character entry.
///
/// This widget presents kanji data in a clean, flat design that matches the
/// diary entry card style throughout the app. It serves as a comprehensive
/// summary of a kanji character's properties, showing readings, meanings,
/// and JLPT levels.
///
/// * [kanji]: The kanji data object containing character details.
class KanjiCard extends StatefulWidget {
  /// The kanji data to display.
  final KanjiData kanji;

  /// Optional callback for tap action. overrides default copy behavior.
  final VoidCallback? onTap;

  /// Optional callback for double-tap action.
  final VoidCallback? onDoubleTap;

  /// Creates a kanji card.
  ///
  /// The [kanji] parameter is required and contains all the information
  /// to be displayed in the card.
  const KanjiCard({
    super.key,
    required this.kanji,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<KanjiCard> createState() => _KanjiCardState();
}

/// Internal state for [KanjiCard] that manages hover interactions.
///
/// Tracks the mouse hover state to provide visual feedback when the user
/// hovers over the card in minimal (list) mode.
class _KanjiCardState extends State<KanjiCard> {
  /// Whether the mouse is currently hovering over this card.
  bool _isHovering = false;

  /// Builds the kanji card with hover effects and interaction handlers.
  ///
  /// The card adapts its appearance based on the style setting, applying a
  /// subtle color change on hover when in minimal mode. Gesture handlers
  /// enable tap-to-copy, and long-press-to-lookup.
  @override
  Widget build(BuildContext context) {
    // Apply hover color effect to minimal style (now default)
    final useHoverColor = _isHovering;
    final kanjiColor = useHoverColor
        ? Theme.of(context).colorScheme.primary
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AppCard(
        style: AppCardStyle.minimal,
        margin: const EdgeInsets.only(bottom: 12, right: 16),
        padding: const EdgeInsets.all(16),
        onTap: widget.onTap ?? () => _handleCopyToClipboard(context),
        onDoubleTap: widget.onDoubleTap,
        onLongPress: () => _handleOpenDictionary(context),
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
                    color: kanjiColor,
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
                    color: Theme.of(context).colorScheme.primary.withAlpha(179),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'WaniKani Level ${widget.kanji.wkLevel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(179),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Copies the kanji character to the system clipboard and shows a snackbar.
  Future<void> _handleCopyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.kanji.kanji));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${widget.kanji.kanji}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Opens the kanji in the Takoboto online dictionary for detailed information.
  ///
  /// Launches the default browser with a pre-filled search query for this kanji.
  Future<void> _handleOpenDictionary(BuildContext context) async {
    final encodedKanji = Uri.encodeComponent(widget.kanji.kanji);
    final url = Uri.parse('https://takoboto.jp/?q=$encodedKanji');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open URL: $url'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Builds a small badge with an icon and label to display kanji metadata.
  ///
  /// Used for stroke count, grade level, JLPT level, and frequency ranking.
  Widget _buildBadge(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Builds a labeled section with an icon, title, and content text.
  ///
  /// Creates a consistent layout for displaying meanings, on readings, and
  /// kun readings with visual hierarchy.
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
          color: Theme.of(context).colorScheme.primary.withAlpha(179),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(179),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(content, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
