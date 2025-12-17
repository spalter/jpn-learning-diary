import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/data/diary_data.dart';

/// Dialog for editing a diary entry.
///
/// Displays input fields for all diary entry properties with
/// save and cancel actions.
class EditDiaryEntryDialog extends StatefulWidget {
  /// The diary entry to edit.
  final DiaryEntry entry;

  const EditDiaryEntryDialog({
    super.key,
    required this.entry,
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
    _japaneseController = TextEditingController(text: widget.entry.japanese);
    _furiganaController = TextEditingController(text: widget.entry.furigana);
    _romajiController = TextEditingController(text: widget.entry.romaji);
    _meaningController = TextEditingController(text: widget.entry.meaning);
    _notesController = TextEditingController(text: widget.entry.notes);
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
    return AlertDialog(
      title: const Text('Edit Entry'),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // TODO: Save the edited entry
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entry saved (placeholder)')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
