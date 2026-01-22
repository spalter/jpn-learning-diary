// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/models/word_data.dart';
import 'package:jpn_learning_diary/repositories/jmdict_repository.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/widgets/jmdict_card.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/widgets/bird_fab.dart';
import 'package:jpn_learning_diary/widgets/responsive_grid_view.dart';
import 'package:jpn_learning_diary/widgets/word_card.dart';
import 'package:jpn_learning_diary/widgets/takoboto_viewer.dart';

/// Study mode page for analyzing text and displaying kanji information.
///
/// Allows users to input Japanese text and see a breakdown of each line
/// with the kanji characters found in that line displayed as cards.
class StudyModePage extends StatefulWidget {
  const StudyModePage({super.key});

  @override
  State<StudyModePage> createState() => _StudyModePageState();
}

class _StudyModePageState extends State<StudyModePage> {
  final TextEditingController _textController = TextEditingController();
  final KanjiRepository _kanjiRepository = KanjiRepository();
  final JMdictRepository _jmdictRepository = JMdictRepository();

  /// Static storage for session persistence of input text.
  static String _sessionText = '';

  /// Map of line index to list of kanji found in that line.
  final Map<int, List<KanjiData>> _kanjiByLine = {};

  /// Map of line index to list of words found in that line.
  final Map<int, List<WordData>> _wordsByLine = {};

  /// Map of line index to list of JMdict entries found in that line.
  final Map<int, List<JMdictEntry>> _jmdictByLine = {};

  /// Current lines parsed from the input text.
  List<String> _lines = [];

  /// Tracks loading state for each line.
  final Map<int, bool> _loadingLines = {};

  /// Current view mode ('grid' or 'list').
  String _viewMode = 'list';

