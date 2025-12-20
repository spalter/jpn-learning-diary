/// Data model for Japanese characters (hiragana, katakana, etc.).
class CharacterData {
  final String character;
  final String romanization;
  final String? description;

  const CharacterData({
    required this.character,
    required this.romanization,
    this.description,
  });
}
