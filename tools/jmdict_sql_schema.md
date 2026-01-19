# JMdict SQLite Schema

This document describes the database schema created by `jmdict_to_sqlite.dart` when importing JMdict XML data.

## Overview

The JMdict (Japanese-Multilingual Dictionary) data is stored in a normalized relational schema with 8 tables. All tables use the `jmdict_` prefix to distinguish them from other data in the database.

## Import

```ps1
dart run .\tools\jmdict_to_sqlite.dart .\tools\JMdict_e .\lib\assets\jpn.db
```

## Tables

### jmdict_entries

Main entry table containing the unique entry sequence number.

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `ent_seq` | INTEGER | Unique JMdict entry sequence number |

**Indexes:** `idx_jmdict_entries_ent_seq` on `ent_seq`

---

### jmdict_kanji

Kanji elements (k_ele) - the written forms using kanji characters.

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `entry_id` | INTEGER | Foreign key to `jmdict_entries.id` |
| `keb` | TEXT | Kanji element text (the written form) |
| `ke_inf` | TEXT | JSON array of kanji info codes (e.g., irregular kanji usage) |
| `ke_pri` | TEXT | JSON array of priority markers (e.g., "news1", "ichi1", "spec1") |

**Indexes:** `idx_jmdict_kanji_entry_id`, `idx_jmdict_kanji_keb`

---

### jmdict_readings

Reading elements (r_ele) - the pronunciation in kana.

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `entry_id` | INTEGER | Foreign key to `jmdict_entries.id` |
| `reb` | TEXT | Reading element text (kana pronunciation) |
| `re_nokanji` | INTEGER | 1 if reading is not a true reading of the kanji (e.g., ateji) |
| `re_restr` | TEXT | JSON array of kanji restrictions (which kanji this reading applies to) |
| `re_inf` | TEXT | JSON array of reading info codes |
| `re_pri` | TEXT | JSON array of priority markers |

**Indexes:** `idx_jmdict_readings_entry_id`, `idx_jmdict_readings_reb`

---

### jmdict_senses

Sense elements - the meanings/translations of the entry.

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `entry_id` | INTEGER | Foreign key to `jmdict_entries.id` |
| `sense_num` | INTEGER | Sense number within the entry (1-based) |
| `stagk` | TEXT | JSON array of kanji restrictions for this sense |
| `stagr` | TEXT | JSON array of reading restrictions for this sense |
| `pos` | TEXT | JSON array of part-of-speech tags (e.g., "noun", "verb") |
| `field` | TEXT | JSON array of field of application codes (e.g., "comp", "med") |
| `misc` | TEXT | JSON array of miscellaneous info (e.g., "col", "hon", "uk") |
| `dial` | TEXT | JSON array of dialect codes (e.g., "ksb" for Kansai-ben) |
| `s_inf` | TEXT | JSON array of sense information notes |

**Indexes:** `idx_jmdict_senses_entry_id`

---

### jmdict_glosses

Gloss elements - the actual translations/definitions.

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `sense_id` | INTEGER | Foreign key to `jmdict_senses.id` |
| `gloss` | TEXT | The translation/definition text |
| `lang` | TEXT | Language code (default: "eng" for English) |
| `g_type` | TEXT | Gloss type (e.g., "expl" for explanatory gloss) |

**Indexes:** `idx_jmdict_glosses_sense_id`

---

### jmdict_lsources

Loan source elements - information about the origin of loanwords (gairaigo).

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `sense_id` | INTEGER | Foreign key to `jmdict_senses.id` |
| `lsource` | TEXT | Source word/phrase in the original language |
| `lang` | TEXT | ISO 639-2 language code (default: "eng") |
| `ls_type` | TEXT | "full" or "part" indicating if source fully/partially describes the word |
| `ls_wasei` | INTEGER | 1 if word is wasei (Japanese-made foreign word, e.g., wasei-eigo) |

**Indexes:** `idx_jmdict_lsources_sense_id`

---

### jmdict_xrefs

