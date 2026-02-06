// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:jpn_learning_diary/models/anki_card.dart';
import 'package:jpn_learning_diary/services/anki_service.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:path/path.dart' as path;

/// Represents the user's self-assessment of how well they knew a card.
enum CardRating {
  /// Did not know the answer at all.
  again,

  /// Knew the answer but it was difficult.
  hard,

  /// Knew the answer well.
  good,

  /// Knew the answer perfectly / too easy.
  easy,
}

/// Represents a single entry in the review deck.
///
/// Each card appears twice: once in normal orientation and once with
/// front and back swapped.
class _DeckEntry {
  final AnkiCard card;
  final bool isReversed;

  /// Whether this entry has been seen (rated) at least once.
  bool seen = false;

  _DeckEntry(this.card, {this.isReversed = false});
}

/// Controller for the Anki flashcard review mode.
///
/// Manages the flashcard session state including loading cards from an APKG file,
/// tracking flip state, self-assessment ratings, and session progress.
/// Unlike the quiz mode, flashcards use a self-assessment model where the user
/// flips the card to see the answer and rates their own knowledge.
///
/// Cards are presented in order, each appearing twice (normal + reversed).
/// Rating a card Again, Hard, or Good moves it to the end of the deck.
/// Rating Easy removes it. The session ends when the deck is empty.
class AnkiController extends ChangeNotifier {
  /// The list of cards for the current session.
  List<AnkiCard> _cards = [];

  /// The active review deck (queue of entries to review).
  List<_DeckEntry> _deck = [];

  /// Total number of entries initially in the deck.
  int _initialDeckSize = 0;

  /// Whether the current card is showing its back (answer) side.
  bool _isFlipped = false;

  /// Whether the session has been completed.
  bool _isCompleted = false;

  /// Loading state.
  bool _isLoading = false;

  /// Error message if loading failed.
  String? _errorMessage;

  /// The raw cards loaded (for restarting).
  List<AnkiCard> _loadedCards = [];

  /// The source name of the loaded deck.
  String _sourceName = '';

  /// Path to the APKG file for on-demand media extraction.
  String? _apkgPath;

  /// Media map from the APKG (archive index -> original filename).
  Map<String, String> _mediaMap = {};

  /// Path to the temp cache directory for extracted audio files.
  String? _audioCacheDir;

  /// Whether this deck has any audio media.
  bool get hasMedia => _mediaMap.isNotEmpty;

  /// Cumulative count of each rating during the session.
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;

  // Getters
  List<AnkiCard> get cards => _cards;
  bool get isFlipped => _isFlipped;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get sourceName => _sourceName;

  /// Whether the current deck entry has its front and back swapped.
  bool get isCurrentCardReversed =>
      _deck.isNotEmpty ? _deck[0].isReversed : false;

  /// Whether there are cards to review.
  bool get hasCards => _cards.isNotEmpty;

  /// The current card being displayed, or null if none.
  AnkiCard? get currentCard => _deck.isNotEmpty ? _deck[0].card : null;

  /// Total number of presentations in the session (cards x 2).
  int get totalCards => _initialDeckSize;

  /// Number of unique cards selected for the session.
  int get selectedCardCount => _cards.length;

  /// Number of entries remaining in the review deck.
  int get remainingCards => _deck.length;

  /// Number of new (unseen) entries still in the deck.
  int get newCards => _deck.where((e) => !e.seen).length;

  /// Number of entries that have been reviewed but are still in the deck.
  int get reviewingCards => _deck.where((e) => e.seen).length;

  /// Number of entries completed (removed via Easy).
  int get completedCards => _easyCount;

  /// Whether the current entry is the last one in the deck.
  bool get isLastCard => _deck.length <= 1;

  /// Count of cards completed via Easy rating.
  int get knownCount => _easyCount;

  /// Count of Again + Hard ratings given during the session.
  int get needsReviewCount => _againCount + _hardCount;

  /// The percentage of entries completed (0-100).
  int get knownPercentage =>
      _initialDeckSize == 0
          ? 0
          : (_easyCount / _initialDeckSize * 100).round();

