import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:window_manager/window_manager.dart';

/// Practice mode where users type Japanese text for given English meanings.
///
/// Presents a random selection of diary entries and asks the user to
/// type the Japanese text when shown the English meaning.
class PracticeModePage extends StatefulWidget {
  const PracticeModePage({super.key});

  @override
  State<PracticeModePage> createState() => _PracticeModePageState();
}

class _PracticeModePageState extends State<PracticeModePage> {
  late Future<List<DiaryEntry>> _entriesFuture;
  List<DiaryEntry> _practiceEntries = [];
  int _currentIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  bool _showCorrectAnswer = false;
  bool _isCorrect = false;
  int _correctCount = 0;
  bool _isCompleted = false;
  bool _hasAttemptedCurrentQuestion = false;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadRandomEntries();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  /// Loads 10 random diary entries for practice.
  Future<List<DiaryEntry>> _loadRandomEntries() async {
    final allEntries = await DatabaseHelper.instance.getAllEntries();
    
    if (allEntries.isEmpty) {
      return [];
    }

    // Shuffle and take up to 10 entries
    final random = Random();
    final shuffled = List<DiaryEntry>.from(allEntries)..shuffle(random);
    final practiceEntries = shuffled.take(10).toList();
    
    setState(() {
      _practiceEntries = practiceEntries;
    });
    
    return practiceEntries;
  }

  /// Checks if the user's answer is correct.
  void _checkAnswer() {
    if (_practiceEntries.isEmpty || _currentIndex >= _practiceEntries.length) {
      return;
    }

    final currentEntry = _practiceEntries[_currentIndex];
    final userAnswer = _answerController.text.trim();
    final correctAnswer = currentEntry.japanese;

    if (userAnswer == correctAnswer) {
      setState(() {
        _isCorrect = true;
        // Only count if this is the first attempt
        if (!_hasAttemptedCurrentQuestion) {
          _correctCount++;
        }
      });
      
      // Move to next entry after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _moveToNext();
        }
      });
    } else {
      setState(() {
        _showCorrectAnswer = true;
        _isCorrect = false;
        _hasAttemptedCurrentQuestion = true;
      });
    }
  }

  /// Moves to the next entry or completes the practice session.
  void _moveToNext() {
    if (_currentIndex < _practiceEntries.length - 1) {
      setState(() {
        _currentIndex++;
        _answerController.clear();
        _showCorrectAnswer = false;
        _isCorrect = false;
        _hasAttemptedCurrentQuestion = false;
      });
      _answerFocusNode.requestFocus();
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  /// Resets and restarts the practice session.
  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _answerController.clear();
      _showCorrectAnswer = false;
      _isCorrect = false;
      _isCompleted = false;
      _hasAttemptedCurrentQuestion = false;
      _entriesFuture = _loadRandomEntries();
    });
    _answerFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DragToMoveArea(
          child: SizedBox(
            width: double.infinity,
            child: Text('Practice Mode'),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: FutureBuilder<List<DiaryEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (_practiceEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No diary entries to practice with.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (_isCompleted) {
            return _buildCompletionScreen(context);
          }

          return _buildPracticeScreen(context);
        },
      ),
    );
  }

  /// Builds the main practice screen.
  Widget _buildPracticeScreen(BuildContext context) {
    final currentEntry = _practiceEntries[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_practiceEntries.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Correct: $_correctCount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Center content with max width
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      currentEntry.meaning,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Answer input field
                  TextField(
                    controller: _answerController,
                    focusNode: _answerFocusNode,
                    autofocus: true,
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: InputDecoration(
                      labelText: 'Your answer',
                      hintText: 'Type in Japanese...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withAlpha(128),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      suffixIcon: _isCorrect
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    onSubmitted: (_) => _checkAnswer(),
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 18)),
                  ),

                  // Correct answer display (shown when wrong)
                  if (_showCorrectAnswer) ...[
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withAlpha(180),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Correct answer:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentEntry.furigana != null &&
                            currentEntry.furigana != currentEntry.japanese)
                          Text(
                            currentEntry.furigana!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        Text(
                          currentEntry.japanese,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _moveToNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        _currentIndex < _practiceEntries.length - 1
                            ? 'Next Question'
                            : 'Finish',
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the completion screen shown after all questions.
  Widget _buildCompletionScreen(BuildContext context) {
    final percentage = (_correctCount / _practiceEntries.length * 100).round();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              percentage >= 70 ? Icons.celebration : Icons.thumb_up,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Practice Complete!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'You got $_correctCount out of ${_practiceEntries.length} correct on first try',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Practice Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Dashboard'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
