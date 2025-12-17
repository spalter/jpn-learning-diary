import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';

/// Phrases and words tracking page.
///
/// Displays and manages learned Japanese phrases and vocabulary words.
/// Provides functionality to track learning progress and practice.
class PhrasesWordsPage extends StatefulWidget {
  const PhrasesWordsPage({super.key});

  @override
  State<PhrasesWordsPage> createState() => _PhrasesWordsPageState();
}

class _PhrasesWordsPageState extends State<PhrasesWordsPage> {
  late Future<List<DiaryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  /// Fetches all diary entries from the database.
  /// 
  /// This is called when the page initializes and after any entry is added,
  /// updated, or deleted to ensure the list stays synchronized with the database.
  void _loadEntries() {
    setState(() {
      _entriesFuture = DatabaseHelper.instance.getAllEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      onEntryAdded: _loadEntries,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entries list
          Expanded(
            child: FutureBuilder<List<DiaryEntry>>(
              future: _entriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                final entries = snapshot.data ?? [];
                
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No entries yet. Add your first entry!'),
                  );
                }
                
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return DiaryEntryCard(
                      entry: entries[index],
                      onUpdate: _loadEntries,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
