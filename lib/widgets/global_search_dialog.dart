import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/jmdict_repository.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/jmdict_card.dart';
import 'package:jpn_learning_diary/widgets/kanji_card.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Repositories
  final _diaryRepository = DiaryRepository();
  final _jmdictRepository = JMdictRepository();
  final _kanjiRepository = KanjiRepository();

  // Results
  List<DiaryEntry> _diaryResults = [];
  List<JMdictEntry> _jmdictResults = [];
  List<KanjiData> _kanjiResults = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_controller.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _lastQuery = '';
        _diaryResults = [];
        _jmdictResults = [];
        _kanjiResults = [];
        _isLoading = false;
      });
      return;
    }

    if (query == _lastQuery) return;

    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      final futures = await Future.wait([
        _diaryRepository.searchEntries(query),
        _jmdictRepository.search(query, limit: 5),
        _kanjiRepository.searchKanji(query),
      ]);

      if (mounted) {
        setState(() {
          _diaryResults = futures[0] as List<DiaryEntry>;
          _jmdictResults = futures[1] as List<JMdictEntry>;
          _kanjiResults = (futures[2] as List<KanjiData>).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const Spacer(),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _diaryResults.isNotEmpty ||
        _jmdictResults.isNotEmpty ||
        _kanjiResults.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedBorderColor =
        Theme.of(context).colorScheme.onSurface.withAlpha(isDark ? 125 : 30);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 16, right: 16),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape):
              () => Navigator.of(context).pop(),
        },
        child: FocusScope(
          autofocus: true,
          child: Container(
            width: 800,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mutedBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (value) {
                      Navigator.of(context).pop(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search diary, dictionary, kanji...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (hasResults ||
                    (_controller.text.isNotEmpty && !_isLoading)) ...[
                  const SizedBox(height: 16),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: mutedBorderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        child: ListView(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          children: [
                          if (_diaryResults.isNotEmpty) ...[
                            _buildSectionHeader('Diary Entries', Icons.book),
                            ..._diaryResults.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: DiaryEntryCard(
                                    entry: entry,
                                    onTap: () => Navigator.of(context).pop(
                                      JapaneseTextUtils.stripRubyPatterns(entry.japanese),
                                    ),
                                    onEntryUpdated: (updated) {
                                      // Update local list if entry is edited
                                      setState(() {
                                        final index = _diaryResults.indexWhere(
                                            (e) => e.id == updated.id);
                                        if (index != -1) {
                                          _diaryResults[index] = updated;
                                        }
                                      });
                                    },
                                  ),
                                )),
                          ],
                          if (_jmdictResults.isNotEmpty) ...[
                            _buildSectionHeader('Dictionary', Icons.translate),
                            ..._jmdictResults.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: JMdictCard(
                                    entry: entry,
                                    onTap: () => Navigator.of(context).pop(entry.kanji),
                                  ),
                                )),
                          ],
                          if (_kanjiResults.isNotEmpty) ...[
                            _buildSectionHeader('Kanji', Icons.edit),
                            ..._kanjiResults.map((kanji) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: KanjiCard(
                                    kanji: kanji,
                                    onTap: () => Navigator.of(context).pop(kanji.kanji),
                                  ),
                                )),
                          ],
                          if (!hasResults &&
                              _controller.text.isNotEmpty &&
                              !_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child:
                                  Center(child: Text('No results found')),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}
