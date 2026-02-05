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

/// Controller for the Anki flashcard review mode.
///
/// Manages the flashcard session state including loading cards from an APKG file,
/// tracking flip state, self-assessment ratings, and session progress.
/// Unlike the quiz mode, flashcards use a self-assessment model where the user
/// flips the card to see the answer and rates their own knowledge.
class AnkiController extends ChangeNotifier {
  /// The list of cards for the current session.
  List<AnkiCard> _cards = [];

  /// Index of the currently displayed card (0-based).
  int _currentIndex = 0;

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

  /// Ratings given to each card during the session.
  /// Maps card index to the rating the user assigned.
  final Map<int, CardRating> _ratings = {};

  // Getters
  List<AnkiCard> get cards => _cards;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get sourceName => _sourceName;
  Map<int, CardRating> get ratings => Map.unmodifiable(_ratings);

  /// Whether there are cards to review.
  bool get hasCards => _cards.isNotEmpty;

  /// The current card being displayed, or null if none.
  AnkiCard? get currentCard =>
      _cards.isNotEmpty && _currentIndex < _cards.length
          ? _cards[_currentIndex]
          : null;

  /// Total number of cards in the session.
  int get totalCards => _cards.length;

  /// Whether the current card is the last one.
  bool get isLastCard => _currentIndex >= _cards.length - 1;

  /// Count of cards rated as "good" or "easy" (considered known).
  int get knownCount => _ratings.values
      .where((r) => r == CardRating.good || r == CardRating.easy)
      .length;

  /// Count of cards rated as "again" or "hard" (considered needs review).
  int get needsReviewCount => _ratings.values
      .where((r) => r == CardRating.again || r == CardRating.hard)
      .length;

  /// The percentage of cards rated as known (0-100).
  int get knownPercentage =>
      _ratings.isEmpty ? 0 : (knownCount / _ratings.length * 100).round();

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
  Future<void> _processCards(List<AnkiCard> cards) async {
    _loadedCards = cards;

    if (cards.isEmpty) {
      _errorMessage = 'No valid cards found in this deck.';
      _cards = [];
      return;
    }

    final random = Random();
    final maxCards = await AppPreferences.getQuizQuestionCount();

    // Shuffle and take up to the configured card count
    final shuffled = List<AnkiCard>.from(cards)..shuffle(random);
    _cards = shuffled.take(min(maxCards, cards.length)).toList();

    _resetSessionState();
  }

  /// Resets session state for a new review.
  void _resetSessionState() {
    _currentIndex = 0;
    _isFlipped = false;
    _isCompleted = false;
    _ratings.clear();
  }

  /// Flips the current card to show the back (answer) side.
  void flipCard() {
    if (_isFlipped || currentCard == null) return;
    _isFlipped = true;
    notifyListeners();
  }

  /// Rates the current card and moves to the next one.
  ///
  /// The rating is stored for the session summary. After rating the last
  /// card, the session is marked as completed.
  void rateCard(CardRating rating) {
    if (!_isFlipped || currentCard == null) return;

    _ratings[_currentIndex] = rating;

    if (isLastCard) {
      _isCompleted = true;
    } else {
      _currentIndex++;
      _isFlipped = false;
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
