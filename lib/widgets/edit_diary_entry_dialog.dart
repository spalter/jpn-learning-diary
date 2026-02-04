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
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';

/// Result of editing a diary entry dialog.
///
/// Contains either the updated/created entry or indicates deletion.
class EditDiaryEntryResult {
  /// The updated or newly created entry, null if deleted.
  final DiaryEntry? updatedEntry;

  /// Whether the entry was deleted.
  final bool wasDeleted;

  const EditDiaryEntryResult.updated(DiaryEntry entry)
    : updatedEntry = entry,
      wasDeleted = false;

  const EditDiaryEntryResult.deleted() : updatedEntry = null, wasDeleted = true;
}

/// Dialog for creating or editing a diary entry.
///
/// This modal dialog presents input fields for all diary entry properties
/// including Japanese text (with inline ruby patterns for furigana), romaji,
/// meaning, and notes. When editing an existing entry, a delete button is
/// also available with confirmation.
///
/// * [entry]: The existing diary entry to edit, or null to create a new one.
class EditDiaryEntryDialog extends StatefulWidget {
  /// The diary entry to edit, or null to create a new entry.
  ///
  /// When provided, the dialog pre-fills all fields with the entry's current
  /// values and shows a delete option.
  final DiaryEntry? entry;

  const EditDiaryEntryDialog({super.key, this.entry});

  @override
  State<EditDiaryEntryDialog> createState() => _EditDiaryEntryDialogState();
}

/// Internal state for [EditDiaryEntryDialog] managing form input.
///
/// Maintains text editing controllers for each field and handles the save,
/// cancel, and delete actions with appropriate database operations.
class _EditDiaryEntryDialogState extends State<EditDiaryEntryDialog> {
  /// Controller for the Japanese text input field.
  late final TextEditingController _japaneseController;

  /// Controller for the romaji transliteration input field.
  late final TextEditingController _romajiController;

  /// Controller for the meaning/translation input field.
  late final TextEditingController _meaningController;

  /// Controller for the optional notes input field.
  late final TextEditingController _notesController;

  /// Initializes controllers with existing entry values or empty strings.
  @override
  void initState() {
    super.initState();
    _japaneseController = TextEditingController(
      text: widget.entry?.japanese ?? '',
    );
    _romajiController = TextEditingController(text: widget.entry?.romaji ?? '');
    _meaningController = TextEditingController(
      text: widget.entry?.meaning ?? '',
    );
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  /// Disposes all text editing controllers to prevent memory leaks.
  @override
  void dispose() {
    _japaneseController.dispose();
    _romajiController.dispose();
    _meaningController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Builds the dialog with form fields and action buttons.
  ///
  /// The title and available actions adapt based on whether an existing entry
  /// is being edited or a new one is being created.
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;

    // Define the save shortcut: Cmd+S on macOS, Ctrl+S on Windows/Linux
    final saveShortcut = Platform.isMacOS
        ? const SingleActivator(LogicalKeyboardKey.keyS, meta: true)
        : const SingleActivator(LogicalKeyboardKey.keyS, control: true);

    return CallbackShortcuts(
      bindings: {saveShortcut: _handleSave},
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          title: Text(
            isEditing ? 'Edit a Diary Entry' : 'Add a new Diary Entry',
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _japaneseController,
                    decoration: InputDecoration(
                      labelText: 'Japanese',
                      helperText: 'Use [漢字](かんじ) for inline furigana',
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(100),
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _romajiController,
                    decoration: InputDecoration(
                      labelText: 'Romaji',
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(100),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _meaningController,
                    decoration: InputDecoration(
                      labelText: 'Meaning',
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(100),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(100),
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Delete button - only shown when editing an existing entry.
            if (isEditing)
              TextButton(
                onPressed: () async {
                  // Show confirmation dialog to prevent accidental deletion.
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text(
                        'Are you sure you want to delete this entry? This cannot be undone.',
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
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  // If confirmed, delete from database and close dialog.
                  if (confirmed == true && context.mounted) {
                    final diaryRepository = DiaryRepository();
                    await diaryRepository.deleteEntry(widget.entry!.id!);
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pop(const EditDiaryEntryResult.deleted());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Entry deleted')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            // Save button - creates new entry or updates existing one.
            FilledButton(onPressed: _handleSave, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  /// Saves the diary entry (creates new or updates existing).
  Future<void> _handleSave() async {
    final isEditing = widget.entry != null;
    final diaryRepository = DiaryRepository();

    DiaryEntry savedEntry;

    if (isEditing) {
      // Update existing entry in database with new values.
      final notesText = _notesController.text.trim();

      savedEntry = widget.entry!.copyWith(
        japanese: _japaneseController.text,
        romaji: _romajiController.text,
        meaning: _meaningController.text,
        notes: notesText.isEmpty ? null : notesText,
        clearNotes: notesText.isEmpty,
      );
      await diaryRepository.updateEntry(savedEntry);
    } else {
      // Create new entry with current timestamp.
      final newEntry = DiaryEntry(
        japanese: _japaneseController.text,
        romaji: _romajiController.text,
        meaning: _meaningController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        dateAdded: DateTime.now(),
      );
      savedEntry = await diaryRepository.createEntry(newEntry);
    }

    if (mounted) {
      Navigator.of(context).pop(EditDiaryEntryResult.updated(savedEntry));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Entry saved' : 'Entry added')),
      );
    }
  }
}
