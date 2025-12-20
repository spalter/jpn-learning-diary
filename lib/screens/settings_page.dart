import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:restart_app/restart_app.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/widgets/app_about_dialog.dart';

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
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAboutSetting(context),
          _buildViewModeSetting(context),
          _buildClearDataSetting(context),
          _buildDatabaseFileSetting(context),
        ],
      );
  }

  /// Builds a settings row container with bottom border.
  Widget _buildSettingRow({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: child,
    );
  }

  /// Builds the view mode setting row.
  Widget _buildViewModeSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: ListTile(
        title: const Text('Preferred View Mode'),
        subtitle: const Text('Choose between grid or list view'),
        trailing: FutureBuilder<String>(
          future: AppPreferences.getViewMode(),
          builder: (context, snapshot) {
            final currentMode = snapshot.data ?? 'list';
            return SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withAlpha(100),
                ),
              ),
              segments: const [
                ButtonSegment<String>(
                  value: 'list',
                  icon: Icon(Icons.view_list),
                  label: Text('List'),
                ),
                ButtonSegment<String>(
                  value: 'grid',
                  icon: Icon(Icons.grid_view),
                  label: Text('Grid'),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (Set<String> selection) async {
                await AppPreferences.setViewMode(selection.first);
                setState(() {}); // Refresh to show updated selection
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds the About setting row.
  Widget _buildAboutSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: ListTile(
        title: const Text('About'),
        subtitle: const Text('App information and licenses'),
        trailing: FilledButton(
          onPressed: () => showAppAboutDialog(context),
          child: const Text('View'),
        ),
      ),
    );
  }

  /// Builds the Clear All Data setting row.
  Widget _buildClearDataSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: ListTile(
        title: const Text('Clear All Data'),
        subtitle: const Text('Delete all diary entries from the database'),
        trailing: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _handleClearAllData(context),
          child: const Text('Clear Data'),
        ),
      ),
    );
  }

  /// Builds the Database File setting row.
  Widget _buildDatabaseFileSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: ListTile(
        title: const Text('Database File'),
        subtitle: _buildDatabasePathSubtitle(context),
        trailing: FilledButton(
          onPressed: () => _handleChangeDatabasePath(context),
          child: const Text('Change'),
        ),
      ),
    );
  }

  /// Builds the database path display as a subtitle.
  Widget _buildDatabasePathSubtitle(BuildContext context) {
    return FutureBuilder<String>(
      future: DatabaseHelper.instance.getDatabasePath(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SelectableText(
            snapshot.data!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontFamily: 'monospace'),
          );
        }
        return const Text('Loading...');
      },
    );
  }

  /// Handles the clear all data action.
  Future<void> _handleClearAllData(BuildContext context) async {
    final confirmed = await _showClearDataConfirmation(context);

    if (confirmed == true && mounted) {
      await DatabaseHelper.instance.deleteAllEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been cleared')),
        );
      }
    }
  }

  /// Shows a confirmation dialog for clearing all data.
  Future<bool?> _showClearDataConfirmation(BuildContext context) {
    return showDialog<bool>(
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
  }

  /// Handles changing the database path.
  Future<void> _handleChangeDatabasePath(BuildContext context) async {
    final selectedPath = await _pickDatabaseFile();
    if (selectedPath == null) return;

    if (!mounted) return;

    if (!await _verifyFileExists(context, selectedPath)) return;

    await AppPreferences.setCustomDatabasePath(selectedPath);

    if (mounted) {
      final shouldRestart = await _showRestartDialog(context);
      if (shouldRestart == true) {
        Restart.restartApp();
      }
    }
  }

  /// Picks a database file using the file picker.
  Future<String?> _pickDatabaseFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Database File',
      type: FileType.custom,
      allowedExtensions: ['db'],
      allowMultiple: false,
    );

    return result?.files.single.path;
  }

  /// Verifies that the selected file exists.
  Future<bool> _verifyFileExists(BuildContext context, String path) async {
    final file = File(path);
    if (await file.exists()) {
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file does not exist')),
      );
    }
    return false;
  }

  /// Shows a restart dialog after changing the database.
  Future<bool?> _showRestartDialog(BuildContext context) {
    return showDialog<bool>(
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
  }
}
