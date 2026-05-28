// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/hiragana_data.dart';
import 'package:jpn_learning_diary/models/katakana_data.dart';
import 'package:jpn_learning_diary/screens/character_set_page.dart';

/// Enum for the type of Kana character set.
enum KanaType { hiragana, katakana }

/// A combined page for displaying Kana (Hiragana or Katakana) character sets.
///
/// This widget renders the standard Gojūon table along with its variations
/// (Dakuten, Handakuten, Yōon). It serves as a reference and learning tool for
/// the basic Japanese syllabaries. The content is determined by the [type] parameter:
///
/// - [KanaType.hiragana]: Displays the Hiragana character set (natives words)
/// - [KanaType.katakana]: Displays the Katakana character set (loan words)
class KanaPage extends StatelessWidget {
  final KanaType type;

  const KanaPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isHiragana = type == KanaType.hiragana;

    return CharacterSetPage(
      characterTypeName: isHiragana ? 'hiragana' : 'katakana',
      baseCharacters: isHiragana
          ? HiraganaData.gridBaseCharacters
          : KatakanaData.gridBaseCharacters,
      dakutenCharacters: isHiragana
          ? HiraganaData.dakutenCharacters
          : KatakanaData.dakutenCharacters,
      hanDakutenCharacters: isHiragana
          ? HiraganaData.handakutenCharacters
          : KatakanaData.handakutenCharacters,
      combinations: isHiragana
          ? HiraganaData.combinations
          : KatakanaData.combinations,
      dakutenCombinations: isHiragana
          ? HiraganaData.dakutenCombinations
          : KatakanaData.dakutenCombinations,
      handakutenCombinations: isHiragana
          ? HiraganaData.handakutenCombinations
          : KatakanaData.handakutenCombinations,
    );
  }
}
