import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';

/// Phrases and words tracking page.
///
/// Displays and manages learned Japanese phrases and vocabulary words.
/// Provides functionality to track learning progress and practice.
class PhrasesWordsPage extends StatelessWidget {
  const PhrasesWordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entries list
          Expanded(
            child: ListView.builder(
              itemCount: DiaryData.dummyEntries.length,
              itemBuilder: (context, index) {
                final entry = DiaryData.dummyEntries[index];
                return DiaryEntryCard(entry: entry);
              },
            ),
          ),
        ],
      ),
    );
  }
}
