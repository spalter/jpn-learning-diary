// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:equatable/equatable.dart';

/// Data model for Japanese characters (hiragana, katakana, etc.).
class CharacterData extends Equatable {
  final String character;
  final String romanization;
  final String? description;

  const CharacterData({
    required this.character,
    required this.romanization,
    this.description,
  });

  @override
  List<Object?> get props => [character, romanization, description];

  @override
  bool get stringify => true;
}
