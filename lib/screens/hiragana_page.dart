import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/data/hiragana_data.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';
import 'package:jpn_learning_diary/widgets/character_card.dart';

/// Hiragana alphabet learning and practice page.
///
/// Displays the hiragana character set and provides tools for
/// learning and practicing hiragana reading and writing.
class HiraganaPage extends StatelessWidget {
  const HiraganaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Base Characters Section
              _buildSection(
                context,
                title: 'Base Characters (Gojūon)',
                characters: HiraganaData.baseCharacters,
              ),
              const SizedBox(height: 32),
              
              // Dakuten Section
              _buildSection(
                context,
                title: 'Dakuten (゛)',
                characters: HiraganaData.dakutenCharacters,
              ),
              const SizedBox(height: 32),
              
              // Han-dakuten Section
              _buildSection(
                context,
                title: 'Han-dakuten (゜)',
                characters: HiraganaData.hanDakutenCharacters,
              ),
              const SizedBox(height: 32),
              
              // Combinations Section
              _buildSection(
                context,
                title: 'Combinations (Yōon)',
                characters: HiraganaData.combinations,
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<CharacterData> characters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive card size
            // Base size: 70x100, Max size: 84x120 (20% bigger)
            final availableWidth = constraints.maxWidth;
            final spacing = 8.0;
            
            // Try to fit as many cards as possible, then adjust size
            int cardsPerRow = (availableWidth / (70 + spacing)).floor();
            cardsPerRow = cardsPerRow < 1 ? 1 : cardsPerRow;
            
            // Calculate card width based on available space
            double cardWidth = (availableWidth - (cardsPerRow - 1) * spacing) / cardsPerRow;
            
            // Constrain between min (70) and max (84)
            cardWidth = cardWidth.clamp(70.0, 84.0);
            
            // Maintain aspect ratio (70:100 = 0.7)
            double cardHeight = cardWidth / 0.7;
            
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: characters.map((char) {
                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: CharacterCard(
                    character: char.character,
                    romanization: char.romanization,
                    onTap: () => _copyToClipboard(context, char),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, CharacterData character) {
    Clipboard.setData(ClipboardData(text: character.character));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${character.character} (${character.romanization}) to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
