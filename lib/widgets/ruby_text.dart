// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';

/// A segment of text that may or may not have furigana.
class _TextSegment {
  final String text;
  final String? reading;

  const _TextSegment(this.text, [this.reading]);

  bool get hasReading => reading != null && reading!.isNotEmpty;
}

/// A widget that renders Japanese text with furigana (ruby text) support.
///
/// Parses text containing ruby patterns and displays the reading above the
/// kanji characters. Regular text is displayed normally.
///
/// Supports various bracket styles for typing in Japanese:
/// - `[kanji](reading)` - ASCII brackets and parentheses
/// - `「kanji」（reading）` - Japanese corner brackets, fullwidth parentheses
/// - `［kanji］（reading）` - Fullwidth square brackets and parentheses
/// - And any mix of the above
///
/// Example input: `「今」（いま）ねます。` or `[晩御飯](ばんごはん)`
///
/// This will render the kanji with furigana displayed above it.
class RubyText extends StatelessWidget {
  /// The text to parse and render, may contain `[kanji](reading)` patterns.
  final String text;

  /// The style for the main text (kanji and regular characters).
  final TextStyle? textStyle;

  /// The style for the furigana reading above kanji.
  /// If not provided, uses a smaller font with primary color.
  final TextStyle? rubyStyle;

  /// The maximum number of lines for the text.
  final int? maxLines;

  /// Creates a RubyText widget.
  const RubyText({
    super.key,
    required this.text,
    this.textStyle,
    this.rubyStyle,
    this.maxLines,
  });

  /// Regex pattern to match ruby text format.
  /// Supports various bracket styles for ease of typing in Japanese:
  /// - `[kanji](reading)` - ASCII brackets and parentheses
  /// - `「kanji」（reading）` - Japanese corner brackets and fullwidth parentheses
  /// - `［kanji］（reading）` - Fullwidth square brackets and parentheses
  /// - And any mix of the above bracket/parenthesis styles
  /// Captures: group 1 = kanji/base text, group 2 = reading
  static final RegExp _rubyPattern = RegExp(
    r'[\[［「]([^\]］」]+)[\]］」][\(（]([^\)）]+)[\)）]',
  );

  /// Checks if the text contains any ruby patterns.
  static bool containsRubyPattern(String text) {
    return _rubyPattern.hasMatch(text);
  }

  /// Strips ruby patterns from text, leaving only the base text.
  /// Example: `[晩御飯](ばんごはん)` becomes `晩御飯`
  static String stripRubyPatterns(String text) {
    return text.replaceAllMapped(_rubyPattern, (match) => match.group(1)!);
  }

  /// Parses the input text into segments of regular text and ruby text.
  List<_TextSegment> _parseText() {
    final segments = <_TextSegment>[];
    int lastEnd = 0;

    for (final match in _rubyPattern.allMatches(text)) {
      // Add any text before this match as a regular segment
      if (match.start > lastEnd) {
        segments.add(_TextSegment(text.substring(lastEnd, match.start)));
      }

      // Add the ruby segment (kanji with reading)
      final kanji = match.group(1)!;
      final reading = match.group(2)!;
      segments.add(_TextSegment(kanji, reading));

      lastEnd = match.end;
    }

    // Add any remaining text after the last match
    if (lastEnd < text.length) {
      segments.add(_TextSegment(text.substring(lastEnd)));
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final segments = _parseText();

    // If no ruby patterns found, just return regular text
    if (segments.length == 1 && !segments.first.hasReading) {
      return Text(
        text,
        style: textStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final defaultTextStyle = textStyle ?? Theme.of(context).textTheme.bodyLarge;
    final defaultRubyStyle =
        rubyStyle ??
        TextStyle(
          fontSize: (defaultTextStyle?.fontSize ?? 16) * 0.5,
          color: Theme.of(context).colorScheme.primary,
          height: 1.0,
        );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: segments.map((segment) {
        if (segment.hasReading) {
          return _RubySegment(
            base: segment.text,
            reading: segment.reading!,
            baseStyle: defaultTextStyle,
            rubyStyle: defaultRubyStyle,
          );
        } else {
          return Text(segment.text, style: defaultTextStyle);
        }
      }).toList(),
    );
  }
}

/// A single ruby text segment with base text and reading above it.
class _RubySegment extends StatelessWidget {
  final String base;
  final String reading;
  final TextStyle? baseStyle;
  final TextStyle? rubyStyle;

  const _RubySegment({
    required this.base,
    required this.reading,
    this.baseStyle,
    this.rubyStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(reading, style: rubyStyle, textAlign: TextAlign.center),
        Text(base, style: baseStyle),
      ],
    );
  }
}
