// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:equatable/equatable.dart';

/// Model for a learned word or phrase entry in the diary.
///
/// This is a data model representing a vocabulary entry with no business logic.
/// Immutable and value-comparable for use in state management.
class DiaryEntry extends Equatable {
  /// Unique identifier for the entry.
  final int? id;

  /// Japanese text (kanji/kana).
  final String japanese;

  /// Furigana/reading guide (hiragana above kanji).
  final String? furigana;

  /// Romanized version (romaji).
  final String romaji;

  /// English translation or meaning.
  final String meaning;

  /// User's notes about the entry.
  final String? notes;

  /// When the entry was created/learned.
  final DateTime dateAdded;

  const DiaryEntry({
    this.id,
    required this.japanese,
    this.furigana,
    required this.romaji,
    required this.meaning,
    this.notes,
    required this.dateAdded,
  });

  /// Creates a DiaryEntry from a database map.
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      japanese: map['japanese'] as String,
      furigana: map['furigana'] as String?,
      romaji: map['romaji'] as String,
      meaning: map['meaning'] as String,
      notes: map['notes'] as String?,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int),
    );
  }

  /// Creates a copy of this entry with the given fields replaced.
  DiaryEntry copyWith({
    int? id,
    String? japanese,
    String? furigana,
    String? romaji,
    String? meaning,
    String? notes,
    DateTime? dateAdded,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      japanese: japanese ?? this.japanese,
      furigana: furigana ?? this.furigana,
      romaji: romaji ?? this.romaji,
      meaning: meaning ?? this.meaning,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        japanese,
        furigana,
        romaji,
        meaning,
        notes,
        dateAdded,
      ];

  @override
  bool get stringify => true;
}
