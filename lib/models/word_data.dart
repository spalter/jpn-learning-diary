import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Represents a variant form of a word.
///
/// A variant includes the written form, pronunciation, and priority indicators.
class WordVariant extends Equatable {
  final String? written;
  final String? pronounced;
  final List<String> priorities;

  const WordVariant({
    this.written,
    this.pronounced,
    this.priorities = const [],
  });

  /// Creates a WordVariant from a database map.
  factory WordVariant.fromMap(Map<String, dynamic> map) {
    List<String> parsePriorities(dynamic value) {
      if (value == null) return [];
      if (value is String) {
        try {
          final list = json.decode(value) as List;
          return list.cast<String>();
        } catch (_) {
          return [];
        }
      }
      if (value is List) {
        return value.cast<String>();
      }
      return [];
    }

    return WordVariant(
      written: map['written'] as String?,
      pronounced: map['pronounced'] as String?,
      priorities: parsePriorities(map['priorities']),
    );
  }

  /// Whether this variant has any priority indicators.
  bool get hasPriority => priorities.isNotEmpty;

  /// Whether this is a common word (has ichi1, news1, or spec1 priority).
  bool get isCommon {
    return priorities.any(
      (p) => p == 'ichi1' || p == 'news1' || p == 'spec1',
    );
  }

  @override
  List<Object?> get props => [written, pronounced, priorities];

  @override
  bool get stringify => true;
}

/// Represents a meaning of a word with glosses.
class WordMeaning extends Equatable {
  final List<String> glosses;

  const WordMeaning({
    this.glosses = const [],
  });

  /// Creates a WordMeaning from a database map.
  factory WordMeaning.fromMap(Map<String, dynamic> map) {
    List<String> parseGlosses(dynamic value) {
      if (value == null) return [];
      if (value is String) {
        try {
          final list = json.decode(value) as List;
          return list.cast<String>();
        } catch (_) {
          return [value];
        }
      }
      if (value is List) {
        return value.cast<String>();
      }
      return [];
    }

    return WordMeaning(
      glosses: parseGlosses(map['glosses']),
    );
  }

  /// Gets a comma-separated string of all glosses.
  String get glossesString => glosses.join(', ');

  @override
  List<Object?> get props => [glosses];

  @override
  bool get stringify => true;
}

/// Word data model for storing Japanese word information.
///
/// A word entry contains the source kanji character, meanings, and variants.
class WordData extends Equatable {
  final int id;
  final String kanji;
  final List<WordMeaning> meanings;
  final List<WordVariant> variants;

  const WordData({
    required this.id,
    required this.kanji,
    this.meanings = const [],
    this.variants = const [],
  });

  /// Creates a WordData from a combined database result map.
  ///
  /// The map should contain:
  /// - id: The word ID
  /// - kanji: The source kanji character
  /// - meanings: List of meaning maps
  /// - variants: List of variant maps
  factory WordData.fromMap(Map<String, dynamic> map) {
    final meaningsData = map['meanings'] as List<dynamic>? ?? [];
    final variantsData = map['variants'] as List<dynamic>? ?? [];

    return WordData(
      id: map['id'] as int,
      kanji: map['kanji'] as String,
      meanings: meaningsData
          .map((m) => WordMeaning.fromMap(m as Map<String, dynamic>))
          .toList(),
      variants: variantsData
          .map((v) => WordVariant.fromMap(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Gets all glosses/meanings as a single string.
  String get allMeanings {
    return meanings.map((m) => m.glossesString).join('; ');
  }

  /// Gets the primary (first) variant's written form.
  String? get primaryWritten => variants.isNotEmpty ? variants.first.written : null;

  /// Gets the primary (first) variant's pronunciation.
  String? get primaryPronounced =>
      variants.isNotEmpty ? variants.first.pronounced : null;

  /// Whether any variant is a common word.
  bool get isCommon => variants.any((v) => v.isCommon);

  @override
  List<Object?> get props => [id, kanji, meanings, variants];

  @override
  bool get stringify => true;
}
