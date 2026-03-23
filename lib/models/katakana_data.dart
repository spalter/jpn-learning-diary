// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:jpn_learning_diary/models/character_data.dart';

/// Katakana character data organized by type.
class KatakanaData {
  /// Base katakana characters (gojūon).
  static const List<CharacterData> baseCharacters = [
    // Vowels
    CharacterData(character: 'ア', romanization: 'a'),
    CharacterData(character: 'イ', romanization: 'i'),
    CharacterData(character: 'ウ', romanization: 'u'),
    CharacterData(character: 'エ', romanization: 'e'),
    CharacterData(character: 'オ', romanization: 'o'),

    // K-row
    CharacterData(character: 'カ', romanization: 'ka'),
    CharacterData(character: 'キ', romanization: 'ki'),
    CharacterData(character: 'ク', romanization: 'ku'),
    CharacterData(character: 'ケ', romanization: 'ke'),
    CharacterData(character: 'コ', romanization: 'ko'),

    // S-row
    CharacterData(character: 'サ', romanization: 'sa'),
    CharacterData(character: 'シ', romanization: 'shi'),
    CharacterData(character: 'ス', romanization: 'su'),
    CharacterData(character: 'セ', romanization: 'se'),
    CharacterData(character: 'ソ', romanization: 'so'),

    // T-row
    CharacterData(character: 'タ', romanization: 'ta'),
    CharacterData(character: 'チ', romanization: 'chi'),
    CharacterData(character: 'ツ', romanization: 'tsu'),
    CharacterData(character: 'テ', romanization: 'te'),
    CharacterData(character: 'ト', romanization: 'to'),

    // N-row
    CharacterData(character: 'ナ', romanization: 'na'),
    CharacterData(character: 'ニ', romanization: 'ni'),
    CharacterData(character: 'ヌ', romanization: 'nu'),
    CharacterData(character: 'ネ', romanization: 'ne'),
    CharacterData(character: 'ノ', romanization: 'no'),

    // H-row
    CharacterData(character: 'ハ', romanization: 'ha'),
    CharacterData(character: 'ヒ', romanization: 'hi'),
    CharacterData(character: 'フ', romanization: 'fu'),
    CharacterData(character: 'ヘ', romanization: 'he'),
    CharacterData(character: 'ホ', romanization: 'ho'),

    // M-row
    CharacterData(character: 'マ', romanization: 'ma'),
    CharacterData(character: 'ミ', romanization: 'mi'),
    CharacterData(character: 'ム', romanization: 'mu'),
    CharacterData(character: 'メ', romanization: 'me'),
    CharacterData(character: 'モ', romanization: 'mo'),

    // Y-row
    CharacterData(character: 'ヤ', romanization: 'ya'),
    CharacterData(character: 'ユ', romanization: 'yu'),
    CharacterData(character: 'ヨ', romanization: 'yo'),

    // R-row
    CharacterData(character: 'ラ', romanization: 'ra'),
    CharacterData(character: 'リ', romanization: 'ri'),
    CharacterData(character: 'ル', romanization: 'ru'),
    CharacterData(character: 'レ', romanization: 're'),
    CharacterData(character: 'ロ', romanization: 'ro'),

    // W-row
    CharacterData(character: 'ワ', romanization: 'wa'),
    CharacterData(character: 'ヲ', romanization: 'wo'),

    // N
    CharacterData(character: 'ン', romanization: 'n'),
  ];
  
  /// Base characters aligned for a 5-column grid (gojūon order).
  static List<CharacterData> get gridBaseCharacters => [
        // A, K, S, T, N, H, M rows
        ...baseCharacters.sublist(0, 35),

        // Y-row: ya, (empty), yu, (empty), yo
        baseCharacters[35], // ya
        CharacterData.empty,
        baseCharacters[36], // yu
        CharacterData.empty,
        baseCharacters[37], // yo

        // R-row
        ...baseCharacters.sublist(38, 43),

        // W-row: wa, (empty), (empty), (empty), wo
        baseCharacters[43], // wa
        CharacterData.empty,
        CharacterData.empty,
        CharacterData.empty,
        baseCharacters[44], // wo
        
        // N-row: n, (empty), (empty), (empty), (empty)
        baseCharacters[45], // n
        CharacterData.empty,
        CharacterData.empty,
        CharacterData.empty,
        CharacterData.empty,
  ];

