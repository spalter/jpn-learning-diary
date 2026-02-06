// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/controllers/anki_controller.dart';
import 'package:jpn_learning_diary/models/anki_card.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:provider/provider.dart';

/// Anki flashcard review session screen.
///
/// Displays cards one at a time in a flashcard format. The user taps to flip
/// the card and reveal the answer, then self-assesses using rating buttons
/// (Again, Hard, Good, Easy). After reviewing all cards, a summary screen
/// shows the session results.
class AnkiFlashcardPage extends StatefulWidget {
  /// Path to the APKG file to load.
  final String? filePath;

  /// Display name for the deck.
  final String sourceName;

  const AnkiFlashcardPage({
    super.key,
    this.filePath,
    this.sourceName = 'Flashcards',
  });

  @override
  State<AnkiFlashcardPage> createState() => _AnkiFlashcardPageState();
}

class _AnkiFlashcardPageState extends State<AnkiFlashcardPage> {
  late AnkiController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnkiController();
    _loadDeck();
  }

  void _loadDeck() {
    if (widget.filePath != null) {
      _controller.loadFromFile(widget.filePath!, sourceName: widget.sourceName);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Plays an audio file, extracting it from the APKG on-demand.
  Future<void> _playAudio(String fileName) async {
    try {
      final audioPath = await _controller.getMediaFilePath(fileName);
      if (audioPath == null) return;

      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(audioPath));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<AnkiController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: LearningModeAppBar(title: widget.sourceName),
            backgroundColor: AppTheme.scaffoldBackground(context),
            body: _buildBody(context, controller),
          );
        },
      ),
    );
  }

  /// Builds the main body based on controller state.
  Widget _buildBody(BuildContext context, AnkiController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return _buildErrorState(context, controller);
    }

    if (!controller.hasCards) {
      return _buildEmptyState(context);
    }

    if (controller.isCompleted) {
      return _buildCompletionScreen(context, controller);
    }

    return _buildFlashcardScreen(context, controller);
  }

  /// Builds the error state.
  Widget _buildErrorState(BuildContext context, AnkiController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Deck',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the empty state when no cards are found.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Cards Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This deck does not contain any valid flashcards.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main flashcard review screen.
  Widget _buildFlashcardScreen(
    BuildContext context,
    AnkiController controller,
  ) {
    final currentCard = controller.currentCard!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressIndicator(context, controller),
                const SizedBox(height: 16),
                _buildFlashcard(context, controller, currentCard),
                const SizedBox(height: 24),
                if (controller.isFlipped)
                  _buildRatingButtons(context, controller)
                else
                  _buildFlipButton(context, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the progress indicator row.
  Widget _buildProgressIndicator(
    BuildContext context,
    AnkiController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Card ${controller.currentIndex + 1} of ${controller.totalCards}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Known: ${controller.knownCount}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the flashcard widget showing front or back.
  Widget _buildFlashcard(
    BuildContext context,
    AnkiController controller,
    AnkiCard card,
  ) {
    return GestureDetector(
      onTap: controller.isFlipped ? null : controller.flipCard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          color: controller.isFlipped
              ? Theme.of(context).colorScheme.secondaryContainer.withAlpha(40)
              : Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.isFlipped
                ? Theme.of(context).colorScheme.secondary.withAlpha(80)
                : Theme.of(context).colorScheme.primary.withAlpha(80),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side label + audio button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (controller.isFlipped
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary)
                        .withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    controller.isFlipped ? 'ANSWER' : 'QUESTION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: controller.isFlipped
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                // Audio play buttons for the current side
                ..._buildAudioButtons(context, controller, card),
              ],
            ),
            const SizedBox(height: 20),
            // Card content
            Text(
              controller.isFlipped ? card.back : card.front,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
            // Images for the current side
            ..._buildCardImages(context, controller, card),
            // Show extra fields when flipped
            if (controller.isFlipped && card.extraFields.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).colorScheme.outline.withAlpha(50),
              ),
              const SizedBox(height: 8),
              ...card.extraFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    field,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(180),
                    ),
                  ),
                ),
              ),
            ],
            // Tap hint when not flipped
            if (!controller.isFlipped) ...[
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Tap to reveal answer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(100),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds audio play buttons for the current card side.
  ///
  /// Shows a play button for each sound file referenced on the currently
  /// visible side of the card. Only shown when the deck has media.
  List<Widget> _buildAudioButtons(
    BuildContext context,
    AnkiController controller,
    AnkiCard card,
  ) {
    if (!controller.hasMedia) return [];

    // Show front sounds on the question side, all sounds on the answer side
    // (many decks put audio in dedicated fields that end up in extraSounds)
    final sounds = controller.isFlipped
        ? {...card.backSounds, ...card.frontSounds, ...card.extraSounds}.toList()
        : [...card.frontSounds, ...card.extraSounds];
    if (sounds.isEmpty) return [];

    return sounds.map((soundFile) {
      return IconButton(
        onPressed: () => _playAudio(soundFile),
        icon: const Icon(Icons.volume_up),
        tooltip: 'Play audio',
        iconSize: 22,
        color: controller.isFlipped
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.primary,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      );
    }).toList();
  }

  /// Builds image widgets for the current card side.
  List<Widget> _buildCardImages(
    BuildContext context,
    AnkiController controller,
    AnkiCard card,
  ) {
    if (!controller.hasMedia) return [];

    final images = controller.isFlipped
        ? {...card.backImages, ...card.frontImages, ...card.extraImages}.toList()
        : [...card.frontImages, ...card.extraImages];
    if (images.isEmpty) return [];

    return [
      const SizedBox(height: 12),
      ...images.map(
        (imageFile) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _AnkiImage(
            key: ValueKey('${card.noteId}_$imageFile'),
            fileName: imageFile,
            controller: controller,
          ),
        ),
      ),
    ];
  }

  /// Builds the flip button shown before the card is revealed.
  Widget _buildFlipButton(BuildContext context, AnkiController controller) {
    return Center(
      child: TextButton.icon(
        onPressed: controller.flipCard,
        icon: const Icon(Icons.flip),
        label: const Text('Show Answer'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the rating buttons shown after the card is flipped.
  ///
  /// Four Anki-style self-assessment buttons: Again, Hard, Good, Easy.
  Widget _buildRatingButtons(BuildContext context, AnkiController controller) {
    return Column(
      children: [
        Text(
          'How well did you know this?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Again',
                rating: CardRating.again,
                color: Colors.red,
                controller: controller,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Hard',
                rating: CardRating.hard,
                color: Colors.orange,
                controller: controller,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Good',
                rating: CardRating.good,
                color: Colors.green,
                controller: controller,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatingButton(
                context,
                label: 'Easy',
                rating: CardRating.easy,
                color: Colors.blue,
                controller: controller,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a single rating button.
  Widget _buildRatingButton(
    BuildContext context, {
    required String label,
    required CardRating rating,
    required Color color,
    required AnkiController controller,
  }) {
    return TextButton(
      onPressed: () => controller.rateCard(rating),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color.withAlpha(20),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withAlpha(100)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Builds the completion screen shown after all cards are reviewed.
  Widget _buildCompletionScreen(
    BuildContext context,
    AnkiController controller,
  ) {
    final percentage = controller.knownPercentage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCompletionIcon(context, percentage),
            const SizedBox(height: 24),
            Text(
              'Session Complete!',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '${controller.totalCards} cards reviewed',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRatingSummary(context, controller),
            const SizedBox(height: 32),
            _buildCompletionButtons(context, controller),
          ],
        ),
      ),
    );
  }

  /// Builds the completion icon based on the known percentage.
  Widget _buildCompletionIcon(BuildContext context, int percentage) {
    IconData icon;
    Color color;

    if (percentage >= 80) {
      icon = Icons.emoji_events;
      color = Theme.of(context).colorScheme.primary;
    } else if (percentage >= 60) {
      icon = Icons.celebration;
      color = Theme.of(context).colorScheme.primary;
    } else {
      icon = Icons.thumb_up;
      color = Theme.of(context).colorScheme.secondary;
    }

    return Icon(icon, size: 80, color: color);
  }

  /// Builds the rating summary showing counts per rating.
  Widget _buildRatingSummary(
    BuildContext context,
    AnkiController controller,
  ) {
    final ratings = controller.ratings;
    final againCount =
        ratings.values.where((r) => r == CardRating.again).length;
    final hardCount =
        ratings.values.where((r) => r == CardRating.hard).length;
    final goodCount =
        ratings.values.where((r) => r == CardRating.good).length;
    final easyCount =
        ratings.values.where((r) => r == CardRating.easy).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRatingStat(context, 'Again', againCount, Colors.red),
          _buildRatingStat(context, 'Hard', hardCount, Colors.orange),
          _buildRatingStat(context, 'Good', goodCount, Colors.green),
          _buildRatingStat(context, 'Easy', easyCount, Colors.blue),
        ],
      ),
    );
  }

  /// Builds a single rating statistic column.
  Widget _buildRatingStat(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Builds the action buttons for the completion screen.
  Widget _buildCompletionButtons(
    BuildContext context,
    AnkiController controller,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: controller.restart,
          icon: const Icon(Icons.refresh),
          label: const Text('Study Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Decks'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

/// Widget that lazily extracts and displays an image from an APKG archive.
class _AnkiImage extends StatefulWidget {
  final String fileName;
  final AnkiController controller;

  const _AnkiImage({super.key, required this.fileName, required this.controller});

  @override
  State<_AnkiImage> createState() => _AnkiImageState();
}

class _AnkiImageState extends State<_AnkiImage> {
  String? _filePath;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _extractImage();
  }

  @override
  void didUpdateWidget(covariant _AnkiImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName) {
      _filePath = null;
      _loading = true;
      _failed = false;
      _extractImage();
    }
  }

  Future<void> _extractImage() async {
    try {
      final path = await widget.controller.getMediaFilePath(widget.fileName);
      if (mounted) {
        setState(() {
          _filePath = path;
          _loading = false;
          _failed = path == null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_failed || _filePath == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: Image.file(
          File(_filePath!),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
