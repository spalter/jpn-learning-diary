// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:equatable/equatable.dart';

import 'diary_item.dart';

/// Model for a long-form note entry in the diary.
class DiaryNote extends Equatable implements DiaryItem {
  /// Unique identifier for the note.
  @override
  final int? id;

  /// The title of the note.
  final String title;

  /// Japanese text, may include inline ruby patterns for furigana.
  final String contentJapanese;

  /// English translation or general notes.
  final String contentEnglish;

  /// Comma-separated tags.
  final String? tags;

  /// When the note was created/added.
  @override
  final DateTime dateAdded;

  /// Constructs a new DiaryNote instance.
  const DiaryNote({
    this.id,
    required this.title,
    required this.contentJapanese,
    this.contentEnglish = '',
    this.tags,
    required this.dateAdded,
  });

  /// Factory constructor to create a DiaryNote off an SQLite map result.
  factory DiaryNote.fromMap(Map<String, dynamic> map) {
    return DiaryNote(
      id: map['id'],
      title: map['title'],
      contentJapanese: map['content_japanese'],
      contentEnglish: map['content_english'],
      tags: map['tags'],
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] ?? 0),
    );
  }

  /// Converts the DiaryNote back to a map representation for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content_japanese': contentJapanese,
      'content_english': contentEnglish,
      'tags': tags,
      'date_added': dateAdded.millisecondsSinceEpoch,
    };
  }

  /// Immutably creates a copy of the DiaryNote with updated fields.
  DiaryNote copyWith({
    int? id,
    String? title,
    String? contentJapanese,
    String? contentEnglish,
    String? tags,
    DateTime? dateAdded,
  }) {
    return DiaryNote(
      id: id ?? this.id,
      title: title ?? this.title,
      contentJapanese: contentJapanese ?? this.contentJapanese,
      contentEnglish: contentEnglish ?? this.contentEnglish,
      tags: tags ?? this.tags,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    contentJapanese,
    contentEnglish,
    tags,
    dateAdded,
  ];
}
