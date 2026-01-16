// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/katakana_data.dart';
import 'package:jpn_learning_diary/screens/character_set_page.dart';

/// Katakana alphabet learning and practice page.
///
/// Displays the katakana character set and provides tools for
/// learning and practicing katakana reading and writing.
class KatakanaPage extends StatelessWidget {
  const KatakanaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CharacterSetPage(
      characterTypeName: 'katakana',
      baseCharacters: KatakanaData.baseCharacters,
      dakutenCharacters: KatakanaData.dakutenCharacters,
      hanDakutenCharacters: KatakanaData.handakutenCharacters,
      combinations: KatakanaData.combinations,
    );
  }
}
