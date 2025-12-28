import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/character_data.dart';
import 'package:jpn_learning_diary/widgets/character_section.dart';

/// Generic character set learning page.
///
/// Displays a character set (hiragana, katakana, etc.) with sections for
/// base characters, dakuten, han-dakuten, and combinations.
/// This is a reusable component that accepts character data to display.
class CharacterSetPage extends StatelessWidget {
  /// The name of the character type (e.g., 'hiragana', 'katakana').
  final String characterTypeName;

  /// The base characters (Gojūon).
  final List<CharacterData> baseCharacters;

  /// The dakuten characters (゛).
  final List<CharacterData> dakutenCharacters;

  /// The han-dakuten characters (゜).
  final List<CharacterData> hanDakutenCharacters;

  /// The combination characters (Yōon).
  final List<CharacterData> combinations;

  const CharacterSetPage({
    super.key,
    required this.characterTypeName,
    required this.baseCharacters,
    required this.dakutenCharacters,
    required this.hanDakutenCharacters,
    required this.combinations,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: true,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBaseCharactersSection(),
            _buildSectionSpacer(),
            _buildDakutenSection(),
            _buildSectionSpacer(),
            _buildHandakutenSection(),
            _buildSectionSpacer(),
            _buildCombinationsSection(),
          ],
        ),
      ),
    );
  }

  /// Builds the base characters (Gojūon) section.
  Widget _buildBaseCharactersSection() {
    return CharacterSection(
      title: 'Base Characters (Gojūon)',
      characters: baseCharacters,
      characterTypeName: characterTypeName,
    );
  }

  /// Builds the dakuten characters section.
  Widget _buildDakutenSection() {
    return CharacterSection(
      title: 'Dakuten (゛)',
      characters: dakutenCharacters,
      characterTypeName: characterTypeName,
    );
  }

  /// Builds the han-dakuten characters section.
  Widget _buildHandakutenSection() {
    return CharacterSection(
      title: 'Han-dakuten (゜)',
      characters: hanDakutenCharacters,
      characterTypeName: characterTypeName,
    );
  }

  /// Builds the combinations (Yōon) section.
  Widget _buildCombinationsSection() {
    return CharacterSection(
      title: 'Combinations (Yōon)',
      characters: combinations,
      characterTypeName: characterTypeName,
    );
  }

  /// Builds the spacer between sections.
  Widget _buildSectionSpacer() {
    return const SizedBox(height: 32);
  }
}
