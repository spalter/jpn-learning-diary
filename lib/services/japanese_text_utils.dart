/// Utility class for Japanese text processing and analysis.
///
/// Provides regex patterns and helper methods for identifying and extracting
/// different types of Japanese characters (kanji, hiragana, katakana).
class JapaneseTextUtils {
  // Private constructor to prevent instantiation
  JapaneseTextUtils._();

  // ============================================================
  // Unicode Ranges
  // ============================================================

  /// CJK Unified Ideographs (most common kanji) - U+4E00 to U+9FFF
  static const String cjkUnifiedIdeographs = r'\u4E00-\u9FFF';

  /// CJK Extension A (rare kanji) - U+3400 to U+4DBF
  static const String cjkExtensionA = r'\u3400-\u4DBF';

  /// CJK Compatibility Ideographs - U+F900 to U+FAFF
  static const String cjkCompatibility = r'\uF900-\uFAFF';

  /// Hiragana - U+3040 to U+309F
  static const String hiraganaRange = r'\u3040-\u309F';

  /// Katakana - U+30A0 to U+30FF
  static const String katakanaRange = r'\u30A0-\u30FF';

  /// Katakana Phonetic Extensions - U+31F0 to U+31FF
  static const String katakanaExtensions = r'\u31F0-\u31FF';

  /// Half-width Katakana - U+FF65 to U+FF9F
  static const String halfWidthKatakana = r'\uFF65-\uFF9F';

  // ============================================================
  // Regex Patterns
  // ============================================================

  /// Pattern for matching one or more kanji characters (common kanji only).
  ///
  /// Use this for typical Japanese text processing.
  /// Example matches: 日本語, 勉強, 食
  static final RegExp kanjiPattern = RegExp(r'[\u4E00-\u9FFF]+');

  /// Pattern for matching one or more kanji characters (extended range).
  ///
  /// Includes rare kanji from CJK Extension A and compatibility ideographs.
  /// Use this when you need to match uncommon or archaic kanji.
  static final RegExp kanjiPatternExtended = RegExp(
    r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]+',
  );

  /// Pattern for matching a single kanji character.
  static final RegExp singleKanjiPattern = RegExp(r'[\u4E00-\u9FFF]');

  /// Pattern for matching kanji with optional okurigana (hiragana suffix).
  ///
  /// Useful for matching verbs and adjectives like 食べる, 美しい
  static final RegExp kanjiWithOkurigana = RegExp(
    r'[\u4E00-\u9FFF]+[\u3040-\u309F]*',
  );

  /// Pattern for matching one or more hiragana characters.
  static final RegExp hiraganaPattern = RegExp(r'[\u3040-\u309F]+');

  /// Pattern for matching one or more katakana characters.
  ///
  /// Includes standard katakana and phonetic extensions.
  static final RegExp katakanaPattern = RegExp(
    r'[\u30A0-\u30FF\u31F0-\u31FF]+',
  );

  /// Pattern for matching any Japanese character (kanji, hiragana, or katakana).
  static final RegExp japanesePattern = RegExp(
    r'[\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF]+',
  );

  // ============================================================
  // Helper Methods
  // ============================================================

  /// Checks if the given text contains any kanji characters.
  static bool containsKanji(String text) {
    return kanjiPattern.hasMatch(text);
  }

  /// Checks if the given text contains any hiragana characters.
  static bool containsHiragana(String text) {
    return hiraganaPattern.hasMatch(text);
  }

  /// Checks if the given text contains any katakana characters.
  static bool containsKatakana(String text) {
    return katakanaPattern.hasMatch(text);
  }

  /// Checks if the given text contains any Japanese characters.
  static bool containsJapanese(String text) {
    return japanesePattern.hasMatch(text);
  }

  /// Checks if a single character is a kanji.
  static bool isKanji(String char) {
    if (char.isEmpty) return false;
    return singleKanjiPattern.hasMatch(char[0]);
  }

  /// Extracts all kanji words/combinations from the given text.
  ///
  /// Returns a list of kanji strings found in the text.
  /// Example: "日本語を勉強しています" → ["日本語", "勉強"]
  static List<String> extractKanji(String text) {
    return kanjiPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Extracts all individual kanji characters from the given text.
  ///
  /// Returns a list of single kanji characters.
  /// Example: "日本語を勉強" → ["日", "本", "語", "勉", "強"]
  static List<String> extractIndividualKanji(String text) {
    return singleKanjiPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Extracts all unique kanji characters from the given text.
  ///
  /// Returns a set of unique kanji characters.
  static Set<String> extractUniqueKanji(String text) {
    return extractIndividualKanji(text).toSet();
  }

  /// Extracts all hiragana words from the given text.
  static List<String> extractHiragana(String text) {
    return hiraganaPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Extracts all katakana words from the given text.
  static List<String> extractKatakana(String text) {
    return katakanaPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Counts the number of kanji characters in the given text.
  static int countKanji(String text) {
    return singleKanjiPattern.allMatches(text).length;
  }

  /// Counts the number of hiragana characters in the given text.
  static int countHiragana(String text) {
    int count = 0;
    for (final char in text.runes) {
      if (char >= 0x3040 && char <= 0x309F) count++;
    }
    return count;
  }

  /// Counts the number of katakana characters in the given text.
  static int countKatakana(String text) {
    int count = 0;
    for (final char in text.runes) {
      if ((char >= 0x30A0 && char <= 0x30FF) ||
          (char >= 0x31F0 && char <= 0x31FF)) {
        count++;
      }
    }
    return count;
  }

  /// Splits text into segments by character type.
  ///
  /// Useful for furigana placement or text analysis.
  /// Example: "日本語です" → [("日本語", kanji), ("です", hiragana)]
  static List<TextSegment> segmentText(String text) {
    final segments = <TextSegment>[];
    if (text.isEmpty) return segments;

    final buffer = StringBuffer();
    CharacterType? currentType;

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final type = _getCharacterType(rune);

      if (currentType == null) {
        currentType = type;
        buffer.write(char);
      } else if (type == currentType) {
        buffer.write(char);
      } else {
        segments.add(TextSegment(buffer.toString(), currentType));
        buffer.clear();
        buffer.write(char);
        currentType = type;
      }
    }

    if (buffer.isNotEmpty && currentType != null) {
      segments.add(TextSegment(buffer.toString(), currentType));
    }

    return segments;
  }

  /// Determines the character type for a Unicode code point.
  static CharacterType _getCharacterType(int rune) {
    if (rune >= 0x4E00 && rune <= 0x9FFF) return CharacterType.kanji;
    if (rune >= 0x3400 && rune <= 0x4DBF) return CharacterType.kanji;
    if (rune >= 0xF900 && rune <= 0xFAFF) return CharacterType.kanji;
    if (rune >= 0x3040 && rune <= 0x309F) return CharacterType.hiragana;
    if (rune >= 0x30A0 && rune <= 0x30FF) return CharacterType.katakana;
    if (rune >= 0x31F0 && rune <= 0x31FF) return CharacterType.katakana;
    return CharacterType.other;
  }
}

/// Represents a segment of text with its character type.
class TextSegment {
  final String text;
  final CharacterType type;

  const TextSegment(this.text, this.type);

  @override
  String toString() => 'TextSegment("$text", $type)';
}

/// Types of Japanese characters.
enum CharacterType { kanji, hiragana, katakana, other }
