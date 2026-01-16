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
import 'package:jpn_learning_diary/models/word_data.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card widget for displaying a single Japanese word entry.
///
/// This widget presents vocabulary data in a clean, flat design that matches
/// the kanji card style throughout the app. The card displays the written form
/// prominently, along with readings, meanings, and frequency indicators. Users
/// can tap to copy the word, double-tap to search, or long-press to open an
/// external dictionary.
class WordCard extends StatefulWidget {
  /// The word data to display.
  final WordData word;

  /// Whether to use a bordered card style with hover effects.
  /// Defaults to false for a minimal appearance.
  final bool useBorderedStyle;

  /// Global key to access the navigation bar for inserting search text.
  final GlobalKey<AppNavigationBarState>? navigationBarKey;

  /// Creates a word card.
  ///
  /// The [word] parameter is required and contains all the information
  /// to be displayed in the card.
  const WordCard({
    super.key,
    required this.word,
    this.useBorderedStyle = false,
    this.navigationBarKey,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

/// Internal state for [WordCard] that manages hover interactions.
///
/// Tracks the mouse hover state to provide visual feedback when the user
/// hovers over the card in minimal (list) mode.
class _WordCardState extends State<WordCard> {
  /// Whether the mouse is currently hovering over this card.
  bool _isHovering = false;

  /// Builds the word card with hover effects and interaction handlers.
  ///
  /// The card adapts its appearance based on the style setting, applying a
  /// subtle color change on hover when in minimal mode. Gesture handlers
  /// enable tap-to-copy, double-tap-to-search, and long-press-to-lookup.
  @override
  Widget build(BuildContext context) {
    // Apply hover color effect only in list mode (minimal style)
    final useHoverColor = !widget.useBorderedStyle && _isHovering;
    final writtenColor =
        useHoverColor ? Theme.of(context).colorScheme.primary : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AppCard(
        style:
            widget.useBorderedStyle ? AppCardStyle.bordered : AppCardStyle.minimal,
        margin: const EdgeInsets.only(bottom: 12, right: 16),
        padding: const EdgeInsets.all(16),
        onTap: () => _handleCopyToClipboard(context),
        onDoubleTap: () => _handleInsertIntoSearch(context),
        onLongPress: () => _handleOpenDictionary(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Written form and metadata
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large written form (kanji)
                Text(
                  widget.word.written,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: writtenColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Metadata badges
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.word.isCommon)
                        _buildBadge(context, 'Common', Icons.star),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pronunciations
            if (widget.word.pronunciations.isNotEmpty) ...[
              _buildSection(
                context,
                'Readings (読み方)',
                widget.word.pronunciationsString,
                Icons.volume_up,
              ),
              const SizedBox(height: 12),
            ],

            // Meanings
            _buildSection(
              context,
              'Meanings',
              widget.word.meaningsString,
              Icons.translate,
              maxLines: 5,
            ),

            // Priority info if available
            if (widget.word.hasPriority) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary.withAlpha(179),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.word.priorities.join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary.withAlpha(179),
                        fontStyle: FontStyle.italic,
                      ),
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

  /// Copies the word's written form to the system clipboard and shows a snackbar.
  Future<void> _handleCopyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.word.written));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${widget.word.written}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Inserts the word into the navigation bar's search field for quick lookup.
  ///
  /// Falls back to showing a message if the navigation bar reference is unavailable.
  void _handleInsertIntoSearch(BuildContext context) {
    if (widget.navigationBarKey?.currentState != null) {
      widget.navigationBarKey!.currentState!.insertSearchText(widget.word.written);
    } else {
      // Fallback: show a message if navigation bar is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search field not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Opens the word in the Takoboto online dictionary for detailed information.
  ///
  /// Launches the default browser with a pre-filled search query for this word.
  Future<void> _handleOpenDictionary(BuildContext context) async {
    final encodedWord = Uri.encodeComponent(widget.word.written);
    final url = Uri.parse('https://takoboto.jp/?q=$encodedWord');
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

  /// Builds a small badge with an icon and label to indicate word properties.
  ///
  /// Used to display metadata like "Common" to highlight frequently used words.
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
  /// Creates a consistent layout for displaying readings and meanings, with
  /// optional line clamping via [maxLines] to prevent overflow in dense lists.
  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon, {
    int? maxLines,
  }) {
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
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
