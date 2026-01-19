// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:convert';
import 'package:equatable/equatable.dart';

/// JMdict entry data model for storing Japanese dictionary entries.
///
/// A JMdict entry contains kanji forms, readings, and senses (meanings).
/// This is a comprehensive dictionary entry from the JMdict project.
class JMdictEntry extends Equatable {
  /// The unique JMdict entry sequence number.
  final int entSeq;

  /// Kanji/written forms of the word.
  final List<JMdictKanji> kanji;

  /// Reading (kana) forms of the word.
  final List<JMdictReading> readings;

  /// Senses/meanings of the word.
  final List<JMdictSense> senses;

  const JMdictEntry({
    required this.entSeq,
    this.kanji = const [],
    this.readings = const [],
    this.senses = const [],
  });

  /// Gets the primary written form (first kanji or first reading if no kanji).
  String get primaryForm =>
      kanji.isNotEmpty ? kanji.first.keb : readings.first.reb;

  /// Gets the primary reading.
  String get primaryReading => readings.isNotEmpty ? readings.first.reb : '';

  /// Gets all glosses from all senses as a flat list.
  List<String> get allGlosses =>
      senses.expand((s) => s.glosses.map((g) => g.gloss)).toList();

  /// Checks if this is a common word (has priority markers).
  bool get isCommon =>
      kanji.any((k) => k.priorities.isNotEmpty) ||
      readings.any((r) => r.priorities.isNotEmpty);

  @override
  List<Object?> get props => [entSeq, kanji, readings, senses];
}

/// Kanji element from JMdict (k_ele).
class JMdictKanji extends Equatable {
  /// The kanji/written form text.
  final String keb;

  /// Information about the kanji form (e.g., irregular kanji).
  final List<String> info;

  /// Priority markers indicating frequency/importance.
  final List<String> priorities;

  const JMdictKanji({
    required this.keb,
    this.info = const [],
    this.priorities = const [],
  });

  /// Creates from database row.
  factory JMdictKanji.fromDb(Map<String, dynamic> row) {
    return JMdictKanji(
      keb: row['keb'] as String,
      info: _parseJsonList(row['ke_inf']),
      priorities: _parseJsonList(row['ke_pri']),
    );
  }

  @override
  List<Object?> get props => [keb, info, priorities];
}

/// Reading element from JMdict (r_ele).
class JMdictReading extends Equatable {
  /// The reading text (kana).
  final String reb;

  /// Whether this is not a true reading of the kanji (e.g., ateji).
  final bool noKanji;

  /// Restrictions - which kanji forms this reading applies to.
  final List<String> restrictions;

  /// Information about the reading.
  final List<String> info;

  /// Priority markers indicating frequency/importance.
  final List<String> priorities;

  const JMdictReading({
    required this.reb,
    this.noKanji = false,
    this.restrictions = const [],
    this.info = const [],
    this.priorities = const [],
  });

  /// Creates from database row.
  factory JMdictReading.fromDb(Map<String, dynamic> row) {
    return JMdictReading(
      reb: row['reb'] as String,
      noKanji: (row['re_nokanji'] as int?) == 1,
      restrictions: _parseJsonList(row['re_restr']),
      info: _parseJsonList(row['re_inf']),
      priorities: _parseJsonList(row['re_pri']),
    );
  }

  @override
  List<Object?> get props => [reb, noKanji, restrictions, info, priorities];
}

/// Sense element from JMdict (sense).
class JMdictSense extends Equatable {
  /// Sense number within the entry.
  final int senseNum;

  /// Kanji restrictions for this sense.
  final List<String> stagk;

  /// Reading restrictions for this sense.
  final List<String> stagr;

  /// Part-of-speech tags.
  final List<String> partsOfSpeech;

  /// Field of application codes.
  final List<String> fields;

  /// Miscellaneous information codes.
  final List<String> misc;

  /// Dialect codes.
  final List<String> dialects;

  /// Sense information notes.
  final List<String> info;

  /// Glosses (translations/definitions).
  final List<JMdictGloss> glosses;

