/// Model for a learned word or phrase entry in the diary.
class DiaryEntry {
  /// Unique identifier for the entry.
  final String id;
  
  /// Japanese text (kanji/kana).
  final String japanese;
  
  /// Furigana/reading guide (hiragana above kanji).
  final String? furigana;
  
  /// Romanized version (romaji).
  final String romaji;
  
  /// English translation or meaning.
  final String meaning;
  
  /// User's notes about the entry.
  final String? notes;
  
  /// When the entry was created/learned.
  final DateTime dateAdded;

  const DiaryEntry({
    required this.id,
    required this.japanese,
    this.furigana,
    required this.romaji,
    required this.meaning,
    this.notes,
    required this.dateAdded,
  });
}

/// Sample diary entries for demonstration.
class DiaryData {
  static final List<DiaryEntry> dummyEntries = [
    DiaryEntry(
      id: '1',
      japanese: 'こんにちは',
      furigana: 'こんにちは',
      romaji: 'konnichiwa',
      meaning: 'Hello, Good afternoon',
      notes: 'Common greeting used during the day',
      dateAdded: DateTime(2025, 12, 15),
    ),
    DiaryEntry(
      id: '2',
      japanese: '食べる',
      furigana: 'たべる',
      romaji: 'taberu',
      meaning: 'to eat',
      notes: 'Ichidan verb - basic daily verb',
      dateAdded: DateTime(2025, 12, 14),
    ),
    DiaryEntry(
      id: '3',
      japanese: '図書館',
      furigana: 'としょかん',
      romaji: 'toshokan',
      meaning: 'library',
      notes: 'Useful for studying, remember the kanji: 図(diagram) 書(writing) 館(building)',
      dateAdded: DateTime(2025, 12, 13),
    ),
    DiaryEntry(
      id: '4',
      japanese: 'ありがとう',
      furigana: 'ありがとう',
      romaji: 'arigatou',
      meaning: 'Thank you',
      notes: 'More polite form: ありがとうございます (arigatou gozaimasu)',
      dateAdded: DateTime(2025, 12, 12),
    ),
    DiaryEntry(
      id: '5',
      japanese: '勉強する',
      furigana: 'べんきょうする',
      romaji: 'benkyou suru',
      meaning: 'to study',
      notes: 'Suru verb - very important for student life!',
      dateAdded: DateTime(2025, 12, 11),
    ),
    DiaryEntry(
      id: '6',
      japanese: '美味しい',
      furigana: 'おいしい',
      romaji: 'oishii',
      meaning: 'delicious',
      notes: 'I-adjective, use it when eating good food',
      dateAdded: DateTime(2025, 12, 10),
    ),
    DiaryEntry(
      id: '7',
      japanese: 'お願いします',
      furigana: 'おねがいします',
      romaji: 'onegai shimasu',
      meaning: 'please',
      notes: 'Very polite way to make a request',
      dateAdded: DateTime(2025, 12, 9),
    ),
    DiaryEntry(
      id: '8',
      japanese: '明日',
      furigana: 'あした',
      romaji: 'ashita',
      meaning: 'tomorrow',
      notes: 'Can also be read as みょうにち (myounichi) in formal contexts',
      dateAdded: DateTime(2025, 12, 8),
    ),
  ];
}
