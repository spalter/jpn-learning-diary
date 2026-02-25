// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show File, Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/controllers/anki_controller.dart';
import 'package:jpn_learning_diary/screens/anki_flashcard_page.dart';
import 'package:jpn_learning_diary/services/anki_progress_service.dart';
import 'package:jpn_learning_diary/services/anki_service.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page for selecting an Anki flashcard deck from the flashcards folder.
///
/// Displays all available APKG files from the user's Documents folder
/// and allows the user to select one to start a flashcard review session.
class AnkiDeckSelectionPage extends StatefulWidget {
  const AnkiDeckSelectionPage({super.key});

  @override
  State<AnkiDeckSelectionPage> createState() => _AnkiDeckSelectionPageState();
}

class _AnkiDeckSelectionPageState extends State<AnkiDeckSelectionPage> {
  List<AnkiDeckInfo>? _decks;
  Map<String, DeckProgressSummary> _progressSummaries = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  /// Loads the list of available decks from the user's flashcards folder.
  Future<void> _loadDecks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AnkiService.initializeFlashcardsFolder();
      final decks = await AnkiService.listAvailableDecks();

      // Load progress summaries for all decks
      final summaries = <String, DeckProgressSummary>{};
      for (final deck in decks) {
        summaries[deck.path] =
            await AnkiProgressService.loadSummary(deck.path);
      }

