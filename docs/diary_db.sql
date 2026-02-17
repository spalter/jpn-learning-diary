CREATE TABLE android_metadata (locale TEXT);
CREATE TABLE IF NOT EXISTS "diary_entries" (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          japanese TEXT NOT NULL,
          romaji TEXT NOT NULL,
          meaning TEXT NOT NULL,
          notes TEXT,
          date_added INTEGER NOT NULL
        );
CREATE TABLE sqlite_sequence(name,seq);
