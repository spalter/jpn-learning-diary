// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/character_data.dart';
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

  /// The dakuten combination characters (濁点拗音).
  final List<CharacterData> dakutenCombinations;

  /// The han-dakuten combination characters (半濁点拗音).
  final List<CharacterData> handakutenCombinations;

  const CharacterSetPage({
    super.key,
    required this.characterTypeName,
    required this.baseCharacters,
    required this.dakutenCharacters,
    required this.hanDakutenCharacters,
    required this.combinations,
    this.dakutenCombinations = const [],
    this.handakutenCombinations = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isMobile =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android;

    if (isMobile) {
      return SingleChildScrollView(
        primary: true,
        child: Column(
          children: [
            _buildBaseCharactersSection(),
            _buildDakutenSection(),
            _buildHandakutenSection(),
            _buildCombinationsSection(),
            _buildDakutenCombinationsSection(),
            _buildHandakutenCombinationsSection(),
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      );
    }

    return SingleChildScrollView(
      primary: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 32.0,
          runSpacing: 32.0,
          children: [
            _buildBaseCharactersSection(),
            _buildDakutenSection(),
            _buildHandakutenSection(),
            _buildCombinationsSection(),
            _buildDakutenCombinationsSection(),
            _buildHandakutenCombinationsSection(),
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
      crossAxisCount: 5,
    );
  }

  /// Builds the dakuten characters section.
  Widget _buildDakutenSection() {
    return CharacterSection(
      title: 'Dakuten (゛)',
      characters: dakutenCharacters,
      characterTypeName: characterTypeName,
      crossAxisCount: 5,
    );
  }

  /// Builds the han-dakuten characters section.
  Widget _buildHandakutenSection() {
    return CharacterSection(
      title: 'Han-dakuten (゜)',
      characters: hanDakutenCharacters,
      characterTypeName: characterTypeName,
      crossAxisCount: 5,
    );
  }

  /// Builds the combinations (Yōon) section.
  Widget _buildCombinationsSection() {
    return CharacterSection(
      title: 'Combinations (Yōon)',
      characters: combinations,
      characterTypeName: characterTypeName,
      crossAxisCount: 3,
    );
  }

  /// Builds the dakuten combinations (濁点拗音) section.
  Widget _buildDakutenCombinationsSection() {
    return CharacterSection(
      title: 'Dakuten Combinations',
      characters: dakutenCombinations,
      characterTypeName: characterTypeName,
      crossAxisCount: 3,
    );
  }

  /// Builds the handakuten combinations (半濁点拗音) section.
  Widget _buildHandakutenCombinationsSection() {
    return CharacterSection(
      title: 'Handakuten Combinations',
      characters: handakutenCombinations,
      characterTypeName: characterTypeName,
      crossAxisCount: 3,
    );
  }

  /// Builds the spacer between sections.
  // Widget _buildSectionSpacer() {
  //   return const SizedBox(height: 32);
  // }
}
