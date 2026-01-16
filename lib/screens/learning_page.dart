// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/controllers/learning_controller.dart';
import 'package:jpn_learning_diary/screens/practice_mode_page.dart';
import 'package:jpn_learning_diary/screens/study_mode_page.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/section_header.dart';
import 'package:provider/provider.dart';

/// Dashboard page showing learning progress overview and training modes.
///
/// Displays progress statistics and provides access to different
/// learning and training scenarios.
class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  late LearningController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LearningController();
    _controller.loadData();
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
      child: Consumer<LearningController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          if (!controller.hasData) {
            return const Center(child: Text('No data available'));
          }

          final data = controller.data!;

          return SingleChildScrollView(
            primary: true,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Row
                  _buildStatisticsRow(context, data),
                  const SizedBox(height: 48),

                  // Learning Modes Section
                  SectionHeader(title: 'Learning Modes', bottomPadding: 16),
                  _buildLearningModesGrid(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the statistics cards row showing key metrics.
  /// Shows items horizontally on desktop, vertically on mobile.
  Widget _buildStatisticsRow(BuildContext context, DashboardData data) {
    final isMobile = Platform.isAndroid || Platform.isIOS;

    final children = [
      _buildStatCard(
        context,
        title: 'Diary Entries',
        value: '${data.totalEntries}',
        icon: Icons.menu_book,
      ),
      _buildKanjiStatCard(context, data),
      _buildJlptLevelsCard(context, data),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: child,
                ))
            .toList(),
      );
    }

    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 16),
        Expanded(child: children[1]),
        const SizedBox(width: 16),
        Expanded(child: children[2]),
      ],
    );
  }

  /// Builds the kanji statistics card.
  Widget _buildKanjiStatCard(BuildContext context, DashboardData data) {
    return _buildStatCard(
      context,
      title: 'Unique Kanji',
      value: '${data.totalKanji}',
      icon: Icons.translate,
    );
  }

  /// Builds the JLPT levels card with horizontal layout.
  Widget _buildJlptLevelsCard(BuildContext context, DashboardData data) {
    final levels = [5, 4, 3, 2, 1];
    final levelNames = {5: 'N5', 4: 'N4', 3: 'N3', 2: 'N2', 1: 'N1'};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school,
            size: 32,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 14),
          // Horizontal layout of JLPT levels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: levels.map((level) {
              final count = data.kanjiByJlptLevel[level] ?? 0;
              return Column(
                children: [
                  Text(
                    levelNames[level]!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'JLPT Levels',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds a single statistics card.
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the grid of learning mode buttons.
  Widget _buildLearningModesGrid(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildLearningModeButton(
          context,
          title: 'Diary Quiz',
          icon: Icons.edit_note,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PracticeModePage()),
            );
          },
        ),
        _buildLearningModeButton(
          context,
          title: 'Kanji Quiz',
          icon: Icons.history_edu,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const PracticeModePage(mode: PracticeMode.kanji),
              ),
            );
          },
        ),
        _buildLearningModeButton(
          context,
          title: 'Study',
          icon: Icons.auto_stories,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StudyModePage()),
            );
          },
        ),
      ],
    );
  }

  /// Builds a single learning mode button.
  Widget _buildLearningModeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 200,
      height: 120,
      child: AppCard.bordered(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
