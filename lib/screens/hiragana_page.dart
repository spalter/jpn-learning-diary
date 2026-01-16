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
import 'package:jpn_learning_diary/screens/character_set_page.dart';

/// Hiragana alphabet learning and practice page.
///
/// Displays the hiragana character set and provides tools for
/// learning and practicing hiragana reading and writing.
class HiraganaPage extends StatelessWidget {
  const HiraganaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CharacterSetPage(
      characterTypeName: 'hiragana',
      baseCharacters: HiraganaData.baseCharacters,
      dakutenCharacters: HiraganaData.dakutenCharacters,
      hanDakutenCharacters: HiraganaData.handakutenCharacters,
      combinations: HiraganaData.combinations,
    );
  }
}