Cross-reference elements - references to related entries.

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `sense_id` | INTEGER | Foreign key to `jmdict_senses.id` |
| `xref` | TEXT | Cross-reference text (typically a keb or reb from another entry) |

**Indexes:** `idx_jmdict_xrefs_sense_id`

---

### jmdict_ants

Antonym elements - references to entries with opposite meanings.

| Column | Type | Description |
| -------- | ------ | ------------- |
| `id` | INTEGER | Primary key (auto-increment) |
| `sense_id` | INTEGER | Foreign key to `jmdict_senses.id` |
| `ant` | TEXT | Antonym text (typically a keb or reb from another entry) |

**Indexes:** `idx_jmdict_ants_sense_id`

---

## Entity Relationship Diagram

```text
jmdict_entries (1) ─┬── (N) jmdict_kanji
                    ├── (N) jmdict_readings
                    └── (N) jmdict_senses (1) ─┬── (N) jmdict_glosses
                                               ├── (N) jmdict_lsources
                                               ├── (N) jmdict_xrefs
                                               └── (N) jmdict_ants
```

## Example Queries

### Find entries by kanji

```sql
SELECT e.ent_seq, k.keb, r.reb, g.gloss
FROM jmdict_entries e
JOIN jmdict_kanji k ON k.entry_id = e.id
JOIN jmdict_readings r ON r.entry_id = e.id
JOIN jmdict_senses s ON s.entry_id = e.id
JOIN jmdict_glosses g ON g.sense_id = s.id
WHERE k.keb = '食べる';
```

### Find entries by reading

```sql
SELECT e.ent_seq, k.keb, r.reb, g.gloss
FROM jmdict_entries e
LEFT JOIN jmdict_kanji k ON k.entry_id = e.id
JOIN jmdict_readings r ON r.entry_id = e.id
JOIN jmdict_senses s ON s.entry_id = e.id
JOIN jmdict_glosses g ON g.sense_id = s.id
WHERE r.reb = 'たべる';
```

### Find common words (with priority markers)

```sql
SELECT DISTINCT k.keb, r.reb
FROM jmdict_kanji k
JOIN jmdict_entries e ON k.entry_id = e.id
JOIN jmdict_readings r ON r.entry_id = e.id
WHERE k.ke_pri LIKE '%"ichi1"%' OR k.ke_pri LIKE '%"news1"%';
```

### Search glosses (English meanings)

```sql
SELECT e.ent_seq, k.keb, r.reb, g.gloss
FROM jmdict_glosses g
JOIN jmdict_senses s ON g.sense_id = s.id
JOIN jmdict_entries e ON s.entry_id = e.id
LEFT JOIN jmdict_kanji k ON k.entry_id = e.id
JOIN jmdict_readings r ON r.entry_id = e.id
WHERE g.gloss LIKE '%eat%'
GROUP BY e.ent_seq;
```

## Priority Markers Reference

Priority markers indicate word frequency/importance:

| Marker | Description |
| -------- | ------------- |
| `news1` | Top 12,000 words from Mainichi Shimbun wordfreq |
| `news2` | Next 12,000 words from Mainichi Shimbun wordfreq |
| `ichi1` | Appears in "Ichimango goi bunruishuu" (common) |
| `ichi2` | Demoted from ichi1 (less common) |
| `spec1` | Detected as common but not in other lists |
| `spec2` | Secondary common marker |
| `gai1` | Common loanword |
| `gai2` | Less common loanword |
| `nfxx` | Frequency rank (01-48, where 01 = top 500 words) |

## Part-of-Speech Tags (Common)

| Tag | Description |
| ----- | ------------- |
| `n` | Noun |
| `v1` | Ichidan verb |
| `v5*` | Godan verb (various endings) |
| `adj-i` | I-adjective (keiyoushi) |
| `adj-na` | Na-adjective (keiyoudoushi) |
| `adv` | Adverb |
| `exp` | Expression |
| `int` | Interjection |
| `prt` | Particle |
| `conj` | Conjunction |

See the JMdict DTD file (`jmdict_dtd_v107.xml`) for the complete list of entity codes.