  /// Dakuten characters (濁点).
  static const List<CharacterData> dakutenCharacters = [
    // G-row
    CharacterData(character: 'ガ', romanization: 'ga'),
    CharacterData(character: 'ギ', romanization: 'gi'),
    CharacterData(character: 'グ', romanization: 'gu'),
    CharacterData(character: 'ゲ', romanization: 'ge'),
    CharacterData(character: 'ゴ', romanization: 'go'),

    // Z-row
    CharacterData(character: 'ザ', romanization: 'za'),
    CharacterData(character: 'ジ', romanization: 'ji'),
    CharacterData(character: 'ズ', romanization: 'zu'),
    CharacterData(character: 'ゼ', romanization: 'ze'),
    CharacterData(character: 'ゾ', romanization: 'zo'),

    // D-row
    CharacterData(character: 'ダ', romanization: 'da'),
    CharacterData(character: 'ヂ', romanization: 'ji'),
    CharacterData(character: 'ヅ', romanization: 'zu'),
    CharacterData(character: 'デ', romanization: 'de'),
    CharacterData(character: 'ド', romanization: 'do'),

    // B-row
    CharacterData(character: 'バ', romanization: 'ba'),
    CharacterData(character: 'ビ', romanization: 'bi'),
    CharacterData(character: 'ブ', romanization: 'bu'),
    CharacterData(character: 'ベ', romanization: 'be'),
    CharacterData(character: 'ボ', romanization: 'bo'),
  ];

  /// Handakuten characters (半濁点).
  static const List<CharacterData> handakutenCharacters = [
    // P-row
    CharacterData(character: 'パ', romanization: 'pa'),
    CharacterData(character: 'ピ', romanization: 'pi'),
    CharacterData(character: 'プ', romanization: 'pu'),
    CharacterData(character: 'ペ', romanization: 'pe'),
    CharacterData(character: 'ポ', romanization: 'po'),
  ];

  /// Combination characters (拗音).
  static const List<CharacterData> combinations = [
    // KY-combinations
    CharacterData(character: 'キャ', romanization: 'kya'),
    CharacterData(character: 'キュ', romanization: 'kyu'),
    CharacterData(character: 'キョ', romanization: 'kyo'),

    // SH-combinations
    CharacterData(character: 'シャ', romanization: 'sha'),
    CharacterData(character: 'シュ', romanization: 'shu'),
    CharacterData(character: 'ショ', romanization: 'sho'),

    // CH-combinations
    CharacterData(character: 'チャ', romanization: 'cha'),
    CharacterData(character: 'チュ', romanization: 'chu'),
    CharacterData(character: 'チョ', romanization: 'cho'),

    // NY-combinations
    CharacterData(character: 'ニャ', romanization: 'nya'),
    CharacterData(character: 'ニュ', romanization: 'nyu'),
    CharacterData(character: 'ニョ', romanization: 'nyo'),

    // HY-combinations
    CharacterData(character: 'ヒャ', romanization: 'hya'),
    CharacterData(character: 'ヒュ', romanization: 'hyu'),
    CharacterData(character: 'ヒョ', romanization: 'hyo'),

    // MY-combinations
    CharacterData(character: 'ミャ', romanization: 'mya'),
    CharacterData(character: 'ミュ', romanization: 'myu'),
    CharacterData(character: 'ミョ', romanization: 'myo'),

    // RY-combinations
    CharacterData(character: 'リャ', romanization: 'rya'),
    CharacterData(character: 'リュ', romanization: 'ryu'),
    CharacterData(character: 'リョ', romanization: 'ryo'),
  ];
  
  /// Dakuten combination characters (濁点拗音).
  static const List<CharacterData> dakutenCombinations = [
    // GY-combinations
    CharacterData(character: 'ギャ', romanization: 'gya'),
    CharacterData(character: 'ギュ', romanization: 'gyu'),
    CharacterData(character: 'ギョ', romanization: 'gyo'),
 
    // J-combinations
    CharacterData(character: 'ジャ', romanization: 'ja'),
    CharacterData(character: 'ジュ', romanization: 'ju'),
    CharacterData(character: 'ジョ', romanization: 'jo'),
 
    // BY-combinations
    CharacterData(character: 'ビャ', romanization: 'bya'),
    CharacterData(character: 'ビュ', romanization: 'byu'),
    CharacterData(character: 'ビョ', romanization: 'byo'),
  ];
 
  /// Handakuten combination characters (半濁点拗音).
  static const List<CharacterData> handakutenCombinations = [
    // PY-combinations
    CharacterData(character: 'ピャ', romanization: 'pya'),
    CharacterData(character: 'ピュ', romanization: 'pyu'),
    CharacterData(character: 'ピョ', romanization: 'pyo'),
  ];

  /// All katakana characters combined.
  static List<CharacterData> get allCharacters => [
        ...baseCharacters,
        ...dakutenCharacters,
        ...handakutenCharacters,
        ...combinations,
        ...dakutenCombinations,
        ...handakutenCombinations,
      ];
}
