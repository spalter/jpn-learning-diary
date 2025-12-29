import 'package:equatable/equatable.dart';

/// Data model for Japanese characters (hiragana, katakana, etc.).
///
/// Pure data model with no business logic.
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
