// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

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
        'kanjiapi.dev',
      ),
      const SizedBox(height: 4),
      Text(
          'https://kanjiapi.dev/',
        ),
      const SizedBox(height: 8),
      const Text(
        'Which uses the EDICT and KANJIDIC dictionary files. These files are the property of the Electronic Dictionary Research and Development Group, and are used in conformance with the Group\'s licence.',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
      const SizedBox(height: 8),
      const Text(
        'EDRDG',
      ),
      const SizedBox(height: 4),
      Text(
          'https://www.edrdg.org/edrdg/licence.html',
        ),
      const SizedBox(height: 8),
      const Text(
        'ELECTRONIC DICTIONARY RESEARCH AND DEVELOPMENT GROUP GENERAL DICTIONARY LICENCE STATEMENT',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ],
  );
}