  /// Rating count getters for the completion summary.
  int get againCount => _againCount;
  int get hardCount => _hardCount;
  int get goodCount => _goodCount;
  int get easyCount => _easyCount;

  /// Loads flashcards from an APKG file path.
  ///
  /// [filePath] - Full path to the APKG file
  /// [sourceName] - A display name for the deck
  Future<void> loadFromFile(String filePath, {String? sourceName}) async {
    _isLoading = true;
    _errorMessage = null;
    _sourceName = sourceName ?? filePath.split('/').last.split('\\').last;
    notifyListeners();

    try {
      final deckData = await AnkiService.loadFromFile(filePath);
      _apkgPath = deckData.apkgPath;
      _mediaMap = deckData.mediaMap;
      await _processCards(deckData.cards);
    } catch (e) {
      _errorMessage = 'Failed to load deck: $e';
      _cards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Extracts and returns the path to a media file (audio or image) on-demand.
  ///
  /// Files are cached in a temp directory so they're only extracted once.
  Future<String?> getMediaFilePath(String fileName) async {
    if (_apkgPath == null) return null;

    // Create cache dir on first use
    _audioCacheDir ??= path.join(
      Directory.systemTemp.path,
      'anki_media_${DateTime.now().millisecondsSinceEpoch}',
    );

    return AnkiService.extractMediaFile(
      apkgPath: _apkgPath!,
      mediaMap: _mediaMap,
      fileName: fileName,
      cacheDir: _audioCacheDir!,
    );
  }

  /// Processes loaded cards into a session.
  ///
  /// Cards are presented in order. Each card appears twice: once in normal
  /// orientation and once with front/back swapped.
  Future<void> _processCards(List<AnkiCard> cards) async {
    _loadedCards = cards;

    if (cards.isEmpty) {
      _errorMessage = 'No valid cards found in this deck.';
      _cards = [];
      _deck = [];
      return;
    }

    final maxCards = await AppPreferences.getQuizQuestionCount();

    // Take cards in order up to the configured limit
    _cards = cards.take(min(maxCards, cards.length)).toList();

    // Build deck: normal cards first, then reversed copies
    _deck = [];
    for (final card in _cards) {
      _deck.add(_DeckEntry(card, isReversed: false));
    }
    for (final card in _cards) {
      _deck.add(_DeckEntry(card, isReversed: true));
    }

    _initialDeckSize = _deck.length;
    _resetSessionState();
  }

  /// Resets session state for a new review.
  void _resetSessionState() {
    _isFlipped = false;
    _isCompleted = false;
    _againCount = 0;
    _hardCount = 0;
    _goodCount = 0;
    _easyCount = 0;
  }

  /// Flips the current card to show the back (answer) side.
  void flipCard() {
    if (_isFlipped || currentCard == null) return;
    _isFlipped = true;
    notifyListeners();
  }

  /// Rates the current card.
  ///
  /// Easy removes the card from the deck. Again, Hard, and Good move the
  /// card to the end of the deck for another review. The session completes
  /// when the deck is empty.
  void rateCard(CardRating rating) {
    if (!_isFlipped || _deck.isEmpty) return;

    final entry = _deck.removeAt(0);
    entry.seen = true;

    switch (rating) {
      case CardRating.again:
        _againCount++;
        _deck.add(entry);
        break;
      case CardRating.hard:
        _hardCount++;
        _deck.add(entry);
        break;
      case CardRating.good:
        _goodCount++;
        _deck.add(entry);
        break;
      case CardRating.easy:
        _easyCount++;
        break;
    }

    _isFlipped = false;

    if (_deck.isEmpty) {
      _isCompleted = true;
    }

    notifyListeners();
  }

  /// Restarts the session with the same deck, reshuffled.
  Future<void> restart() async {
    await _processCards(_loadedCards);
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up extracted audio cache
    AnkiService.cleanupMediaDirectory(_audioCacheDir);
    super.dispose();
  }
}
