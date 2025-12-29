import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/models/diary_entry.dart';
import 'package:jpn_learning_diary/repositories/diary_repository.dart';

/// Dialog for creating or editing a diary entry.
///
/// Displays input fields for all diary entry properties with
/// save and cancel actions.
class EditDiaryEntryDialog extends StatefulWidget {
  /// The diary entry to edit. If null, creates a new entry.
  final DiaryEntry? entry;

  const EditDiaryEntryDialog({
    super.key,
    this.entry,
  });

  @override
  State<EditDiaryEntryDialog> createState() => _EditDiaryEntryDialogState();
}

class _EditDiaryEntryDialogState extends State<EditDiaryEntryDialog> {
  late final TextEditingController _japaneseController;
  late final TextEditingController _furiganaController;
  late final TextEditingController _romajiController;
  late final TextEditingController _meaningController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _japaneseController = TextEditingController(text: widget.entry?.japanese ?? '');
    _furiganaController = TextEditingController(text: widget.entry?.furigana ?? '');
    _romajiController = TextEditingController(text: widget.entry?.romaji ?? '');
    _meaningController = TextEditingController(text: widget.entry?.meaning ?? '');
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  void dispose() {
    _japaneseController.dispose();
    _furiganaController.dispose();
    _romajiController.dispose();
    _meaningController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Entry' : 'Add Entry'),
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
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withAlpha(100),
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _furiganaController,
                decoration: InputDecoration(
                  labelText: 'Furigana',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withAlpha(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _romajiController,
                decoration: InputDecoration(
                  labelText: 'Romaji',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withAlpha(100),
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
                      color: Theme.of(context).colorScheme.primary.withAlpha(100),
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
                      color: Theme.of(context).colorScheme.primary.withAlpha(100),
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
                  content: const Text('Are you sure you want to delete this entry? This cannot be undone.'),
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
              
              // If confirmed, delete from database and close dialog.
              if (confirmed == true && context.mounted) {
                final diaryRepository = DiaryRepository();
                await diaryRepository.deleteEntry(widget.entry!.id!);
                if (context.mounted) {
                  Navigator.of(context).pop(true);
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        // Save button - creates new entry or updates existing one.
        FilledButton(
          onPressed: () async {
            final isEditing = widget.entry != null;
            final diaryRepository = DiaryRepository();
            
            if (isEditing) {
              // Update existing entry in database with new values.
              final updatedEntry = widget.entry!.copyWith(
                japanese: _japaneseController.text,
                furigana: _furiganaController.text.isEmpty ? null : _furiganaController.text,
                romaji: _romajiController.text,
                meaning: _meaningController.text,
                notes: _notesController.text.isEmpty ? null : _notesController.text,
              );
              await diaryRepository.updateEntry(updatedEntry);
            } else {
              // Create new entry with current timestamp.
              final newEntry = DiaryEntry(
                japanese: _japaneseController.text,
                furigana: _furiganaController.text.isEmpty ? null : _furiganaController.text,
                romaji: _romajiController.text,
                meaning: _meaningController.text,
                notes: _notesController.text.isEmpty ? null : _notesController.text,
                dateAdded: DateTime.now(),
              );
              await diaryRepository.createEntry(newEntry);
            }
            
            if (context.mounted) {
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEditing ? 'Entry saved' : 'Entry added')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
