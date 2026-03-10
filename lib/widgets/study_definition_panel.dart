// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/widgets/jmdict_card.dart';

/// A dedicated panel for displaying dictionary search results in Study Mode.
///
/// This widget manages the presentation of dictionary lookup results when a user
/// selects a word in the text analyzer. It handles various states including
/// loading, empty results, and successful matches, providing annotation tools
/// for the selected word.
///
/// * [selectedWord]: The word currently being looked up or annotated.
/// * [isSearching]: Whether a dictionary search is currently in progress.
/// * [results]: List of dictionary entry objects found for the search.
/// * [scrollController]: Controller for the results list scroll view.
/// * [currentAnnotation]: The current user note for the selected word.
/// * [onAnnotationChanged]: Callback when the annotation text is modified.
class StudySearchResultsPanel extends StatelessWidget {
  final String? selectedWord;
  final bool isSearching;
  final List<JMdictEntry> results;
  final ScrollController? scrollController;
  final String? currentAnnotation;
  final ValueChanged<String> onAnnotationChanged;

  const StudySearchResultsPanel({
    super.key,
    required this.selectedWord,
    required this.isSearching,
    required this.results,
    this.scrollController,
    this.currentAnnotation,
    required this.onAnnotationChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedWord == null) {
      return _buildHint(context);
    }

    if (isSearching) {
      return _buildLoading(context);
    }

    if (results.isEmpty) {
      return _buildNoResults(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                selectedWord!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${results.length} results)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        _buildAnnotationInput(context),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: results.length,
            itemBuilder: (context, index) {
              return JMdictCard(
                entry: results[index]
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap a word to search',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dictionary results will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Searching for "$selectedWord"...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            selectedWord!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        _buildAnnotationInput(context),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  'No results for "$selectedWord"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnotationInput(BuildContext context) {
    return _AnnotationInput(
      initialValue: currentAnnotation,
      onChanged: onAnnotationChanged,
    );
  }
}

class _AnnotationInput extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const _AnnotationInput({
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<_AnnotationInput> createState() => _AnnotationInputState();
}

class _AnnotationInputState extends State<_AnnotationInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_AnnotationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_note,
            size: 18,
            color: Theme.of(context).colorScheme.primary.withAlpha(150),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add note (e.g., reading, meaning)...',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: widget.onChanged,
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
            ),
        ],
      ),
    );
  }
}
