/// Data model for Japanese characters.
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

/// Hiragana character data organized by type.
class HiraganaData {
  /// Base hiragana characters (gojūon).
  static const List<CharacterData> baseCharacters = [
    // Vowels
    CharacterData(character: 'あ', romanization: 'a'),
    CharacterData(character: 'い', romanization: 'i'),
    CharacterData(character: 'う', romanization: 'u'),
    CharacterData(character: 'え', romanization: 'e'),
    CharacterData(character: 'お', romanization: 'o'),
    
    // K-row
    CharacterData(character: 'か', romanization: 'ka'),
    CharacterData(character: 'き', romanization: 'ki'),
    CharacterData(character: 'く', romanization: 'ku'),
    CharacterData(character: 'け', romanization: 'ke'),
    CharacterData(character: 'こ', romanization: 'ko'),
    
    // S-row
    CharacterData(character: 'さ', romanization: 'sa'),
    CharacterData(character: 'し', romanization: 'shi'),
    CharacterData(character: 'す', romanization: 'su'),
    CharacterData(character: 'せ', romanization: 'se'),
    CharacterData(character: 'そ', romanization: 'so'),
    
    // T-row
    CharacterData(character: 'た', romanization: 'ta'),
    CharacterData(character: 'ち', romanization: 'chi'),
    CharacterData(character: 'つ', romanization: 'tsu'),
    CharacterData(character: 'て', romanization: 'te'),
    CharacterData(character: 'と', romanization: 'to'),
    
    // N-row
    CharacterData(character: 'な', romanization: 'na'),
    CharacterData(character: 'に', romanization: 'ni'),
    CharacterData(character: 'ぬ', romanization: 'nu'),
    CharacterData(character: 'ね', romanization: 'ne'),
    CharacterData(character: 'の', romanization: 'no'),
    
    // H-row
    CharacterData(character: 'は', romanization: 'ha'),
    CharacterData(character: 'ひ', romanization: 'hi'),
    CharacterData(character: 'ふ', romanization: 'fu'),
    CharacterData(character: 'へ', romanization: 'he'),
    CharacterData(character: 'ほ', romanization: 'ho'),
    
    // M-row
    CharacterData(character: 'ま', romanization: 'ma'),
    CharacterData(character: 'み', romanization: 'mi'),
    CharacterData(character: 'む', romanization: 'mu'),
    CharacterData(character: 'め', romanization: 'me'),
    CharacterData(character: 'も', romanization: 'mo'),
    
    // Y-row
    CharacterData(character: 'や', romanization: 'ya'),
    CharacterData(character: 'ゆ', romanization: 'yu'),
    CharacterData(character: 'よ', romanization: 'yo'),
    
    // R-row
    CharacterData(character: 'ら', romanization: 'ra'),
    CharacterData(character: 'り', romanization: 'ri'),
    CharacterData(character: 'る', romanization: 'ru'),
    CharacterData(character: 'れ', romanization: 're'),
    CharacterData(character: 'ろ', romanization: 'ro'),
    
    // W-row
    CharacterData(character: 'わ', romanization: 'wa'),
    CharacterData(character: 'を', romanization: 'wo'),
    
    // N
    CharacterData(character: 'ん', romanization: 'n'),
  ];

