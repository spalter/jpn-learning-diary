import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/screens/practice_mode_page.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/section_header.dart';

/// Dashboard page showing learning progress overview and training modes.
///
/// Displays progress statistics and provides access to different
/// learning and training scenarios.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Triggers a reload of dashboard data from the database.
  void _loadData() {
    setState(() {
      _dataFuture = _fetchDashboardData();
    });
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final entries = await DatabaseHelper.instance.getAllEntries();
    return _DashboardData(totalEntries: entries.length);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          primary: true,
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
        );
      },
    );
  }

  /// Builds the statistics cards row showing key metrics.
  Widget _buildStatisticsRow(BuildContext context, _DashboardData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Diary Entries',
            value: '${data.totalEntries}',
            icon: Icons.menu_book,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Coming Soon',
            value: '-',
            icon: Icons.more_horiz,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Coming Soon',
            value: '-',
            icon: Icons.more_horiz,
          ),
        ),
      ],
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
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
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
          title: 'Practice',
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kanji Quiz mode coming soon!')),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(80),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }
}

/// Internal data model for dashboard statistics.
class _DashboardData {
  /// Total count of all diary entries in the database.
  final int totalEntries;

  _DashboardData({required this.totalEntries});
}
