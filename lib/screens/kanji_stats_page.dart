import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/kanji_data.dart';
import 'package:jpn_learning_diary/repositories/kanji_repository.dart';
import 'package:jpn_learning_diary/theme/app_theme.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';
import 'package:jpn_learning_diary/screens/search_results_page.dart';

class KanjiStatsPage extends StatefulWidget {
  const KanjiStatsPage({super.key});

  @override
  State<KanjiStatsPage> createState() => _KanjiStatsPageState();
}

class _KanjiStatsPageState extends State<KanjiStatsPage> {
  final KanjiRepository _kanjiRepository = KanjiRepository();
  List<KanjiData>? _learnedKanji;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKanji();
  }

  Future<void> _loadKanji() async {
    try {
      final kanji = await _kanjiRepository.getAllLearnedKanji();
      
      // Sort kanji by stroke count ascending
      kanji.sort((a, b) => a.strokes.compareTo(b.strokes));

      if (mounted) {
        setState(() {
          _learnedKanji = kanji;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load kanji: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningModeAppBar(
        title: 'Unique Kanji',
      ),
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _learnedKanji == null || _learnedKanji!.isEmpty
              ? const Center(child: Text('No kanji found.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 100,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _learnedKanji!.length,
                  itemBuilder: (context, index) {
                    final kanjiData = _learnedKanji![index];
                    return AppCard.bordered(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: kanjiData.kanji));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied: ${kanjiData.kanji}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      onDoubleTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SearchResultsPage(
                              searchQuery: kanjiData.kanji,
                            ),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            kanjiData.kanji,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.1, // Tighter height to fit nicely in the grid
                            ),
                          ),
                          if (kanjiData.jlptNew != null || kanjiData.grade != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                kanjiData.jlptNew != null
                                    ? 'JLPT N${kanjiData.jlptNew}'
                                    : 'Grade ${kanjiData.grade}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}


