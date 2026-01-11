import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/widgets/responsive_grid_view.dart';

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

  /// Map of line index to list of kanji found in that line.
  final Map<int, List<KanjiData>> _kanjiByLine = {};

  /// Current lines parsed from the input text.
  List<String> _lines = [];

  /// Tracks loading state for each line.
  final Map<int, bool> _loadingLines = {};

  /// Current view mode ('grid' or 'list').
  String _viewMode = 'list';

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
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
    _loadingLines.removeWhere((key, value) => key >= newLines.length);
  }

  /// Extracts kanji characters from a line and fetches their data.
  Future<void> _processLineForKanji(int lineIndex, String line) async {
    // Extract kanji characters using regex
    final kanjiPattern = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
    final matches = kanjiPattern.allMatches(line);
    final kanjiChars = matches.map((m) => m.group(0)!).toSet().toList();

    if (kanjiChars.isEmpty) {
      setState(() {
        _kanjiByLine[lineIndex] = [];
        _loadingLines[lineIndex] = false;
      });
      return;
    }

    // Check if we need to update (compare with existing kanji)
    final existingKanji =
        _kanjiByLine[lineIndex]?.map((k) => k.kanji).toSet() ?? {};
    final newKanjiSet = kanjiChars.toSet();

    if (existingKanji.containsAll(newKanjiSet) &&
        newKanjiSet.containsAll(existingKanji)) {
      // No change in kanji characters
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

    if (mounted) {
      setState(() {
        _kanjiByLine[lineIndex] = kanjiDataList;
        _loadingLines[lineIndex] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningModeAppBar(title: 'Study Mode'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text input area
            _buildTextInputArea(context),
            const SizedBox(height: 24),

            // Lines and kanji cards list
            Expanded(child: _buildLinesAndKanjiList(context)),
          ],
        ),
      ),
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
        final isLoading = _loadingLines[index] ?? false;

        // Skip empty lines
        if (line.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildLineSection(context, index, line, kanjiList, isLoading);
      },
    );
  }

  /// Builds a section for a single line with its kanji cards below.
  Widget _buildLineSection(
    BuildContext context,
    int lineIndex,
    String line,
    List<KanjiData> kanjiList,
    bool isLoading,
  ) {
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
                Container(
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
                const SizedBox(width: 12),
                // Line text
                Expanded(
                  child: Text(
                    line,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          // Kanji cards section
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
                    'Loading kanji...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            )
          else if (kanjiList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      '${kanjiList.length} kanji found',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _viewMode == 'grid'
                      ? _buildKanjiGridView(kanjiList)
                      : _buildKanjiListView(kanjiList),
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

  /// Builds a list view of kanji cards (vertical stack).
  Widget _buildKanjiListView(List<KanjiData> kanjiList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: kanjiList
          .map(
            (kanji) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: KanjiCard(kanji: kanji, useBorderedStyle: false),
            ),
          )
          .toList(),
    );
  }

  /// Builds a grid view of kanji cards.
  Widget _buildKanjiGridView(List<KanjiData> kanjiList) {
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
            itemCount: kanjiList.length,
            itemBuilder: (context, index) =>
                KanjiCard(kanji: kanjiList[index], useBorderedStyle: true),
          );
        },
      ),
    );
  }
}
