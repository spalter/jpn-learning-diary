import 'package:equatable/equatable.dart';

/// Kanji data model for storing kanji information from the kanji-data JSON.
///
/// This is a pure data model with no business logic.
/// Data source: https://github.com/davidluzgouveia/kanji-data
/// Licensed under MIT License
class KanjiData extends Equatable {
  final String kanji;
  final int strokes;
  final int? grade;
  final int? freq;
  final int? jlptOld;
  final int? jlptNew;
  final String meanings;
  final String readingsOn;
  final String readingsKun;
  final int? wkLevel;
  final String? wkMeanings;
  final String? wkReadingsOn;
  final String? wkReadingsKun;
  final String? wkRadicals;

  const KanjiData({
    required this.kanji,
    required this.strokes,
    this.grade,
    this.freq,
    this.jlptOld,
    this.jlptNew,
    required this.meanings,
    required this.readingsOn,
    required this.readingsKun,
    this.wkLevel,
    this.wkMeanings,
    this.wkReadingsOn,
    this.wkReadingsKun,
    this.wkRadicals,
  });

  /// Creates a KanjiData instance from a database map.
  factory KanjiData.fromMap(Map<String, dynamic> map) {
    return KanjiData(
      kanji: map['kanji'] as String,
      strokes: map['strokes'] as int,
      grade: map['grade'] as int?,
      freq: map['freq'] as int?,
      jlptOld: map['jlpt_old'] as int?,
      jlptNew: map['jlpt_new'] as int?,
      meanings: map['meanings'] as String,
      readingsOn: map['readings_on'] as String,
      readingsKun: map['readings_kun'] as String,
      wkLevel: map['wk_level'] as int?,
      wkMeanings: map['wk_meanings'] as String?,
      wkReadingsOn: map['wk_readings_on'] as String?,
      wkReadingsKun: map['wk_readings_kun'] as String?,
      wkRadicals: map['wk_radicals'] as String?,
    );
  }

  /// Creates a KanjiData instance from a JSON map with kanji character.
  factory KanjiData.fromJson(String kanji, Map<String, dynamic> json) {
    return KanjiData(
      kanji: kanji,
      strokes: json['strokes'] as int,
      grade: json['grade'] as int?,
      freq: json['freq'] as int?,
      jlptOld: json['jlpt_old'] as int?,
      jlptNew: json['jlpt_new'] as int?,
      meanings: (json['meanings'] as List).join(', '),
      readingsOn: (json['readings_on'] as List).join(', '),
      readingsKun: (json['readings_kun'] as List).join(', '),
      wkLevel: json['wk_level'] as int?,
      wkMeanings: json['wk_meanings'] != null
          ? (json['wk_meanings'] as List).join(', ')
          : null,
      wkReadingsOn: json['wk_readings_on'] != null
          ? (json['wk_readings_on'] as List).join(', ')
          : null,
      wkReadingsKun: json['wk_readings_kun'] != null
          ? (json['wk_readings_kun'] as List).join(', ')
          : null,
      wkRadicals: json['wk_radicals'] != null
          ? (json['wk_radicals'] as List).join(', ')
          : null,
    );
  }

  /// Converts the KanjiData instance to a database map.
  Map<String, dynamic> toMap() {
    return {
      'kanji': kanji,
      'strokes': strokes,
      'grade': grade,
      'freq': freq,
      'jlpt_old': jlptOld,
      'jlpt_new': jlptNew,
      'meanings': meanings,
      'readings_on': readingsOn,
      'readings_kun': readingsKun,
      'wk_level': wkLevel,
      'wk_meanings': wkMeanings,
      'wk_readings_on': wkReadingsOn,
      'wk_readings_kun': wkReadingsKun,
      'wk_radicals': wkRadicals,
    };
  }

  /// Helper to get the current JLPT level (prioritizes new system).
  int? get jlptLevel => jlptNew ?? jlptOld;

  /// Helper to check if kanji is beginner-friendly (N5 or N4).
  bool get isBeginnerLevel {
    final level = jlptLevel;
    return level != null && level >= 4;
  }

  @override
  List<Object?> get props => [
        kanji,
        strokes,
        grade,
        freq,
        jlptOld,
        jlptNew,
        meanings,
        readingsOn,
        readingsKun,
        wkLevel,
        wkMeanings,
        wkReadingsOn,
        wkReadingsKun,
        wkRadicals,
      ];

  @override
  bool get stringify => true;
}
