// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:equatable/equatable.dart';

/// Model for a single Anki flashcard extracted from an APKG file.
///
/// Represents one card with a front (question) side and a back (answer) side.
/// Additional fields from the note are preserved in [extraFields] for display
/// purposes. Immutable and value-comparable for state management.
class AnkiCard extends Equatable {
  /// Unique note identifier from the Anki database.
  final int noteId;

  /// The front side of the flashcard (typically the question/prompt).
  final String front;

  /// The back side of the flashcard (typically the answer).
  final String back;

  /// Any additional fields from the Anki note beyond front and back.
  final List<String> extraFields;

  /// Optional tags associated with this note.
  final List<String> tags;

  /// Sound file references found on the front side (e.g. "pronunciation.mp3").
  final List<String> frontSounds;

  /// Sound file references found on the back side.
  final List<String> backSounds;

  /// Sound file references found in extra fields.
  final List<String> extraSounds;

  /// Image file references found on the front side.
  final List<String> frontImages;

  /// Image file references found on the back side.
  final List<String> backImages;

  /// Image file references found in extra fields.
  final List<String> extraImages;

  const AnkiCard({
    required this.noteId,
    required this.front,
    required this.back,
    this.extraFields = const [],
    this.tags = const [],
    this.frontSounds = const [],
    this.backSounds = const [],
    this.extraSounds = const [],
    this.frontImages = const [],
    this.backImages = const [],
    this.extraImages = const [],
  });

  /// Whether this card has any sound files on the front side.
  bool get hasFrontAudio => frontSounds.isNotEmpty;

  /// Whether this card has any sound files on the back side.
  bool get hasBackAudio => backSounds.isNotEmpty;

  /// Whether this card has any audio at all.
  bool get hasAudio => frontSounds.isNotEmpty || backSounds.isNotEmpty || extraSounds.isNotEmpty;

  /// Whether this card has any images at all.
  bool get hasImages => frontImages.isNotEmpty || backImages.isNotEmpty || extraImages.isNotEmpty;

  /// Creates an [AnkiCard] from an Anki note's fields string.
  ///
  /// Anki stores note fields separated by the unit separator character (0x1F).
  /// [frontIndex] and [backIndex] specify which field indices to use for
  /// the front and back of the card. Remaining fields become [extraFields].
  factory AnkiCard.fromAnkiNote({
    required int noteId,
    required String fieldsString,
    String tagsString = '',
    int frontIndex = 0,
    int backIndex = 1,
    List<String> fieldNames = const [],
  }) {
    final fields = fieldsString.split('\x1F');

    // Extract sound and image references before stripping
    final soundRefs = fields.map(_extractSoundRefs).toList();
    final imageRefs = fields.map(_extractImageRefs).toList();

    // Strip HTML tags and media references for clean text display
    final cleanFields = fields.map(_stripHtmlAndMedia).toList();

    // Determine front and back indices, clamping to available fields
    final fi = frontIndex < cleanFields.length ? frontIndex : 0;
    final bi = backIndex < cleanFields.length
        ? backIndex
        : (cleanFields.length > 1 ? 1 : 0);

    // Collect extra fields (everything that isn't front or back),
    // filtering out empty values, pure numbers, and metadata fields.
    final extras = <String>[];
    for (int i = 0; i < cleanFields.length; i++) {
      if (i == fi || i == bi) continue;
      final value = cleanFields[i];
      if (value.isEmpty) continue;
      // Skip pure numeric values (sort indices, frequency counts, etc.)
      if (RegExp(r'^\d+$').hasMatch(value)) continue;
      // Skip fields whose names indicate metadata/audio/index
      if (i < fieldNames.length && _isMetadataField(fieldNames[i])) continue;
      extras.add(value);
    }

    // Collect sounds and images from extra fields
    final allExtraSounds = <String>[];
    final allExtraImages = <String>[];
    for (int i = 0; i < soundRefs.length; i++) {
      if (i != fi && i != bi) {
        allExtraSounds.addAll(soundRefs[i]);
      }
    }
    for (int i = 0; i < imageRefs.length; i++) {
      if (i != fi && i != bi) {
        allExtraImages.addAll(imageRefs[i]);
      }
    }

    return AnkiCard(
      noteId: noteId,
      front: cleanFields.isNotEmpty ? cleanFields[fi] : '',
      back: cleanFields.length > 1 ? cleanFields[bi] : '',
      extraFields: extras,
      tags: tagsString.trim().isEmpty
          ? const []
          : tagsString.trim().split(RegExp(r'\s+')),
      frontSounds: fi < soundRefs.length ? soundRefs[fi] : const [],
      backSounds: bi < soundRefs.length ? soundRefs[bi] : const [],
      extraSounds: allExtraSounds,
      frontImages: fi < imageRefs.length ? imageRefs[fi] : const [],
      backImages: bi < imageRefs.length ? imageRefs[bi] : const [],
      extraImages: allExtraImages,
    );
  }

  /// Regex for Anki sound references: [sound:filename.mp3]
  static final _soundRefRegex = RegExp(r'\[sound:([^\]]+)\]');

  /// Regex for image references: <img src="filename.jpg">
  static final _imageRefRegex = RegExp(
    r"""<img[^>]+src\s*=\s*["']([^"']+)["']""",
    caseSensitive: false,
  );

  /// Extracts all sound file references from a field string.
  static List<String> _extractSoundRefs(String field) {
    return _soundRefRegex
        .allMatches(field)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// Extracts all image file references from a field string.
  static List<String> _extractImageRefs(String field) {
    return _imageRefRegex
        .allMatches(field)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// Strips HTML tags, sound references, and image references from a string.
  ///
  /// Also normalizes whitespace and decodes common HTML entities.
  static String _stripHtmlAndMedia(String html) {
    // Remove [sound:...] references
    var text = html.replaceAll(_soundRefRegex, '');
    // Replace <br>, <br/>, <div> tags with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>|</?div>'), '\n');
    // Remove <img> tags (image references)
    text = text.replaceAll(RegExp(r'<img[^>]*>'), '');
    // Remove remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    // Normalize whitespace
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// Pattern for field names that indicate metadata, not displayable content.
  static final _metadataFieldPattern = RegExp(
    r'(index|audio|sound|image|img|clozed?|cloze|frequency|freq|'
    r'sort|order|seq|notes?$|caution|pos$)',
    caseSensitive: false,
  );

  /// Returns true if a field name indicates metadata rather than content.
  static bool _isMetadataField(String fieldName) {
    return _metadataFieldPattern.hasMatch(fieldName);
  }

  /// Whether this card has meaningful content on both sides.
  bool get isValid => front.isNotEmpty && back.isNotEmpty;

  @override
  List<Object?> get props => [noteId, front, back, extraFields, tags, frontSounds, backSounds, extraSounds, frontImages, backImages, extraImages];

  @override
  String toString() => 'AnkiCard(noteId: $noteId, front: "$front", back: "$back")';
}
