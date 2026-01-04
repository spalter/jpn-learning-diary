import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/controllers/diary_entries_controller.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/widgets/common_states.dart';
import 'package:jpn_learning_diary/widgets/diary_entry_card.dart';
import 'package:jpn_learning_diary/widgets/responsive_grid_view.dart';
import 'package:provider/provider.dart';

/// Phrases and words tracking page.
///
/// Displays and manages learned Japanese phrases and vocabulary words.
/// Provides functionality to track learning progress and practice.
class DiaryPage extends StatefulWidget {
  /// Callback to set search text in the navigation bar.
  final void Function(String)? onSearchTextSet;

  const DiaryPage({super.key, this.onSearchTextSet});

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
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          AppPreferences.getViewMode(),
          AppPreferences.getShowRomaji(),
          AppPreferences.getShowFurigana(),
        ]),
        builder: (context, snapshot) {
          final viewMode = snapshot.data?[0] as String? ?? 'list';
          final showRomaji = snapshot.data?[1] as bool? ?? true;
          final showFurigana = snapshot.data?[2] as bool? ?? true;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: viewMode == 'grid'
                    ? _buildEntriesGridView(
                        showRomaji: showRomaji,
                        showFurigana: showFurigana,
                      )
                    : _buildEntriesList(),
              ),
            ],
          );
        },
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

  /// Builds a grid view of diary entry cards.
  Widget _buildEntriesGridView({
    required bool showRomaji,
    required bool showFurigana,
  }) {
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

        return _buildGridView(
          controller.entries,
          showRomaji: showRomaji,
          showFurigana: showFurigana,
        );
      },
    );
  }

  /// Builds the grid view of diary entry cards.
  Widget _buildGridView(
    List<DiaryEntry> entries, {
    required bool showRomaji,
    required bool showFurigana,
  }) {
    // Use a taller aspect ratio (wider cards) when content is hidden
    // Default: 4/3 (~1.33), Compact: 5/2 (2.5) for shorter cards
    final isCompact = !showRomaji && !showFurigana;
    final aspectRatio = isCompact ? 5 / 3 : 4 / 3;

    return ResponsiveGridView(
      itemCount: entries.length,
      minCardWidth: 320.0,
      childAspectRatio: aspectRatio,
      itemBuilder: (context, index) =>
          _buildEntryCard(entries[index], useBorderedStyle: true),
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
      onUpdate: () => _controller.refresh(),
      onTap: widget.onSearchTextSet != null
          ? () => widget.onSearchTextSet!(entry.japanese)
          : null,
      useBorderedStyle: useBorderedStyle,
    );
  }
}