  /// Loan word sources.
  final List<JMdictLSource> lsources;

  /// Cross-references.
  final List<String> xrefs;

  /// Antonyms.
  final List<String> antonyms;

  const JMdictSense({
    required this.senseNum,
    this.stagk = const [],
    this.stagr = const [],
    this.partsOfSpeech = const [],
    this.fields = const [],
    this.misc = const [],
    this.dialects = const [],
    this.info = const [],
    this.glosses = const [],
    this.lsources = const [],
    this.xrefs = const [],
    this.antonyms = const [],
  });

  /// Creates from database row (without glosses, lsources, xrefs, antonyms).
  factory JMdictSense.fromDb(Map<String, dynamic> row) {
    return JMdictSense(
      senseNum: row['sense_num'] as int,
      stagk: _parseJsonList(row['stagk']),
      stagr: _parseJsonList(row['stagr']),
      partsOfSpeech: _parseJsonList(row['pos']),
      fields: _parseJsonList(row['field']),
      misc: _parseJsonList(row['misc']),
      dialects: _parseJsonList(row['dial']),
      info: _parseJsonList(row['s_inf']),
    );
  }

  /// Creates a copy with additional data.
  JMdictSense copyWith({
    List<JMdictGloss>? glosses,
    List<JMdictLSource>? lsources,
    List<String>? xrefs,
    List<String>? antonyms,
  }) {
    return JMdictSense(
      senseNum: senseNum,
      stagk: stagk,
      stagr: stagr,
      partsOfSpeech: partsOfSpeech,
      fields: fields,
      misc: misc,
      dialects: dialects,
      info: info,
      glosses: glosses ?? this.glosses,
      lsources: lsources ?? this.lsources,
      xrefs: xrefs ?? this.xrefs,
      antonyms: antonyms ?? this.antonyms,
    );
  }

  @override
  List<Object?> get props => [
    senseNum,
    stagk,
    stagr,
    partsOfSpeech,
    fields,
    misc,
    dialects,
    info,
    glosses,
    lsources,
    xrefs,
    antonyms,
  ];
}

/// Gloss (translation) from JMdict.
class JMdictGloss extends Equatable {
  /// The translation/definition text.
  final String gloss;

  /// Language code (default: "eng").
  final String lang;

  /// Gloss type (e.g., "expl" for explanatory).
  final String? gType;

  const JMdictGloss({
    required this.gloss,
    this.lang = 'eng',
    this.gType,
  });

  /// Creates from database row.
  factory JMdictGloss.fromDb(Map<String, dynamic> row) {
    return JMdictGloss(
      gloss: row['gloss'] as String,
      lang: row['lang'] as String? ?? 'eng',
      gType: row['g_type'] as String?,
    );
  }

  @override
  List<Object?> get props => [gloss, lang, gType];
}

/// Loan word source from JMdict.
class JMdictLSource extends Equatable {
  /// The source word/phrase.
  final String? source;

  /// Source language code.
  final String lang;

  /// Type: "full" or "part".
  final String? lsType;

  /// Whether this is a wasei (Japanese-made) word.
  final bool wasei;

  const JMdictLSource({
    this.source,
    this.lang = 'eng',
    this.lsType,
    this.wasei = false,
  });

  /// Creates from database row.
  factory JMdictLSource.fromDb(Map<String, dynamic> row) {
    return JMdictLSource(
      source: row['lsource'] as String?,
      lang: row['lang'] as String? ?? 'eng',
      lsType: row['ls_type'] as String?,
      wasei: (row['ls_wasei'] as int?) == 1,
    );
  }

  @override
  List<Object?> get props => [source, lang, lsType, wasei];
}

/// Parses a JSON list from a dynamic value.
List<String> _parseJsonList(dynamic value) {
  if (value == null) return [];
  if (value is String) {
    try {
      final decoded = json.decode(value);
      if (decoded is List) {
        return decoded.cast<String>();
      }
    } catch (_) {
      return [];
    }
  }
  if (value is List) {
    return value.cast<String>();
  }
  return [];
}
