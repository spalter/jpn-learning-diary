CREATE TABLE IF NOT EXISTS "kanjis" ("_key" TEXT, "freq_mainichi_shinbun" INTEGER, "grade" INTEGER, "heisig_en" TEXT, "jlpt" INTEGER, "kanji" TEXT, "kun_readings" TEXT, "meanings" TEXT, "name_readings" TEXT, "notes" TEXT, "on_readings" TEXT, "stroke_count" INTEGER, "unicode" TEXT, "unihan_cjk_compatibility_variant" TEXT);
CREATE INDEX "idx_kanjis_key" ON "kanjis" ("_key");
CREATE TABLE IF NOT EXISTS "readings" ("_key" TEXT, "main_kanji" TEXT, "name_kanji" TEXT, "reading" TEXT);
CREATE INDEX "idx_readings_key" ON "readings" ("_key");
CREATE TABLE IF NOT EXISTS "words" (
      "id" INTEGER PRIMARY KEY,
      "kanji" TEXT NOT NULL
    );
CREATE INDEX "idx_words_kanji" ON "words" ("kanji");
CREATE TABLE IF NOT EXISTS "word_meanings" (
      "id" INTEGER PRIMARY KEY,
      "word_id" INTEGER NOT NULL,
      "glosses" TEXT NOT NULL,
      FOREIGN KEY ("word_id") REFERENCES "words" ("id")
    );
CREATE INDEX "idx_word_meanings_word_id" ON "word_meanings" ("word_id");
CREATE TABLE IF NOT EXISTS "word_variants" (
      "id" INTEGER PRIMARY KEY,
      "word_id" INTEGER NOT NULL,
      "priorities" TEXT,
      "pronounced" TEXT,
      "written" TEXT,
      FOREIGN KEY ("word_id") REFERENCES "words" ("id")
    );
CREATE INDEX "idx_word_variants_word_id" ON "word_variants" ("word_id");
CREATE TABLE IF NOT EXISTS "jmdict_entries" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "ent_seq" INTEGER NOT NULL UNIQUE
    );
CREATE TABLE sqlite_sequence(name,seq);
CREATE INDEX "idx_jmdict_entries_ent_seq" ON "jmdict_entries" ("ent_seq");
CREATE TABLE IF NOT EXISTS "jmdict_kanji" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "entry_id" INTEGER NOT NULL,
      "keb" TEXT NOT NULL,
      "ke_inf" TEXT,
      "ke_pri" TEXT,
      FOREIGN KEY ("entry_id") REFERENCES "jmdict_entries" ("id")
    );
CREATE INDEX "idx_jmdict_kanji_entry_id" ON "jmdict_kanji" ("entry_id");
CREATE INDEX "idx_jmdict_kanji_keb" ON "jmdict_kanji" ("keb");
CREATE TABLE IF NOT EXISTS "jmdict_readings" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "entry_id" INTEGER NOT NULL,
      "reb" TEXT NOT NULL,
      "re_nokanji" INTEGER DEFAULT 0,
      "re_restr" TEXT,
      "re_inf" TEXT,
      "re_pri" TEXT,
      FOREIGN KEY ("entry_id") REFERENCES "jmdict_entries" ("id")
    );
CREATE INDEX "idx_jmdict_readings_entry_id" ON "jmdict_readings" ("entry_id");
CREATE INDEX "idx_jmdict_readings_reb" ON "jmdict_readings" ("reb");
CREATE TABLE IF NOT EXISTS "jmdict_senses" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "entry_id" INTEGER NOT NULL,
      "sense_num" INTEGER NOT NULL,
      "stagk" TEXT,
      "stagr" TEXT,
      "pos" TEXT,
      "field" TEXT,
      "misc" TEXT,
      "dial" TEXT,
      "s_inf" TEXT,
      FOREIGN KEY ("entry_id") REFERENCES "jmdict_entries" ("id")
    );
CREATE INDEX "idx_jmdict_senses_entry_id" ON "jmdict_senses" ("entry_id");
CREATE TABLE IF NOT EXISTS "jmdict_glosses" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "gloss" TEXT NOT NULL,
      "lang" TEXT DEFAULT 'eng',
      "g_type" TEXT,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    );
CREATE INDEX "idx_jmdict_glosses_sense_id" ON "jmdict_glosses" ("sense_id");
CREATE TABLE IF NOT EXISTS "jmdict_lsources" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "lsource" TEXT,
      "lang" TEXT DEFAULT 'eng',
      "ls_type" TEXT,
      "ls_wasei" INTEGER DEFAULT 0,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    );
CREATE INDEX "idx_jmdict_lsources_sense_id" ON "jmdict_lsources" ("sense_id");
CREATE TABLE IF NOT EXISTS "jmdict_xrefs" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "xref" TEXT NOT NULL,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    );
CREATE INDEX "idx_jmdict_xrefs_sense_id" ON "jmdict_xrefs" ("sense_id");
CREATE TABLE IF NOT EXISTS "jmdict_ants" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "sense_id" INTEGER NOT NULL,
      "ant" TEXT NOT NULL,
      FOREIGN KEY ("sense_id") REFERENCES "jmdict_senses" ("id")
    );
CREATE INDEX "idx_jmdict_ants_sense_id" ON "jmdict_ants" ("sense_id");
