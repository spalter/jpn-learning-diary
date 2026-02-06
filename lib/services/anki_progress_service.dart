// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Tracks per-card review progress for Anki flashcard decks.
///
/// Progress is stored as a JSON file alongside each APKG file
/// (e.g. `deck.apkg.progress.json`). Each card is tracked by its
/// note ID with a last rating, review count, and last review date.
///
/// This data is used to:
/// - Resume progress (skip already-mastered cards)
/// - Show deck statistics in the deck selection screen
/// - Order cards so unreviewed and weaker cards come first
class AnkiProgressService {
  AnkiProgressService._();

  /// Returns the progress file path for a given APKG file.
  static String _progressPath(String apkgPath) => '$apkgPath.progress.json';

  /// Loads deck progress from disk.
  ///
  /// Returns an empty [DeckProgress] if no progress file exists yet.
  static Future<DeckProgress> loadProgress(String apkgPath) async {
    try {
      final file = File(_progressPath(apkgPath));
      if (!await file.exists()) {
        return DeckProgress();
      }
      final json = jsonDecode(await file.readAsString());
      return DeckProgress.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to load Anki progress: $e');
      return DeckProgress();
    }
  }

  /// Saves deck progress to disk.
  static Future<void> saveProgress(
    String apkgPath,
    DeckProgress progress,
  ) async {
    try {
      final file = File(_progressPath(apkgPath));
      await file.writeAsString(jsonEncode(progress.toJson()));
    } catch (e) {
      debugPrint('Failed to save Anki progress: $e');
    }
  }

  /// Loads a summary of deck progress for display in the deck list.
  ///
  /// This is a lightweight read that only needs the card count and
  /// review statistics, not the full card list.
  static Future<DeckProgressSummary> loadSummary(String apkgPath) async {
    final progress = await loadProgress(apkgPath);
    return DeckProgressSummary(
      totalCards: progress.totalCards,
      totalReviewed: progress.cards.length,
      mastered: progress.cards.values
          .where((c) => c.lastRating == 'easy' && c.reviewCount >= 2)
          .length,
      lastStudied: progress.lastStudied,
    );
  }

  /// Deletes the progress file for a deck.
  static Future<void> deleteProgress(String apkgPath) async {
    try {
      final file = File(_progressPath(apkgPath));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup
    }
  }
}

/// Progress data for an entire deck.
class DeckProgress {
  /// Per-card progress, keyed by note ID (as string for JSON).
  final Map<String, CardProgress> cards;

  /// Total number of cards in the deck (stored on first open).
  int? totalCards;

  /// Timestamp of the last study session.
  DateTime? lastStudied;

  DeckProgress({
    Map<String, CardProgress>? cards,
    this.totalCards,
    this.lastStudied,
  }) : cards = cards ?? {};

  factory DeckProgress.fromJson(Map<String, dynamic> json) {
    final cardsJson = json['cards'] as Map<String, dynamic>? ?? {};
    final cards = cardsJson.map(
      (key, value) => MapEntry(
        key,
        CardProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
    final lastStudied = json['lastStudied'] != null
        ? DateTime.tryParse(json['lastStudied'] as String)
        : null;
    final totalCards = json['totalCards'] as int?;
    return DeckProgress(
      cards: cards,
      totalCards: totalCards,
      lastStudied: lastStudied,
    );
  }

  Map<String, dynamic> toJson() => {
    'cards': cards.map((key, value) => MapEntry(key, value.toJson())),
    if (totalCards != null) 'totalCards': totalCards,
    if (lastStudied != null) 'lastStudied': lastStudied!.toIso8601String(),
  };

  /// Records a review result for a card.
  void recordReview(int noteId, String rating) {
    final key = noteId.toString();
    final existing = cards[key];
    cards[key] = CardProgress(
      lastRating: rating,
      reviewCount: (existing?.reviewCount ?? 0) + 1,
      lastReviewed: DateTime.now(),
    );
    lastStudied = DateTime.now();
  }
}

/// Progress data for a single card.
class CardProgress {
  /// The last self-assessment rating: 'again', 'hard', 'good', or 'easy'.
  final String lastRating;

  /// How many times this card has been reviewed across all sessions.
  final int reviewCount;

  /// When this card was last reviewed.
  final DateTime lastReviewed;

  const CardProgress({
    required this.lastRating,
    required this.reviewCount,
    required this.lastReviewed,
  });

  factory CardProgress.fromJson(Map<String, dynamic> json) {
    return CardProgress(
      lastRating: json['lastRating'] as String? ?? 'again',
      reviewCount: json['reviewCount'] as int? ?? 0,
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lastRating': lastRating,
    'reviewCount': reviewCount,
    'lastReviewed': lastReviewed.toIso8601String(),
  };
}

/// Lightweight summary of deck progress for list display.
class DeckProgressSummary {
  /// Total number of cards in the deck (null if not yet recorded).
  final int? totalCards;

  /// Number of unique cards that have been reviewed at least once.
  final int totalReviewed;

  /// Number of cards considered mastered (easy + reviewed multiple times).
  final int mastered;

  /// When the deck was last studied.
  final DateTime? lastStudied;

  const DeckProgressSummary({
    this.totalCards,
    required this.totalReviewed,
    required this.mastered,
    this.lastStudied,
  });
}
