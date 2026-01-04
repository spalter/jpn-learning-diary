import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card widget for displaying a single kanji entry.
///
/// Shows the kanji character, meanings, readings, stroke count,
/// grade level, and other relevant information in a flat design
/// matching the diary entry card style.
class KanjiCard extends StatelessWidget {
  /// The kanji data to display.
  final KanjiData kanji;

  /// Whether to use a bordered card style with hover effects.
  /// Defaults to false for a minimal appearance.
  final bool useBorderedStyle;

  /// Global key to access the navigation bar for inserting search text.
  final GlobalKey<AppNavigationBarState>? navigationBarKey;

  /// Creates a kanji card.
  ///
  /// The [kanji] parameter is required and contains all the information
  /// to be displayed in the card.
  const KanjiCard({
    super.key,
    required this.kanji,
    this.useBorderedStyle = false,
    this.navigationBarKey,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: useBorderedStyle ? AppCardStyle.bordered : AppCardStyle.minimal,
      margin: const EdgeInsets.only(bottom: 12, right: 16),
      padding: const EdgeInsets.all(16),
      onTap: () => _handleCopyToClipboard(context),
      onDoubleTap: () => _handleInsertIntoSearch(context),
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
                kanji.kanji,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
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
                      '${kanji.strokes} strokes',
                      Icons.draw,
                    ),
                    if (kanji.grade != null)
                      _buildBadge(
                        context,
                        'Grade ${kanji.grade}',
                        Icons.school,
                      ),
                    if (kanji.jlptNew != null)
                      _buildBadge(
                        context,
                        'JLPT N${kanji.jlptNew}',
                        Icons.flag,
                      ),
                    if (kanji.freq != null)
                      _buildBadge(context, '#${kanji.freq}', Icons.trending_up),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Meanings
          _buildSection(context, 'Meanings', kanji.meanings, Icons.translate),
          const SizedBox(height: 12),

          // On readings
          _buildSection(
            context,
            'On readings (音読み)',
            kanji.readingsOn,
            Icons.volume_up,
          ),
          const SizedBox(height: 12),

          // Kun readings
          _buildSection(
            context,
            'Kun readings (訓読み)',
            kanji.readingsKun,
            Icons.speaker_notes,
          ),

          // WaniKani info if available
          if (kanji.wkLevel != null) ...[
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
                  'WaniKani Level ${kanji.wkLevel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withAlpha(179),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Handles copying the kanji character to clipboard
  Future<void> _handleCopyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: kanji.kanji));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${kanji.kanji}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handles inserting the kanji into the navigation bar search field
  void _handleInsertIntoSearch(BuildContext context) {
    if (navigationBarKey?.currentState != null) {
      navigationBarKey!.currentState!.insertSearchText(kanji.kanji);
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

  /// Handles opening the kanji in Takoboto dictionary
  Future<void> _handleOpenDictionary(BuildContext context) async {
    final encodedKanji = Uri.encodeComponent(kanji.kanji);
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

  Widget _buildBadge(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.primary,
            ),
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
