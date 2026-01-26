// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/foundation.dart';

/// Registers custom licenses for third-party data sources.
/// Call this once during app initialization.
void registerCustomLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['kanjiapi.dev'],
      '''This application uses kanji data from kanjiapi.dev (https://kanjiapi.dev/).

kanjiapi.dev uses the EDICT and KANJIDIC dictionary files. These files are the property of the Electronic Dictionary Research and Development Group, and are used in conformance with the Group's licence.''',
    );

    yield const LicenseEntryWithLineBreaks(
      ['EDRDG (EDICT/KANJIDIC)'],
      '''ELECTRONIC DICTIONARY RESEARCH AND DEVELOPMENT GROUP
GENERAL DICTIONARY LICENCE STATEMENT

The dictionary files are made available under a Creative Commons Attribution-ShareAlike Licence (V4.0).

In summary (from https://www.edrdg.org/edrdg/licence.html):

In general, the licence statement allows free use of the dictionary files. The conditions are:

- Attribution: You must give appropriate credit, provide a link to the licence, and indicate if changes were made.

- ShareAlike: If you remix, transform, or build upon the material, you must distribute your contributions under the same licence as the original.''',
    );
  });
}
