import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/common_states.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/responsive_grid_view.dart';

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
    return FutureBuilder<String>(
      future: AppPreferences.getViewMode(),
      builder: (context, snapshot) {
        final viewMode = snapshot.data ?? 'list';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: viewMode == 'grid'
                  ? _buildEntriesGridView()
                  : _buildEntriesList(),
            ),
          ],
        );
      },
    );
  }

  /// Builds the main entries list with loading and error states.
  Widget _buildEntriesList() {
    return FutureBuilder<List<DiaryEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }

        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const EmptyState(
            message: 'No entries yet. Add your first entry!',
          );
        }

        return _buildEntriesListView(entries);
      },
    );
  }

  /// Builds a grid view of diary entry cards.
  Widget _buildEntriesGridView() {
    return FutureBuilder<List<DiaryEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }

        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const EmptyState(
            message: 'No entries yet. Add your first entry!',
          );
        }

        return ResponsiveGridView(
          itemCount: entries.length,
          minCardWidth: 320.0,
          itemBuilder: (context, index) =>
              _buildEntryCard(entries[index], useBorderedStyle: true),
        );
      },
    );
  }

  /// Builds the scrollable list of diary entry cards.
  Widget _buildEntriesListView(List<DiaryEntry> entries) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildEntryCard(entries[index]),
    );
  }

  /// Builds a single diary entry card.
  Widget _buildEntryCard(DiaryEntry entry, {bool useBorderedStyle = false}) {
    return DiaryEntryCard(
      entry: entry,
      onUpdate: _loadEntries,
      useBorderedStyle: useBorderedStyle,
    );
  }
}
