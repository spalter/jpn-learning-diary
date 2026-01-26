// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/services/app_preferences.dart';
import 'package:jpn_learning_diary/services/cloud_sync_service.dart';
import 'package:jpn_learning_diary/services/database_helper.dart';
import 'package:jpn_learning_diary/services/theme_notifier.dart';
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
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAboutSetting(context),
        _buildThemeStyleSetting(context),
        _buildViewModeSetting(context),
        _buildDisplaySettingsSection(context),
        _buildDatabaseFileSetting(context),
        _buildCloudSyncSetting(context),
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
    if (_isMobile) {
      return const SizedBox.shrink();
    }
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
                selectedBackgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface,
                selectedForegroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
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
        _buildQuizQuestionCountSetting(context),
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
            activeThumbColor: Theme.of(context).colorScheme.onSurface,
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
            activeThumbColor: Theme.of(context).colorScheme.onSurface,
            onChanged: (value) async {
              await AppPreferences.setShowFurigana(value);
              setState(() {}); // Refresh to show updated value
            },
          );
        },
      ),
    );
  }

  /// Builds the quiz question count setting.
  Widget _buildQuizQuestionCountSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: ListTile(
        title: const Text('Quiz Question Count'),
        subtitle: const Text('Number of questions per quiz session'),
        trailing: FutureBuilder<int>(
          future: AppPreferences.getQuizQuestionCount(),
          builder: (context, snapshot) {
            final currentCount =
                snapshot.data ?? AppPreferences.defaultQuizQuestionCount;
            return DropdownButton<int>(
              value: currentCount,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(8),
              items: AppPreferences.quizQuestionCountOptions.map((count) {
                return DropdownMenuItem<int>(
                  value: count,
                  child: Text('$count'),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  await AppPreferences.setQuizQuestionCount(value);
                  setState(() {}); // Refresh to show updated selection
                }
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
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
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

  /// Builds the Database File setting row (desktop only).
  Widget _buildDatabaseFileSetting(BuildContext context) {
    if (_isMobile) {
      return const SizedBox.shrink();
    }
    return _buildSettingRow(
      context: context,
      child: ListTile(
        title: const Text('Database File'),
        subtitle: _buildDatabasePathSubtitle(context),
        trailing: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => _handleChangeDatabasePath(context),
          child: const Text('Select'),
        ),
      ),
    );
  }

  /// Builds the Cloud Sync setting row (Android only).
  Widget _buildCloudSyncSetting(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    return _buildSettingRow(
      context: context,
      child: ListTile(
        title: const Text('Cloud Sync'),
        subtitle: _buildCloudSyncSubtitle(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<bool>(
              future: CloudSyncService.isCloudSyncEnabled(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _handleDisableCloudSync(context),
                      child: const Text('Disable'),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => _handleSetupCloudSync(context),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the cloud sync status display as a subtitle.
  Widget _buildCloudSyncSubtitle(BuildContext context) {
    return FutureBuilder<String?>(
      future: CloudSyncService.getCloudDisplayName(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Text(
            'Syncing: ${snapshot.data}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        return const Text('Sync database with cloud storage (e.g., Dropbox)');
      },
    );
  }

  /// Builds the theme style setting row.
  Widget _buildThemeStyleSetting(BuildContext context) {
    return _buildSettingRow(
      context: context,
      child: _isMobile
          ? _buildThemeStyleMobile(context)
          : _buildThemeStyleDesktop(context),
    );
  }

  /// Builds the theme style setting for mobile (vertical layout).
  Widget _buildThemeStyleMobile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme Style', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Choose the app color scheme',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: ThemeNotifier.instance,
            builder: (context, child) {
              final currentStyle = ThemeNotifier.instance.themeStyleIndex;
              return SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface,
                    selectedForegroundColor: Theme.of(
                      context,
                    ).colorScheme.surface,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(Icons.nightlight_round),
                    ),
                    ButtonSegment<int>(value: 1, icon: Icon(Icons.contrast)),
                    ButtonSegment<int>(value: 2, icon: Icon(Icons.favorite)),
                    ButtonSegment<int>(
                      value: 3,
                      icon: Icon(Icons.local_fire_department),
                    ),
                    ButtonSegment<int>(value: 4, icon: Icon(Icons.eco)),
                  ],
                  showSelectedIcon: false,
                  selected: {currentStyle},
                  onSelectionChanged: (Set<int> selection) async {
                    await ThemeNotifier.instance.setThemeStyle(selection.first);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds the theme style setting for desktop (horizontal layout).
  Widget _buildThemeStyleDesktop(BuildContext context) {
    return ListTile(
      title: const Text('Theme Style'),
      subtitle: const Text('Choose the app color scheme'),
      trailing: ListenableBuilder(
        listenable: ThemeNotifier.instance,
        builder: (context, child) {
          final currentStyle = ThemeNotifier.instance.themeStyleIndex;
          return SegmentedButton<int>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Theme.of(context).colorScheme.onSurface,
              selectedForegroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
            ),
            segments: const [
              ButtonSegment<int>(
                value: 0,
                icon: Icon(Icons.nightlight_round),
                label: Text('Blue'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: Icon(Icons.contrast),
                label: Text('Grey'),
              ),
              ButtonSegment<int>(
                value: 2,
                icon: Icon(Icons.favorite),
                label: Text('Pink'),
              ),
              ButtonSegment<int>(
                value: 3,
                icon: Icon(Icons.local_fire_department),
                label: Text('Orange'),
              ),
              ButtonSegment<int>(
                value: 4,
                icon: Icon(Icons.eco),
                label: Text('Green'),
              ),
            ],
            selected: {currentStyle},
            onSelectionChanged: (Set<int> selection) async {
              await ThemeNotifier.instance.setThemeStyle(selection.first);
            },
          );
        },
      ),
    );
  }

  /// Handles setting up cloud sync.
  Future<void> _handleSetupCloudSync(BuildContext context) async {
    final result = await CloudSyncService.pickCloudFile();
    if (result == null) return; // User cancelled

    if (!mounted) return;

    // Save the cloud URI
    final saved = await CloudSyncService.saveCloudUri(
      result['uri']!,
      result['displayName']!,
    );

    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to set up cloud sync'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Reset database connection, sync from cloud, and reinitialize
    await DatabaseHelper.instance.resetConnection();
    await CloudSyncService.syncFromCloud();
    await DatabaseHelper.instance.database; // Reinitialize with synced file

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud sync enabled. Database loaded.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {}); // Refresh UI
    }
  }

  /// Handles disabling cloud sync.
  Future<void> _handleDisableCloudSync(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Cloud Sync'),
        content: const Text(
          'This will stop syncing with cloud storage. Your local data will be preserved, but changes will no longer sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await CloudSyncService.clearCloudUri();
    await DatabaseHelper.instance.resetConnection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud sync disabled'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {}); // Refresh UI
    }
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
  /// 4. Resets database connection to immediately use the new file
  /// 5. Refreshes UI to display the new path
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

    // Close existing database connection and force reconnection with new path
    await DatabaseHelper.instance.resetConnection();

    if (mounted) {
      // Notify user of success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database file updated successfully. Reloading...'),
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
