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
import 'package:jpn_learning_diary/screens/custom_quiz_page.dart';
import 'package:jpn_learning_diary/services/custom_quiz_service.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';

/// Page for selecting a custom quiz from the quizzes folder.
///
/// Displays all available CSV quiz files from the user's Documents folder
/// and allows the user to select one to start a quiz.
class QuizSelectionPage extends StatefulWidget {
  const QuizSelectionPage({super.key});

  @override
  State<QuizSelectionPage> createState() => _QuizSelectionPageState();
}

class _QuizSelectionPageState extends State<QuizSelectionPage> {
  List<QuizFileInfo>? _quizzes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  /// Loads the list of available quizzes from the user's quizzes folder.
  ///
  /// This method initializes the quizzes folder with bundled samples if needed,
  /// then fetches all available quiz files. Updates the UI state to reflect
  /// loading progress, success with quiz data, or any errors encountered.
  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize folder with bundled samples if needed
      await CustomQuizService.initializeQuizzesFolder();
      // Load list of available quizzes
      final quizzes = await CustomQuizService.listAvailableQuizzes();
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quizzes: $e';
        _isLoading = false;
      });
    }
  }

  /// Imports a quiz file from the device using the file picker.
  ///
  /// Opens a file picker dialog for CSV files, copies the selected file
  /// to the app's quizzes directory (overwriting if it already exists),
  /// and refreshes the quiz list.
  Future<void> _importQuizFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final pickedFile = result.files.first;
      final bytes = pickedFile.bytes;
      final fileName = pickedFile.name;

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to read file')));
        }
        return;
      }

      // Get the quizzes directory and save the file
      final quizzesDir = await CustomQuizService.getQuizzesDirectory();
      final targetFile = File('${quizzesDir.path}/$fileName');
      await targetFile.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imported: $fileName')));
      }

      // Refresh the list
      await _loadQuizzes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to import: $e')));
      }
    }
  }

  /// Builds the main scaffold with app bar, background, and floating action button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningModeAppBar(title: 'My Quizzes'),
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: _buildBody(context),
    );
  }

  /// Builds the main body content based on the current loading state.
  ///
  /// Returns a loading indicator while fetching quizzes, an error state widget
  /// if loading failed, an empty state widget if no quizzes are found, or
  /// the quiz list when quizzes are available.
  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_quizzes == null || _quizzes!.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildQuizList(context);
  }

  /// Builds the error state UI displayed when quiz loading fails.
  ///
  /// Shows an error icon, title, the specific error message, and a retry
  /// button to allow the user to attempt loading quizzes again.
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
              'Error Loading Quizzes',
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
              onPressed: _loadQuizzes,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the empty state UI displayed when no quizzes are found.
  ///
  /// Shows a placeholder icon, informative text guiding the user to add
  /// quiz files, template information for creating quizzes, and action
  /// buttons to open the quizzes folder or refresh the list.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No Quizzes Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isAndroid || Platform.isIOS
                  ? 'Import a CSV quiz file to get started.'
                  : 'Add CSV quiz files to your quizzes folder to get started.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildTemplateInfo(context),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds the scrollable list of available quiz cards.
  ///
  /// Displays a header with the title and folder access button, followed
  /// by individual quiz cards for each available quiz file, and template
  /// information at the bottom for reference.
  Widget _buildQuizList(BuildContext context) {
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
                    'Available Quizzes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildFolderButton(context),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a quiz to start practicing',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 24),

              // Quiz cards
              ..._quizzes!.map(
                (quiz) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuizCard(context, quiz),
                ),
              ),

              const SizedBox(height: 24),
              _buildTemplateInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single quiz card displaying quiz information.
  ///
  /// Creates a tappable card showing the quiz name, file name, and a
  /// decorative icon. Tapping the card navigates to the quiz page.
  /// On mobile platforms, long-pressing shows a delete confirmation dialog.
  Widget _buildQuizCard(BuildContext context, QuizFileInfo quiz) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return AppCard.bordered(
      onTap: () => _startQuiz(context, quiz),
      onLongPress: isMobile ? () => _showDeleteDialog(context, quiz) : null,
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
              Icons.description,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quiz.fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog to delete a quiz file.
  Future<void> _showDeleteDialog(
    BuildContext context,
    QuizFileInfo quiz,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.name}"?'),
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
      await _deleteQuiz(quiz);
    }
  }

  /// Deletes a quiz file and refreshes the list.
  Future<void> _deleteQuiz(QuizFileInfo quiz) async {
    final success = await CustomQuizService.deleteQuiz(quiz.path);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted: ${quiz.name}')));
        await _loadQuizzes();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete quiz')));
      }
    }
  }

  /// Builds the folder access button row with refresh and open folder/import options.
  ///
  /// Always displays a refresh button. On desktop platforms, includes
  /// an "Open Folder" button. On mobile platforms, includes an "Import" button.
  Widget _buildFolderButton(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refresh button - always show
        IconButton(
          onPressed: _loadQuizzes,
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh',
        ),
        // Import button - mobile only
        if (isMobile)
          TextButton.icon(
            onPressed: _importQuizFile,
            icon: const Icon(Icons.file_upload, size: 18),
            label: const Text('Import'),
          ),
        // Folder button - desktop only
        if (!isMobile)
          TextButton.icon(
            onPressed: () async {
              await CustomQuizService.openQuizzesFolder();
            },
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Folder'),
          ),
      ],
    );
  }

  /// Builds the action buttons for the empty state.
  ///
  /// On desktop platforms, includes a button to open the quizzes folder.
  /// On mobile platforms, includes an import button.
  /// Always includes a refresh button to reload the quiz list.
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
            onPressed: _importQuizFile,
            icon: const Icon(Icons.file_upload),
            label: const Text('Import Quiz'),
          ),
        // Open folder button - desktop only
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () async {
              await CustomQuizService.openQuizzesFolder();
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Quizzes Folder'),
          ),
        OutlinedButton.icon(
          onPressed: _loadQuizzes,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  /// Builds the template information panel explaining how to create custom quizzes.
  ///
  /// Displays a styled container with instructions on the CSV format required
  /// for quiz files, including a selectable code example showing the expected
  /// semicolon-separated structure with question, reading, and meaning fields.
  Widget _buildTemplateInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
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
                'Create Your Own Quiz',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Create a CSV file with semicolon-separated values:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              CustomQuizService.getTemplate(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Save your file with a .csv extension in the quizzes folder. '
            'A template.csv file is provided for reference.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to the custom quiz page with the selected quiz.
  ///
  /// Pushes a new route to the navigation stack, passing the quiz file path
  /// and display name to the [CustomQuizPage] for loading and presenting
  /// the quiz content to the user.
  void _startQuiz(BuildContext context, QuizFileInfo quiz) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CustomQuizPage(filePath: quiz.path, sourceName: quiz.name),
      ),
    );
  }
}