  /// Dakuten characters (voiced consonants).
  static const List<CharacterData> dakutenCharacters = [
    // G-row
    CharacterData(character: 'が', romanization: 'ga'),
    CharacterData(character: 'ぎ', romanization: 'gi'),
    CharacterData(character: 'ぐ', romanization: 'gu'),
    CharacterData(character: 'げ', romanization: 'ge'),
    CharacterData(character: 'ご', romanization: 'go'),
    
    // Z-row
    CharacterData(character: 'ざ', romanization: 'za'),
    CharacterData(character: 'じ', romanization: 'ji'),
    CharacterData(character: 'ず', romanization: 'zu'),
    CharacterData(character: 'ぜ', romanization: 'ze'),
    CharacterData(character: 'ぞ', romanization: 'zo'),
    
    // D-row
    CharacterData(character: 'だ', romanization: 'da'),
    CharacterData(character: 'ぢ', romanization: 'ji'),
    CharacterData(character: 'づ', romanization: 'zu'),
    CharacterData(character: 'で', romanization: 'de'),
    CharacterData(character: 'ど', romanization: 'do'),
    
    // B-row
    CharacterData(character: 'ば', romanization: 'ba'),
    CharacterData(character: 'び', romanization: 'bi'),
    CharacterData(character: 'ぶ', romanization: 'bu'),
    CharacterData(character: 'べ', romanization: 'be'),
    CharacterData(character: 'ぼ', romanization: 'bo'),
  ];

  /// Han-dakuten characters (p-sounds).
  static const List<CharacterData> hanDakutenCharacters = [
    CharacterData(character: 'ぱ', romanization: 'pa'),
    CharacterData(character: 'ぴ', romanization: 'pi'),
    CharacterData(character: 'ぷ', romanization: 'pu'),
    CharacterData(character: 'ぺ', romanization: 'pe'),
    CharacterData(character: 'ぽ', romanization: 'po'),
  ];

  /// Combination characters (yōon).
  static const List<CharacterData> combinations = [
    // K-combinations
    CharacterData(character: 'きゃ', romanization: 'kya'),
    CharacterData(character: 'きゅ', romanization: 'kyu'),
    CharacterData(character: 'きょ', romanization: 'kyo'),
    
    // S-combinations
    CharacterData(character: 'しゃ', romanization: 'sha'),
    CharacterData(character: 'しゅ', romanization: 'shu'),
    CharacterData(character: 'しょ', romanization: 'sho'),
    
    // C-combinations
    CharacterData(character: 'ちゃ', romanization: 'cha'),
    CharacterData(character: 'ちゅ', romanization: 'chu'),
    CharacterData(character: 'ちょ', romanization: 'cho'),
    
    // N-combinations
    CharacterData(character: 'にゃ', romanization: 'nya'),
    CharacterData(character: 'にゅ', romanization: 'nyu'),
    CharacterData(character: 'にょ', romanization: 'nyo'),
    
    // H-combinations
    CharacterData(character: 'ひゃ', romanization: 'hya'),
    CharacterData(character: 'ひゅ', romanization: 'hyu'),
    CharacterData(character: 'ひょ', romanization: 'hyo'),
    
    // M-combinations
    CharacterData(character: 'みゃ', romanization: 'mya'),
    CharacterData(character: 'みゅ', romanization: 'myu'),
    CharacterData(character: 'みょ', romanization: 'myo'),
    
    // R-combinations
    CharacterData(character: 'りゃ', romanization: 'rya'),
    CharacterData(character: 'りゅ', romanization: 'ryu'),
    CharacterData(character: 'りょ', romanization: 'ryo'),
    
    // G-combinations
    CharacterData(character: 'ぎゃ', romanization: 'gya'),
    CharacterData(character: 'ぎゅ', romanization: 'gyu'),
    CharacterData(character: 'ぎょ', romanization: 'gyo'),
    
    // J-combinations
    CharacterData(character: 'じゃ', romanization: 'ja'),
    CharacterData(character: 'じゅ', romanization: 'ju'),
    CharacterData(character: 'じょ', romanization: 'jo'),
    
    // B-combinations
    CharacterData(character: 'びゃ', romanization: 'bya'),
    CharacterData(character: 'びゅ', romanization: 'byu'),
    CharacterData(character: 'びょ', romanization: 'byo'),
    
    // P-combinations
    CharacterData(character: 'ぴゃ', romanization: 'pya'),
    CharacterData(character: 'ぴゅ', romanization: 'pyu'),
    CharacterData(character: 'ぴょ', romanization: 'pyo'),
  ];
}
