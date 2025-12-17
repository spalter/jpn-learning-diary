import 'package:flutter/material.dart';

/// Shows the application's about dialog with license information.
void showAppAboutDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Japanese Learning Diary',
    applicationVersion: '1.0.0',
    applicationIcon: Icon(
      Icons.book,
      size: 48,
      color: Theme.of(context).colorScheme.primary,
    ),
    children: [
      const SizedBox(height: 16),
      const Text(
        'This application uses kanji data from:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'kanji-data by David Gouveia',
      ),
      const SizedBox(height: 4),
      Text(
          'https://github.com/davidluzgouveia/kanji-data',
        ),
      const SizedBox(height: 8),
      const Text(
        'Licensed under the MIT License',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ],
  );
}
