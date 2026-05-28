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
import 'package:jpn_learning_diary/models/diary_note.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';
import 'package:jpn_learning_diary/repositories/diary_notes_repository.dart';

/// Result of editing a diary item dialog.
///
/// Contains either the updated/created entry/note or indicates deletion.
class EditDiaryEntryResult {
  /// The updated or newly created entry, null if deleted.
  final DiaryEntry? updatedEntry;

  /// The updated or newly created note, null if deleted.
  final DiaryNote? updatedNote;

  /// Whether the entry/note was deleted.
  final bool wasDeleted;

  const EditDiaryEntryResult.updatedEntry(DiaryEntry entry)
    : updatedEntry = entry,
      updatedNote = null,
      wasDeleted = false;

  const EditDiaryEntryResult.updatedNote(DiaryNote note)
    : updatedEntry = null,
      updatedNote = note,
      wasDeleted = false;

  const EditDiaryEntryResult.deleted()
    : updatedEntry = null,
      updatedNote = null,
      wasDeleted = true;
}

/// Dialog for creating or editing a diary item (entry or note).
class EditDiaryEntryDialog extends StatefulWidget {
  final DiaryEntry? entry;
  final DiaryNote? note;

  const EditDiaryEntryDialog({super.key, this.entry, this.note});

  @override
  State<EditDiaryEntryDialog> createState() => _EditDiaryEntryDialogState();
}

/// Internal state for [EditDiaryEntryDialog] managing form input.
///
/// Maintains text editing controllers for each field and handles the save,
/// cancel, and delete actions with appropriate database operations.
class _EditDiaryEntryDialogState extends State<EditDiaryEntryDialog> {
  bool _isNoteMode = false;

  late final TextEditingController _japaneseController;
  late final TextEditingController _romajiController;
  late final TextEditingController _meaningController;
  late final TextEditingController _notesController;

  late final TextEditingController _titleController;
  late final TextEditingController _contentJapaneseController;

  @override
  void initState() {
    super.initState();
    _isNoteMode = widget.note != null;

    _japaneseController = TextEditingController(
      text: widget.entry?.japanese ?? '',
    );
    _romajiController = TextEditingController(text: widget.entry?.romaji ?? '');
    _meaningController = TextEditingController(
      text: widget.entry?.meaning ?? '',
    );
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');

    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentJapaneseController = TextEditingController(
      text: widget.note?.contentJapanese ?? '',
    );
  }

  @override
  void dispose() {
    _japaneseController.dispose();
    _romajiController.dispose();
    _meaningController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    _contentJapaneseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null || widget.note != null;
    final isEditingNew = !isEditing;

    final saveShortcut = Platform.isMacOS
        ? const SingleActivator(LogicalKeyboardKey.keyS, meta: true)
        : const SingleActivator(LogicalKeyboardKey.keyS, control: true);

    return CallbackShortcuts(
      bindings: {saveShortcut: _handleSave},
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 4,
          title: isEditingNew
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SegmentedButton<bool>(
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
                        ButtonSegment<bool>(value: false, label: Text('Vocab')),
                        ButtonSegment<bool>(value: true, label: Text('Note')),
                      ],
                      selected: {_isNoteMode},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isNoteMode = newSelection.first;
                        });
                      },
                    ),
                  ],
                )
              : null,
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: _isNoteMode
                  ? _buildNoteForm(context)
                  : _buildVocabForm(context),
            ),
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () => _handleDelete(context),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(onPressed: _handleSave, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _japaneseController,
          decoration: InputDecoration(
            labelText: 'Japanese',
            helperText: 'Use [漢字](かんじ) for inline furigana',
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _romajiController,
          decoration: const InputDecoration(
            labelText: 'Romaji',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _meaningController,
          decoration: const InputDecoration(
            labelText: 'Meaning',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildNoteForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            helperText: 'Use [漢字](かんじ) for inline furigana',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contentJapaneseController,
          decoration: InputDecoration(
            labelText: 'Japanese Content',
            helperText: 'Use [漢字](かんじ) for inline furigana',
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 16),
          minLines: 8,
          maxLines: null,
        ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (_isNoteMode) {
        final repo = DiaryNotesRepository();
        await repo.deleteNote(widget.note!.id!);
        if (context.mounted) {
          Navigator.of(context).pop(const EditDiaryEntryResult.deleted());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Note deleted')));
        }
      } else {
        final repo = DiaryRepository();
        await repo.deleteEntry(widget.entry!.id!);
        if (context.mounted) {
          Navigator.of(context).pop(const EditDiaryEntryResult.deleted());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
        }
      }
    }
  }

  Future<void> _handleSave() async {
    final isEditingEntry = widget.entry != null;
    final isEditingNote = widget.note != null;

    if (_isNoteMode) {
      final repo = DiaryNotesRepository();
      DiaryNote savedNote;

      if (isEditingNote) {
        savedNote = widget.note!.copyWith(
          title: _titleController.text,
          contentJapanese: _contentJapaneseController.text,
          contentEnglish: '', // explicitly clear out if it had any
        );
        await repo.updateNote(savedNote);
      } else {
        final newNote = DiaryNote(
          title: _titleController.text,
          contentJapanese: _contentJapaneseController.text,
          dateAdded: DateTime.now(),
        );
        savedNote = await repo.createNote(newNote);
      }

      if (mounted) {
        Navigator.of(context).pop(EditDiaryEntryResult.updatedNote(savedNote));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditingNote ? 'Note saved' : 'Note added')),
        );
      }
    } else {
      final repo = DiaryRepository();
      DiaryEntry savedEntry;

      final notesText = _notesController.text.trim();

      if (isEditingEntry) {
        savedEntry = widget.entry!.copyWith(
          japanese: _japaneseController.text,
          romaji: _romajiController.text,
          meaning: _meaningController.text,
          notes: notesText.isEmpty ? null : notesText,
          clearNotes: notesText.isEmpty,
        );
        await repo.updateEntry(savedEntry);
      } else {
        final newEntry = DiaryEntry(
          japanese: _japaneseController.text,
          romaji: _romajiController.text,
          meaning: _meaningController.text,
          notes: notesText.isEmpty ? null : notesText,
          dateAdded: DateTime.now(),
        );
        savedEntry = await repo.createEntry(newEntry);
      }

      if (mounted) {
        Navigator.of(
          context,
        ).pop(EditDiaryEntryResult.updatedEntry(savedEntry));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditingEntry ? 'Entry saved' : 'Entry added'),
          ),
        );
      }
    }
  }
}
