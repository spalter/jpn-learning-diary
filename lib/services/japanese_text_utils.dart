// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:tiny_segmenter_dart/tiny_segmenter_dart.dart';

/// Utility class for Japanese text processing and analysis.
///
/// Provides regex patterns and helper methods for identifying and extracting
/// different types of Japanese characters (kanji, hiragana, katakana).
class JapaneseTextUtils {
  // Singleton instance of TinySegmenter for word tokenization
  static final TinySegmenter _segmenter = TinySegmenter();
  // Private constructor to prevent instantiation
  JapaneseTextUtils._();

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
  /// Uses TinySegmenter for word boundary detection.
  /// Example: "私は日本語を勉強しています" → ["私", "は", "日本語", "を", "勉強", "し", "て", "い", "ます"]
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];
    return _segmenter.segment(text);
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
