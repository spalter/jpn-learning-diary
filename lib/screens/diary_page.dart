// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/controllers/diary_entries_controller.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/screens/search_results_page.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/widgets/common_states.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:provider/provider.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';

/// Phrases and words tracking and management page.
///
/// This widget displays the user's collection of learned phrases and vocabulary.
/// It provides a grid-based view of diary entries and allows for detailed management
/// of the learning diary.
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late DiaryEntriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DiaryEntriesController();
    _controller.loadEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _buildEntriesList())],
      ),
    );
  }

  /// Builds the main entries list with loading and error states.
  Widget _buildEntriesList() {
    return Consumer<DiaryEntriesController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const LoadingState();
        }

        if (controller.errorMessage != null) {
          return ErrorState(error: controller.errorMessage);
        }

        if (controller.isEmpty) {
          return const EmptyState(
            message: 'No entries yet. Add your first entry!',
          );
        }

        return _buildEntriesListView(controller.entries);
      },
    );
  }

  /// Builds the scrollable list of diary entry cards.
  Widget _buildEntriesListView(List<DiaryEntry> entries) {
    return FutureBuilder<List<bool>>(
      future: Future.wait([
        AppPreferences.getShowRomaji(),
        AppPreferences.getShowFurigana(),
      ]),
      builder: (context, snapshot) {
        final showRomaji = snapshot.data?[0] ?? true;
        final showFurigana = snapshot.data?[1] ?? true;

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildEntryCard(
              entry,
              key: ValueKey(entry.id),
              showRomaji: showRomaji,
              showFurigana: showFurigana,
            );
          },
        );
      },
    );
  }

  /// Builds a single diary entry card.
  Widget _buildEntryCard(
    DiaryEntry entry, {
    Key? key,
    required bool showRomaji,
    required bool showFurigana,
  }) {
    return DiaryEntryCard(
      key: key,
      entry: entry,
      onDoubleTap: () => _openSearchForEntry(entry),
      showRomaji: showRomaji,
      showFurigana: showFurigana,
      onEntryUpdated: _controller.updateEntry,
      onEntryDeleted: (id) => _controller.removeEntry(id),
    );
  }

  /// Opens the search results page for the given entry's Japanese text.
  void _openSearchForEntry(DiaryEntry entry) {
    if (!mounted) return;

    final query = JapaneseTextUtils.stripRubyPatterns(entry.japanese);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(searchQuery: query),
      ),
    );
  }
}
