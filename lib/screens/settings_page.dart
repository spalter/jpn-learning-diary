import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/services/file_access_service.dart';
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
        _buildDisplaySettingsSection(context),
        _buildDatabaseFileSetting(context),
        _buildClearDataSetting(context),
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
                selectedForegroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimary,
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

  /// Builds the display settings section.
  Widget _buildDisplaySettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShowRomajiSetting(context),
        _buildShowFuriganaSetting(context),
      ],
    );
  }

  /// Builds the show romaji toggle setting.
  Widget _buildShowRomajiSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: FutureBuilder<bool>(
        future: AppPreferences.getShowRomaji(),
        builder: (context, snapshot) {
          final showRomaji = snapshot.data ?? true;
          return SwitchListTile(
            title: const Text('Show Romaji'),
            subtitle: const Text('Display romanization in diary entry cards'),
            value: showRomaji,
            onChanged: (value) async {
              await AppPreferences.setShowRomaji(value);
              setState(() {}); // Refresh to show updated value
            },
          );
        },
      ),
    );
  }

  /// Builds the show furigana toggle setting.
  Widget _buildShowFuriganaSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: FutureBuilder<bool>(
        future: AppPreferences.getShowFurigana(),
        builder: (context, snapshot) {
          final showFurigana = snapshot.data ?? true;
          return SwitchListTile(
            title: const Text('Show Furigana'),
            subtitle: const Text('Display reading guides above Japanese text'),
            value: showFurigana,
            onChanged: (value) async {
              await AppPreferences.setShowFurigana(value);
              setState(() {}); // Refresh to show updated value
            },
          );
        },
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
          child: const Text('Select'),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
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
      final diaryRepository = DiaryRepository();
      await diaryRepository.deleteAllEntries();
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

  /// Handles the process of changing the database file location.
  ///
  /// **Workflow:**
  /// 1. Prompts user to select a .db file via file picker
  /// 2. Verifies the selected file exists
  /// 3. Saves the file path to preferences
  /// 4. On macOS: Creates a security-scoped bookmark for persistent access
  /// 5. Resets database connection to immediately use the new file
  /// 6. Refreshes UI to display the new path
  ///
  /// **macOS Security-Scoped Bookmarks:**
  /// On macOS, creating a bookmark is essential for maintaining access to files
  /// outside the app's sandbox across app restarts. If bookmark creation fails,
  /// the user will need to re-select the file after each app restart.
  ///
  /// **Use Case:**
  /// Allows users to store their database in a custom location such as:
  /// - Cloud storage folders (Dropbox, Google Drive, iCloud Drive)
  /// - External drives
  /// - Network shares
  /// - Any location accessible to the user
  Future<void> _handleChangeDatabasePath(BuildContext context) async {
    // Show file picker and wait for user selection
    final selectedPath = await _pickDatabaseFile();
    if (selectedPath == null) return; // User cancelled

    if (!mounted) return;

    // Verify file exists before proceeding
    if (!await _verifyFileExists(context, selectedPath)) return;

    // Persist the selected path to preferences
    await AppPreferences.setCustomDatabasePath(selectedPath);
    
    // macOS: Create security-scoped bookmark for persistent file access
    // This allows the app to access the file across restarts without re-selection
    if (Platform.isMacOS) {
      final bookmarkSaved = await FileAccessService.saveBookmark(selectedPath);
      if (!bookmarkSaved && mounted) {
        // Warn user if bookmark creation failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Warning: Could not save persistent access. You may need to select the file again after restart.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
    
    // Close existing database connection and force reconnection with new path
    await DatabaseHelper.instance.resetConnection();
    
    if (mounted) {
      // Notify user of success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Database file updated successfully. Reloading...',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Trigger UI rebuild to show updated database path
      setState(() {});
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
}
