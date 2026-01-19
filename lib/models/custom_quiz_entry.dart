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
/// Represents a single quiz question with one correct answer and three
/// wrong answer options. Immutable and value-comparable for state management.
class CustomQuizEntry extends Equatable {
  /// Unique identifier for the entry.
  final int id;

  /// The question text shown to the user.
  final String question;

  /// The correct answer for this question.
  final String correctAnswer;

  /// First wrong answer option.
  final String wrongAnswer1;

  /// Second wrong answer option.
  final String wrongAnswer2;

  /// Third wrong answer option.
  final String wrongAnswer3;

  const CustomQuizEntry({
    required this.id,
    required this.question,
    required this.correctAnswer,
    required this.wrongAnswer1,
    required this.wrongAnswer2,
    required this.wrongAnswer3,
  });

  /// Creates a CustomQuizEntry from a CSV row.
  ///
  /// Expected format: id;question;correct answer;wrong answer 1;wrong answer 2;wrong answer 3
  factory CustomQuizEntry.fromCsvRow(String row) {
    final parts = row.split(';').map((p) => p.trim()).toList();

    if (parts.length < 6) {
      throw FormatException(
        'Invalid CSV row: expected 6 fields separated by semicolons, got ${parts.length}',
      );
    }

    final id = int.tryParse(parts[0]);
    if (id == null) {
      throw FormatException('Invalid ID: ${parts[0]} is not a valid integer');
    }

    return CustomQuizEntry(
      id: id,
      question: parts[1],
      correctAnswer: parts[2],
      wrongAnswer1: parts[3],
      wrongAnswer2: parts[4],
      wrongAnswer3: parts[5],
    );
  }

  /// Returns all answer options as a list.
  List<String> get allAnswers => [
    correctAnswer,
    wrongAnswer1,
    wrongAnswer2,
    wrongAnswer3,
  ];

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