      setState(() {
        _decks = decks;
        _progressSummaries = summaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load decks: $e';
        _isLoading = false;
      });
    }
  }

  /// Imports an APKG file from the device using the file picker.
  /// Uses stream-based copying to avoid loading the entire file into memory,
  Future<void> _importDeckFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final pickedFile = result.files.first;
      final fileName = pickedFile.name;

      // Validate file extension
      if (!fileName.toLowerCase().endsWith('.apkg')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an .apkg file'),
            ),
          );
        }
        return;
      }

      final sourcePath = pickedFile.path;
      if (sourcePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file')),
          );
        }
        return;
      }

      // Stream-copy the file to the flashcards directory
      final flashcardsDir = await AnkiService.getFlashcardsDirectory();
      final targetPath = '${flashcardsDir.path}/$fileName';
      await File(sourcePath).copy(targetPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported: $fileName')),
        );
      }

      // Refresh the list
      await _loadDecks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningModeAppBar(title: 'Flashcards'),
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: _buildBody(context),
    );
  }

  /// Builds the main body content based on loading state.
  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_decks == null || _decks!.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildDeckList(context);
  }

  /// Builds the error state.
  Widget _buildErrorState(BuildContext context) {
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
              'Error Loading Decks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDecks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the empty state when no decks are found.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No Decks Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isAndroid || Platform.isIOS
                  ? 'Import an APKG flashcard deck to get started.'
                  : 'Add APKG flashcard files to your flashcards folder to get started.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildApkgInfo(context),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 16),
            _buildAnkiWebLink(context),
          ],
        ),
      ),
    );
  }

  /// Builds the scrollable list of available deck cards.
  Widget _buildDeckList(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with folder button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Decks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildFolderButton(context),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a deck to start reviewing',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 24),

              // Deck cards
              ..._decks!.map(
                (deck) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDeckCard(context, deck),
                ),
              ),

              const SizedBox(height: 24),
              _buildApkgInfo(context),
              const SizedBox(height: 16),
              _buildAnkiWebLink(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single deck card.
  Widget _buildDeckCard(BuildContext context, AnkiDeckInfo deck) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final summary = _progressSummaries[deck.path];
    final hasReviewed = summary != null && summary.totalReviewed > 0;

    if (isMobile) {
      return _buildMobileDeckCard(context, deck, summary, hasReviewed);
    }
    return _buildDesktopDeckCard(context, deck, summary, hasReviewed);
  }

  /// Builds the desktop deck card with inline New/Review action buttons.
  Widget _buildDesktopDeckCard(
    BuildContext context,
    AnkiDeckInfo deck,
    DeckProgressSummary? summary,
    bool hasReviewed,
  ) {
    final borderColor =
        Theme.of(context).colorScheme.primary.withAlpha(80);
    return AppCard.bordered(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildDeckInfo(context, deck, summary, hasReviewed),
            ),
            Container(width: 1, color: borderColor),
            _buildStudyAction(
              context,
              icon: Icons.auto_awesome,
              label: 'New',
              onTap: () => _startDeck(context, deck, StudyMode.newCards),
            ),
            Container(width: 1, color: borderColor),
            _buildStudyAction(
              context,
              icon: Icons.replay,
              label: 'Review',
              onTap: hasReviewed
                  ? () => _startDeck(context, deck, StudyMode.review)
                  : null,
              muted: !hasReviewed,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the mobile deck card that opens a popup menu on tap.
  Widget _buildMobileDeckCard(
    BuildContext context,
    AnkiDeckInfo deck,
    DeckProgressSummary? summary,
    bool hasReviewed,
  ) {
    return AppCard.bordered(
      onTap: () => _showMobileDeckActions(context, deck, hasReviewed),
      padding: EdgeInsets.zero,
      child: _buildDeckInfo(context, deck, summary, hasReviewed),
    );
  }

  /// Builds the deck info section shared by both mobile and desktop cards.
  Widget _buildDeckInfo(
    BuildContext context,
    AnkiDeckInfo deck,
    DeckProgressSummary? summary,
    bool hasReviewed,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.style,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  deck.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (hasReviewed)
                  _buildProgressInfo(context, summary!)
                else
                  Text(
                    deck.fileName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet with deck actions on mobile.
  void _showMobileDeckActions(
    BuildContext context,
    AnkiDeckInfo deck,
    bool hasReviewed,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                deck.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('New Cards'),
              subtitle: const Text('Study new cards in order'),
              onTap: () {
                Navigator.of(ctx).pop();
                _startDeck(context, deck, StudyMode.newCards);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.replay,
                color: hasReviewed ? null : Theme.of(context).disabledColor,
              ),
              title: Text(
                'Review',
                style: hasReviewed
                    ? null
                    : TextStyle(color: Theme.of(context).disabledColor),
              ),
              subtitle: Text(
                'Review previously studied cards',
                style: hasReviewed
                    ? null
                    : TextStyle(color: Theme.of(context).disabledColor),
              ),
              onTap: hasReviewed
                  ? () {
                      Navigator.of(ctx).pop();
                      _startDeck(context, deck, StudyMode.review);
                    }
                  : null,
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary.withAlpha(80),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showDeleteDialog(context, deck);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Builds a full-height study mode action section for a deck card.
  Widget _buildStudyAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool muted = false,
  }) {
    final color = muted
        ? Theme.of(context).colorScheme.onSurface.withAlpha(60)
        : Theme.of(context).colorScheme.primary;
    return InkWell(
        onTap: onTap,
        hoverColor: Theme.of(context).colorScheme.primary.withAlpha(15),
        highlightColor: Theme.of(context).colorScheme.primary.withAlpha(20),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
    );
  }

  /// Builds the progress info row for a deck card.
  Widget _buildProgressInfo(BuildContext context, DeckProgressSummary summary) {
    final lastStudiedText = _formatLastStudied(summary.lastStudied);
    final percentage = summary.totalCards != null && summary.totalCards! > 0
        ? (summary.mastered / summary.totalCards! * 100).round()
        : null;
    return Row(
      children: [
        if (percentage != null) ...[          Text(
            '$percentage% mastered',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green.withAlpha(200),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\u00b7 ${summary.mastered}/${summary.totalCards}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ] else ...[          Text(
            '${summary.totalReviewed} reviewed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
        if (percentage == null && summary.mastered > 0) ...[
          const SizedBox(width: 8),
          Text(
            '\u00b7 ${summary.mastered} mastered',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green.withAlpha(200),
            ),
          ),
        ],
        if (lastStudiedText != null) ...[
          const SizedBox(width: 8),
          Text(
            '\u00b7 $lastStudiedText',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ],
    );
  }

  /// Formats "last studied" as a relative time string.
  String? _formatLastStudied(DateTime? lastStudied) {
    if (lastStudied == null) return null;
    final diff = DateTime.now().difference(lastStudied);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  /// Shows a confirmation dialog to delete a deck file.
  Future<void> _showDeleteDialog(
    BuildContext context,
    AnkiDeckInfo deck,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Are you sure you want to delete "${deck.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteDeck(deck);
    }
  }

  /// Deletes a deck file and refreshes the list.
  Future<void> _deleteDeck(AnkiDeckInfo deck) async {
    final success = await AnkiService.deleteDeck(deck.path);
    if (success) {
      // Also delete progress file
      await AnkiProgressService.deleteProgress(deck.path);
    }
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted: ${deck.name}')),
        );
        await _loadDecks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete deck')),
        );
      }
    }
  }

  /// Builds the folder access button row.
  Widget _buildFolderButton(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refresh button - always show
        IconButton(
          onPressed: _loadDecks,
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh',
        ),
        // Import button - mobile only
        if (isMobile)
          TextButton.icon(
            onPressed: _importDeckFile,
            icon: const Icon(Icons.file_upload, size: 18),
            label: const Text('Import'),
          ),
        // Folder button - desktop only
        if (!isMobile)
          TextButton.icon(
            onPressed: () async {
              await AnkiService.openFlashcardsFolder();
            },
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Folder'),
          ),
      ],
    );
  }

  /// Builds the action buttons for the empty state.
  Widget _buildActionButtons(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // Import button - mobile only
        if (isMobile)
          ElevatedButton.icon(
            onPressed: _importDeckFile,
            icon: const Icon(Icons.file_upload),
            label: const Text('Import Deck'),
          ),
        // Open folder button - desktop only
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () async {
              await AnkiService.openFlashcardsFolder();
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Flashcards Folder'),
          ),
        OutlinedButton.icon(
          onPressed: _loadDecks,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  /// Builds info panel about APKG files.
  Widget _buildApkgInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Anki Flashcard Decks',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Place .apkg files exported from Anki into the flashcards folder. '
            'You can export decks from Anki Desktop via File > Export, or '
            'download shared decks from AnkiWeb (ankiweb.net/shared/decks).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            Platform.isAndroid || Platform.isIOS
                ? 'On mobile, use the Import button to add .apkg files.'
                : 'Open the flashcards folder and drop your .apkg files there.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a link button to browse shared Japanese decks on AnkiWeb.
  Widget _buildAnkiWebLink(BuildContext context) {
    return TextButton.icon(
      onPressed: () => launchUrl(
        Uri.parse('https://ankiweb.net/shared/decks?search=japanese'),
      ),
      icon: const Icon(Icons.language, size: 18),
      label: const Text('Browse Japanese Decks on AnkiWeb'),
    );
  }

  /// Navigates to the flashcard page with the selected deck.
  void _startDeck(BuildContext context, AnkiDeckInfo deck, StudyMode mode) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AnkiFlashcardPage(
              filePath: deck.path,
              sourceName: deck.name,
              studyMode: mode,
            ),
          ),
        )
        .then((_) => _loadDecks()); // Refresh stats after returning
  }
}
