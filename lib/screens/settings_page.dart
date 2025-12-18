import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:restart_app/restart_app.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/app_about_dialog.dart';
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
          // General Section
          Text('General', style: Theme.of(context).textTheme.titleMedium),
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
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('App information and licenses'),
              trailing: TextButton(
                onPressed: () {
                  showAppAboutDialog(context);
                },
                child: const Text('View'),
              ),
            ),
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
              subtitle: const Text(
                'Delete all diary entries from the database',
              ),
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
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
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
              leading: const Icon(Icons.storage),
              title: const Text('Database File'),
              subtitle: FutureBuilder<String>(
                future: DatabaseHelper.instance.getDatabasePath(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SelectableText(
                      snapshot.data!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    );
                  }
                  return const Text('Loading...');
                },
              ),
              trailing: FilledButton(
                onPressed: () async {
                  // Pick an existing database file
                  final result = await FilePicker.platform.pickFiles(
                    dialogTitle: 'Select Database File',
                    type: FileType.custom,
                    allowedExtensions: ['db'],
                    allowMultiple: false,
                  );

                  if (result != null &&
                      result.files.single.path != null &&
                      mounted) {
                    final selectedPath = result.files.single.path!;

                    // Verify the file exists
                    final file = File(selectedPath);
                    if (!await file.exists()) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selected file does not exist'),
                          ),
                        );
                      }
                      return;
                    }

                    // Save the new path (or clear if it's the default)
                    await AppPreferences.setCustomDatabasePath(selectedPath);

                    // Show restart dialog
                    if (mounted) {
                      final shouldRestart = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('Restart Required'),
                          content: const Text(
                            'The database file has been changed. '
                            'The application needs to restart to load the new database.\n\n'
                            'Would you like to restart now?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Later'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Restart Now'),
                            ),
                          ],
                        ),
                      );

                      if (shouldRestart == true) {
                        Restart.restartApp();
                      }
                    }
                  }
                },
                child: const Text('Change'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