  /// Whether to show tokenized text with nakaguro separators.
  bool _showTokenized = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Restore text from session storage
    if (_sessionText.isNotEmpty) {
      _textController.text = _sessionText;
    }
    _loadViewMode();
  }

  /// Loads the view mode preference from app settings.
  Future<void> _loadViewMode() async {
    final viewMode = await AppPreferences.getViewMode();
    if (mounted) {
      setState(() {
        _viewMode = viewMode;
      });
    }
  }

  @override
  void dispose() {
    // Save text to session storage before disposing
    _sessionText = _textController.text;
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  /// Called when the text in the input field changes.
  void _onTextChanged() {
    final text = _textController.text;
    final newLines = text.split('\n');

    setState(() {
      _lines = newLines;
    });

    // Process each line for kanji
    for (int i = 0; i < newLines.length; i++) {
      _processLineForKanji(i, newLines[i]);
    }

    // Clean up kanji data for removed lines
    _kanjiByLine.removeWhere((key, value) => key >= newLines.length);
    _wordsByLine.removeWhere((key, value) => key >= newLines.length);
    _jmdictByLine.removeWhere((key, value) => key >= newLines.length);
    _loadingLines.removeWhere((key, value) => key >= newLines.length);
  }

  /// Punctuation characters that should not have nakaguro around them.
  static final RegExp _punctuationPattern = RegExp(
    r'^[、。！？「」『』（）〈〉《》【】〔〕・…―ー～，．：；]+$',
  );

  /// Opens Takoboto dictionary for the given word in a popup dialog.
  void _openTakoboto(String word) {
    if (!mounted) return;
    TakobotoViewer.showPopup(context, word);
  }

  /// Copies the word to clipboard and shows a snackbar.
  Future<void> _copyWord(BuildContext context, String word) async {
    await Clipboard.setData(ClipboardData(text: word));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $word'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Builds clickable tokenized text where each word can be tapped.
  Widget _buildClickableTokenizedText(BuildContext context, String line) {
    // Tokenize the text
    final tokens = JapaneseTextUtils.tokenize(
      line,
    ).where((t) => t.trim().isNotEmpty).toList();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < tokens.length; i++) ...[
          _buildClickableToken(context, tokens[i], i, tokens.length),
        ],
      ],
    );
  }

  /// Builds a single clickable token widget.
  Widget _buildClickableToken(
    BuildContext context,
    String token,
    int index,
    int totalTokens,
  ) {
    final isPunctuation = _punctuationPattern.hasMatch(token);
    final showSeparator = _showTokenized && !isPunctuation && index > 0;

    // Check if previous token was punctuation (for separator logic)
    // We'll handle this in the parent widget instead

    if (isPunctuation) {
      // Punctuation is not clickable
      return Text(
        token,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSeparator)
          Text(
            '・',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        _ClickableWord(
          word: token,
          onTap: () => _copyWord(context, token),
          onLongPress: () => _openTakoboto(token),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
        ),
      ],
    );
  }

  /// Extracts kanji characters from a line and fetches their data and words.
  /// Also tokenizes the line and searches JMdict for each token.
  Future<void> _processLineForKanji(int lineIndex, String line) async {
    // Extract kanji characters using regex
    final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
    final matches = kanjiPattern.allMatches(line);
    final kanjiChars = matches.map((m) => m.group(0)!).toSet().toList();

    // Tokenize the line for JMdict search
    final tokens = JapaneseTextUtils.tokenize(line)
        .where((t) => t.trim().isNotEmpty)
        .where((t) => !_punctuationPattern.hasMatch(t))
        .toSet()
        .toList();

    if (kanjiChars.isEmpty && tokens.isEmpty) {
      setState(() {
        _kanjiByLine[lineIndex] = [];
        _wordsByLine[lineIndex] = [];
        _jmdictByLine[lineIndex] = [];
        _loadingLines[lineIndex] = false;
      });
      return;
    }

    // Check if we need to update (compare with existing kanji)
    final existingKanji =
        _kanjiByLine[lineIndex]?.map((k) => k.kanji).toSet() ?? {};
    final newKanjiSet = kanjiChars.toSet();
    final existingJmdict =
        _jmdictByLine[lineIndex]?.map((e) => e.entSeq).toSet() ?? {};

    // Skip if no changes (simple check - kanji same and we already have jmdict data)
    if (existingKanji.containsAll(newKanjiSet) &&
        newKanjiSet.containsAll(existingKanji) &&
        existingJmdict.isNotEmpty) {
      return;
    }

    setState(() {
      _loadingLines[lineIndex] = true;
    });

    // Fetch kanji data for each character
    final kanjiDataList = <KanjiData>[];
    for (final char in kanjiChars) {
      final kanjiData = await _kanjiRepository.getKanji(char);
      if (kanjiData != null) {
        kanjiDataList.add(kanjiData);
      }
    }

    // Fetch JMdict entries for each token
    final jmdictEntries = <JMdictEntry>[];
    final seenEntSeqs = <int>{};
    for (final token in tokens) {
      final entries = await _jmdictRepository.searchByToken(token, limit: 5);
      for (final entry in entries) {
        if (!seenEntSeqs.contains(entry.entSeq)) {
          seenEntSeqs.add(entry.entSeq);
          jmdictEntries.add(entry);
        }
      }
    }

    if (mounted) {
      setState(() {
        _kanjiByLine[lineIndex] = kanjiDataList;
        _jmdictByLine[lineIndex] = jmdictEntries;
        _loadingLines[lineIndex] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      appBar: const LearningModeAppBar(title: 'Study Mode'),
      floatingActionButton: const BirdFab(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text input area
            _buildTextInputArea(context),
            const SizedBox(height: 12),

            // Tokenize toggle
            _buildTokenizeToggle(context),
            const SizedBox(height: 12),

            // Lines and kanji cards list
            Expanded(child: _buildLinesAndKanjiList(context)),
          ],
        ),
      ),
    );
  }

  /// Builds the tokenize toggle button.
  Widget _buildTokenizeToggle(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          size: 18,
          color: Theme.of(context).colorScheme.primary.withAlpha(150),
        ),
        const SizedBox(width: 8),
        Text(
          'Word separation',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
          ),
        ),
        const Spacer(),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: _showTokenized,
            onChanged: (value) {
              setState(() {
                _showTokenized = value;
              });
            },
          ),
        ),
      ],
    );
  }

  /// Builds the expandable text input area.
  Widget _buildTextInputArea(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 80, // Approximately 3 lines
      ),
      child: TextField(
        controller: _textController,
        maxLines: null, // Allows unlimited lines
        minLines: 3, // Shows at least 3 lines
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(80),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(80),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.primaryContainer.withAlpha(20),
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
      ),
    );
  }

  /// Builds the list view showing lines and their associated kanji cards.
  Widget _buildLinesAndKanjiList(BuildContext context) {
    if (_lines.isEmpty || (_lines.length == 1 && _lines[0].isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter some Japanese text above',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kanji found in each line will be displayed here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final line = _lines[index];
        final kanjiList = _kanjiByLine[index] ?? [];
        final wordsList = _wordsByLine[index] ?? [];
        final jmdictList = _jmdictByLine[index] ?? [];
        final isLoading = _loadingLines[index] ?? false;

        // Skip empty lines
        if (line.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildLineSection(
          context,
          index,
          line,
          kanjiList,
          wordsList,
          jmdictList,
          isLoading,
        );
      },
    );
  }

  /// Builds a section for a single line with its words and kanji cards below.
  Widget _buildLineSection(
    BuildContext context,
    int lineIndex,
    String line,
    List<KanjiData> kanjiList,
    List<WordData> wordsList,
    List<JMdictEntry> jmdictList,
    bool isLoading,
  ) {
    final hasResults =
        kanjiList.isNotEmpty || wordsList.isNotEmpty || jmdictList.isNotEmpty;
    final totalCount = jmdictList.length + wordsList.length + kanjiList.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line header with the text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(50),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line number badge
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${lineIndex + 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Line text with clickable words
                Expanded(child: _buildClickableTokenizedText(context, line)),
              ],
            ),
          ),

          // Results section (words + kanji)
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            )
          else if (hasResults)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      '$totalCount results (${jmdictList.length} dictionary, ${wordsList.length} words, ${kanjiList.length} kanji)',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _viewMode == 'grid'
                      ? _buildCombinedGridView(jmdictList, wordsList, kanjiList)
                      : _buildCombinedListView(
                          jmdictList,
                          wordsList,
                          kanjiList,
                        ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Text(
                'No kanji in this line',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a combined list view of JMdict cards, word cards, then kanji cards.
  Widget _buildCombinedListView(
    List<JMdictEntry> jmdictList,
    List<WordData> wordsList,
    List<KanjiData> kanjiList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // JMdict cards first (dictionary entries from tokens)
        ...jmdictList.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: JMdictCard(entry: entry, useBorderedStyle: false),
          ),
        ),
        // Word cards second
        ...wordsList.map(
          (word) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: WordCard(word: word, useBorderedStyle: false),
          ),
        ),
        // Then kanji cards
        ...kanjiList.map(
          (kanji) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: KanjiCard(kanji: kanji, useBorderedStyle: false),
          ),
        ),
      ],
    );
  }

  /// Builds a combined grid view of JMdict cards, word cards, then kanji cards.
  Widget _buildCombinedGridView(
    List<JMdictEntry> jmdictList,
    List<WordData> wordsList,
    List<KanjiData> kanjiList,
  ) {
    final totalCount = jmdictList.length + wordsList.length + kanjiList.length;

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = ResponsiveGridView.calculateCrossAxisCount(
            constraints.maxWidth,
            320.0, // minCardWidth
            8.0, // spacing
            EdgeInsets.zero,
          );

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3 / 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              // JMdict entries come first, then words, then kanji
              if (index < jmdictList.length) {
                return JMdictCard(
                  entry: jmdictList[index],
                  useBorderedStyle: true,
                );
              } else if (index < jmdictList.length + wordsList.length) {
                final wordIndex = index - jmdictList.length;
                return WordCard(
                  word: wordsList[wordIndex],
                  useBorderedStyle: true,
                );
              } else {
                final kanjiIndex = index - jmdictList.length - wordsList.length;
                return KanjiCard(
                  kanji: kanjiList[kanjiIndex],
                  useBorderedStyle: true,
                );
              }
            },
          );
        },
      ),
    );
  }
}

/// A clickable word widget that copies on tap and opens dictionary on long press.
class _ClickableWord extends StatefulWidget {
  final String word;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final TextStyle? style;

  const _ClickableWord({
    required this.word,
    required this.onTap,
    this.onLongPress,
    this.style,
  });

  @override
  State<_ClickableWord> createState() => _ClickableWordState();
}

class _ClickableWordState extends State<_ClickableWord> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.style?.color ?? Theme.of(context).colorScheme.onSurface;
    final hoverColor = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Text(
          widget.word,
          style:
              widget.style?.copyWith(
                color: _isHovering ? hoverColor : baseColor,
              ) ??
              TextStyle(color: _isHovering ? hoverColor : baseColor),
        ),
      ),
    );
  }
}
