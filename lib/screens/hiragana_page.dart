import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/hiragana_data.dart';
import 'package:jpn_learning_diary/widgets/character_section.dart';

/// Hiragana alphabet learning and practice page.
///
/// Displays the hiragana character set and provides tools for
/// learning and practicing hiragana reading and writing.
class HiraganaPage extends StatelessWidget {
  const HiraganaPage({super.key});

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
              characters: HiraganaData.baseCharacters,
              characterTypeName: 'hiragana',
            ),
            const SizedBox(height: 32),

            // Dakuten Section
            CharacterSection(
              title: 'Dakuten (゛)',
              characters: HiraganaData.dakutenCharacters,
              characterTypeName: 'hiragana',
            ),
            const SizedBox(height: 32),

            // Han-dakuten Section
            CharacterSection(
              title: 'Han-dakuten (゜)',
              characters: HiraganaData.hanDakutenCharacters,
              characterTypeName: 'hiragana',
            ),
            const SizedBox(height: 32),

            // Combinations Section
            CharacterSection(
              title: 'Combinations (Yōon)',
              characters: HiraganaData.combinations,
              characterTypeName: 'hiragana',
            ),
          ],
        ),
      ),
    );
  }
}
