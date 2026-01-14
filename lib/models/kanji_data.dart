import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Data model representing a single kanji character and its attributes.
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

  /// Creates a KanjiData instance from the jpn.db database schema.
  ///
  /// The jpn.db has columns: _key, kanji, stroke_count, grade, jlpt,
  /// meanings (JSON), on_readings (JSON), kun_readings (JSON), etc.
  factory KanjiData.fromJpnDb(Map<String, dynamic> map) {
    // Parse JSON arrays for meanings and readings
    String parseJsonArray(dynamic value) {
      if (value == null) return '';
      if (value is String) {
        try {
          final list = json.decode(value) as List;
          return list.join(', ');
        } catch (_) {
          return value;
        }
      }
      if (value is List) {
        return value.join(', ');
      }
      return value.toString();
    }

    return KanjiData(
      kanji: (map['_key'] as String?) ?? (map['kanji'] as String?) ?? '',
      strokes: (map['stroke_count'] as int?) ?? 0,
      grade: map['grade'] as int?,
      freq: map['freq_mainichi_shinbun'] as int?,
      jlptOld: null,
      jlptNew: map['jlpt'] as int?,
      meanings: parseJsonArray(map['meanings']),
      readingsOn: parseJsonArray(map['on_readings']),
      readingsKun: parseJsonArray(map['kun_readings']),
      wkLevel: null,
      wkMeanings: map['heisig_en'] as String?,
      wkReadingsOn: null,
      wkReadingsKun: parseJsonArray(map['name_readings']),
      wkRadicals: null,
    );
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
