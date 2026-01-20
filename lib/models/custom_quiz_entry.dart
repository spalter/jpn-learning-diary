// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:equatable/equatable.dart';

/// Model for a custom quiz entry loaded from a CSV file.
///
/// Represents a single quiz question with one correct answer and optionally
/// three wrong answer options. If wrong answers are not provided, they will
/// be randomly selected from other entries. Immutable and value-comparable for state management.
class CustomQuizEntry extends Equatable {
  /// Unique identifier for the entry.
  final int id;

  /// The question text shown to the user.
  final String question;

  /// The correct answer for this question.
  final String correctAnswer;

  /// First wrong answer option (null if using random mode).
  final String? wrongAnswer1;

  /// Second wrong answer option (null if using random mode).
  final String? wrongAnswer2;

  /// Third wrong answer option (null if using random mode).
  final String? wrongAnswer3;

  const CustomQuizEntry({
    required this.id,
    required this.question,
    required this.correctAnswer,
    this.wrongAnswer1,
    this.wrongAnswer2,
    this.wrongAnswer3,
  });

  /// Whether this entry has predefined wrong answers.
  bool get hasPredefinedAnswers => wrongAnswer1 != null && wrongAnswer2 != null && wrongAnswer3 != null;

  /// Creates a CustomQuizEntry from a CSV row.
  ///
  /// Supports two formats:
  /// - 5 columns: id;question;correct answer;wrong answer 1;wrong answer 2;wrong answer 3
  /// - 2 columns: id;question;correct answer (wrong answers will be randomly selected)
  factory CustomQuizEntry.fromCsvRow(String row) {
    final parts = row.split(';').map((p) => p.trim()).toList();

    if (parts.length < 3) {
      throw FormatException(
        'Invalid CSV row: expected at least 3 fields (id;question;answer) or 6 fields (id;question;answer;wrong1;wrong2;wrong3), got ${parts.length}',
      );
    }

    if (parts.length != 3 && parts.length < 6) {
      throw FormatException(
        'Invalid CSV row: expected 3 fields or 6 fields, got ${parts.length}',
      );
    }

    final id = int.tryParse(parts[0]);
    if (id == null) {
      throw FormatException('Invalid ID: ${parts[0]} is not a valid integer');
    }

    // 5-column format with predefined wrong answers
    if (parts.length >= 6) {
      return CustomQuizEntry(
        id: id,
        question: parts[1],
        correctAnswer: parts[2],
        wrongAnswer1: parts[3],
        wrongAnswer2: parts[4],
        wrongAnswer3: parts[5],
      );
    }

    // 2-column format - wrong answers will be generated later
    return CustomQuizEntry(
      id: id,
      question: parts[1],
      correctAnswer: parts[2],
    );
  }

  /// Returns all answer options as a list (only if predefined answers exist).
  /// Returns null if this entry uses random answer mode.
  List<String>? get allAnswers {
    if (!hasPredefinedAnswers) return null;
    return [
      correctAnswer,
      wrongAnswer1!,
      wrongAnswer2!,
      wrongAnswer3!,
    ];
  }

  @override
  List<Object?> get props => [
    id,
    question,
    correctAnswer,
    wrongAnswer1,
    wrongAnswer2,
    wrongAnswer3,
  ];

  @override
  String toString() {
    return 'CustomQuizEntry(id: $id, question: $question)';
  }
}
