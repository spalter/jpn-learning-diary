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

  /// Helper to create an empty/placeholder character.
  static const empty = CharacterData(character: '', romanization: '');

  /// Whether this is an empty/placeholder character.
  bool get isEmpty => character.isEmpty && romanization.isEmpty;

  @override
  List<Object?> get props => [character, romanization, description];

  @override
  bool get stringify => true;
}
