// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:kuromoji/kuromoji.dart';

/// Utility class for Japanese text processing and morphological analysis.
///
/// This service provides specialized tools for working with Japanese text,
/// including precise regex patterns for ruby text (furigana) parsing and
/// integration with the Kuromoji tokenizer. It enables the app to break down
/// sentences into interactive words and identify character types like hiragana,
/// katakana, and kanji.
class JapaneseTextUtils {
  // Singleton instance of Kuromoji Tokenizer for word tokenization
  static final Tokenizer _tokenizer = Tokenizer.buildSync();

  // Private constructor to prevent instantiation
  JapaneseTextUtils._();

  // ============================================================================
  // Ruby Text (Furigana) Utilities
  // ============================================================================

  /// Regex pattern to match ruby text format.
  ///
  /// Supports various bracket styles for ease of typing in Japanese:
  /// - `[kanji](reading)` - ASCII brackets and parentheses
  /// - `「kanji」（reading）` - Japanese corner brackets and fullwidth parentheses
  /// - `［kanji］（reading）` - Fullwidth square brackets and parentheses
  /// - And any mix of the above bracket/parenthesis styles
  ///
  /// Captures: group 1 = kanji/base text, group 2 = reading
  static final RegExp rubyPattern = RegExp(
    r'[\[［「]([^\]］」]+)[\]］」][\(（]([^\)）]+)[\)）]',
  );

  /// Checks if the text contains any ruby patterns.
  ///
  /// Example: `containsRubyPattern('[食](た)べる')` → true
  static bool containsRubyPattern(String text) {
    return rubyPattern.hasMatch(text);
  }

  /// Strips ruby patterns from text, leaving only the base text (kanji).
  ///
  /// Example: `[晩御飯](ばんごはん)を[食](た)べる` → `晩御飯を食べる`
  static String stripRubyPatterns(String text) {
    return text.replaceAllMapped(rubyPattern, (match) => match.group(1)!);
  }

  // ============================================================================
  // Particle Detection
  // ============================================================================

  /// Set of common Japanese particles (助詞).
  ///
  /// Includes case particles, binding particles, adverbial particles,
  /// conjunctive particles, and sentence-ending particles.
  static const Set<String> japaneseParticles = {
    // Case particles (格助詞)
    'が', 'を', 'に', 'へ', 'で', 'と', 'から', 'より', 'まで',
    // Binding/topic particles (係助詞)
    'は', 'も', 'こそ', 'さえ', 'しか', 'でも',
    // Adverbial particles (副助詞)
    'ばかり', 'だけ', 'ほど', 'くらい', 'ぐらい', 'など', 'なんか', 'なんて', 'のみ',
    // Conjunctive particles (接続助詞)
    'て', 'ば', 'ても', 'けど', 'けれど', 'けれども', 'のに', 'ので', 'し', 'たり', 'ながら',
    // Sentence-ending particles (終助詞)
    'か', 'な', 'ね', 'よ', 'わ', 'ぞ', 'ぜ', 'さ', 'かな', 'っけ',
    // Other particles
    'の', 'や', 'とか', 'って',
  };

  /// Checks if a text segment is a Japanese particle.
  ///
  /// Returns true if the segment matches a known particle.
  /// Note: This is a simple lookup and may have false positives
  /// (e.g., 'が' as particle vs. moth kanji is rare but possible).
  /// Example: isParticle('は') → true, isParticle('日本') → false
  static bool isParticle(String segment) => japaneseParticles.contains(segment);

  /// Pattern for matching one or more kanji characters (common kanji only).
  ///
  /// Use this for typical Japanese text processing.
  /// Example matches: 日本語, 勉強, 食
  static final RegExp kanjiPattern = RegExp(r'[\u4E00-\u9FFF]+');

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

  /// Tokenizes Japanese text into individual words/tokens.
  ///
  /// Uses Kuromoji for morphological analysis with dictionary-based tokenization.
  /// Returns just the surface forms for backward compatibility.
  /// Example: "私は日本語を勉強しています" → ["私", "は", "日本語", "を", "勉強", "し", "て", "い", "ます"]
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];
    return _tokenizer.tokenize(text).map((t) => t.surfaceForm).toList();
  }

  /// Tokenizes Japanese text with full morphological information.
  ///
  /// Uses Kuromoji for morphological analysis, returning rich token data including:
  /// - surfaceForm: The actual text of the token
  /// - pos: Part of speech (名詞, 動詞, 助詞, etc.)
  /// - reading: Kana reading of the token
  /// - basicForm: Dictionary/lemma form
  /// - conjugatedType/conjugatedForm: Conjugation information
  ///
  /// Example usage:
  /// ```dart
  /// final tokens = JapaneseTextUtils.tokenizeWithInfo("食べています");
  /// for (final token in tokens) {
  ///   print('${token.surfaceForm} - ${token.pos} - ${token.reading}');
  /// }
  /// ```
  static List<UnknownToken> tokenizeWithInfo(String text) {
    if (text.isEmpty) return [];
    return _tokenizer.tokenize(text);
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
