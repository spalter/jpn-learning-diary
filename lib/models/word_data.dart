import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Word data model for storing Japanese word information.
///
/// A word entry contains the written form, meanings, pronunciations, and priorities.
class WordData extends Equatable {
  final int id;
  final String written;
  final List<String> meanings;
  final List<String> pronunciations;
  final List<String> priorities;

  const WordData({
    required this.id,
    required this.written,
    this.meanings = const [],
    this.pronunciations = const [],
    this.priorities = const [],
  });

  /// Creates a WordData from a single database row.
  ///
  /// The map should contain:
  /// - word_id: The word ID
  /// - written: The written form (kanji)
  /// - glosses: JSON array of meanings
  /// - pronounced: The pronunciation
  /// - priorities: JSON array of priority indicators
  factory WordData.fromRow(Map<String, dynamic> map) {
    return WordData(
      id: map['word_id'] as int,
      written: map['written'] as String? ?? '',
      meanings: _parseJsonList(map['glosses']),
      pronunciations: [if (map['pronounced'] != null) map['pronounced'] as String],
      priorities: _parseJsonList(map['priorities']),
    );
  }

  /// Creates a list of WordData from query results, grouping by written form.
  ///
  /// This collects all unique pronunciations and meanings into a single WordData
  /// per unique written form.
  static List<WordData> fromRows(List<Map<String, dynamic>> rows) {
    final Map<String, WordData> grouped = {};

    for (final row in rows) {
      final id = row['word_id'] as int;
      final written = row['written'] as String? ?? '';
      final meanings = _parseJsonList(row['glosses']);
      final pronounced = row['pronounced'] as String?;
      final priorities = _parseJsonList(row['priorities']);

      // Group by written form only
      final key = written;

      if (grouped.containsKey(key)) {
        // Merge into existing entry
        final existing = grouped[key]!;
        
        // Collect unique pronunciations
        final newPronunciations = [...existing.pronunciations];
        if (pronounced != null && !newPronunciations.contains(pronounced)) {
          newPronunciations.add(pronounced);
        }
        
        // Collect unique meanings
        final newMeanings = [...existing.meanings];
        for (final meaning in meanings) {
          if (!newMeanings.contains(meaning)) {
            newMeanings.add(meaning);
          }
        }
        
        // Collect unique priorities
        final newPriorities = [...existing.priorities];
        for (final priority in priorities) {
          if (!newPriorities.contains(priority)) {
            newPriorities.add(priority);
          }
        }
        
        grouped[key] = WordData(
          id: existing.id,
          written: existing.written,
          meanings: newMeanings,
          pronunciations: newPronunciations,
          priorities: newPriorities,
        );
      } else {
        // Create new entry
        grouped[key] = WordData(
          id: id,
          written: written,
          meanings: meanings,
          pronunciations: [if (pronounced != null) pronounced],
          priorities: priorities,
        );
      }
    }

    return grouped.values.toList();
  }

  /// Parses a JSON list from a dynamic value.
  static List<String> _parseJsonList(dynamic value) {
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

  /// Gets all meanings as a single comma-separated string.
  String get meaningsString => meanings.join(', ');

  /// Gets all pronunciations as a single string separated by " / ".
  String get pronunciationsString => pronunciations.join(' / ');

  /// Gets the primary (first) pronunciation.
  String? get primaryPronunciation =>
      pronunciations.isNotEmpty ? pronunciations.first : null;

  /// Whether this is a common word (has ichi1, news1, or spec1 priority).
  bool get isCommon {
    return priorities.any(
      (p) => p == 'ichi1' || p == 'news1' || p == 'spec1',
    );
  }

  /// Whether this word has any priority indicators.
  bool get hasPriority => priorities.isNotEmpty;

  @override
  List<Object?> get props => [id, written, meanings, pronunciations, priorities];

  @override
  bool get stringify => true;
}
