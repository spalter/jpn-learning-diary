import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';

/// Application settings and configuration page.
///
/// Provides access to app preferences, theme settings,
/// and other configuration options.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          // Data Management Section
          Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Clear All Data'),
              subtitle: const Text('Delete all diary entries from the database'),
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Data'),
                      content: const Text(
                        'Are you sure you want to delete all diary entries? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete All'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await DatabaseHelper.instance.deleteAllEntries();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All data has been cleared'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Clear Data'),
              ),
            ),
          ),
          
          // Debug Section (only in debug mode)
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Text(
              'Debug',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.folder,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Database Location'),
              subtitle: FutureBuilder<String>(
                future: DatabaseHelper.instance.getDatabasePath(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SelectableText(
                      snapshot.data!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    );
                  }
                  return const Text('Loading...');
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.delete_sweep,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete Entire Database'),
              subtitle: const Text('Remove database file and reload on restart'),
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Database'),
                      content: const Text(
                        'Are you sure you want to delete the entire database? '
                        'This will remove all diary entries and kanji data. '
                        'The app will restart with a fresh database.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete Database'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await DatabaseHelper.instance.deleteDatabase();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Database deleted. Please restart the app.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete DB'),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}
