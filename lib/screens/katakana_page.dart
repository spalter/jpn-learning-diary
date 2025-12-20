import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/katakana_data.dart';
import 'package:jpn_learning_diary/widgets/character_section.dart';

/// Katakana alphabet learning and practice page.
///
/// Displays the katakana character set and provides tools for
/// learning and practicing katakana reading and writing.
class KatakanaPage extends StatelessWidget {
  const KatakanaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: true,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Base Characters Section
            CharacterSection(
              title: 'Base Characters (Gojūon)',
              characters: KatakanaData.baseCharacters,
              characterTypeName: 'katakana',
            ),
            const SizedBox(height: 32),

            // Dakuten Section
            CharacterSection(
              title: 'Dakuten (゛)',
              characters: KatakanaData.dakutenCharacters,
              characterTypeName: 'katakana',
            ),
            const SizedBox(height: 32),

            // Han-dakuten Section
            CharacterSection(
              title: 'Han-dakuten (゜)',
              characters: KatakanaData.hanDakutenCharacters,
              characterTypeName: 'katakana',
            ),
            const SizedBox(height: 32),

            // Combinations Section
            CharacterSection(
              title: 'Combinations (Yōon)',
              characters: KatakanaData.combinations,
              characterTypeName: 'katakana',
            ),
          ],
        ),
      ),
    );
  }
}
