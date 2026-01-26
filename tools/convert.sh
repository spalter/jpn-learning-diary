#!/bin/bash

# Simple script to download the jpn data, extract it and convert it.
# Kanji API: https://kanjiapi.dev/kanjiapi_full.zip
# JMdict: ftp://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz

# ==============================================================================
# Kanji API Data
# ==============================================================================

# Download the zip file
curl -L -o tools/kanjiapi_full.zip https://kanjiapi.dev/kanjiapi_full.zip

# Unzip the JSON file to tools directory
unzip -j tools/kanjiapi_full.zip kanjiapi_full.json -d tools

# Execute the Dart command
dart --packages=".dart_tool/package_config.json" tools/json_to_sqlite.dart tools/kanjiapi_full.json lib/assets/jpn.db

# Clean up the zip file
rm tools/kanjiapi_full.zip

# ==============================================================================
# JMdict Data
# ==============================================================================

# Download JMdict (English) from EDRDG
curl -o tools/JMdict_e.gz ftp://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz

# Extract the gzip file
gzip -d tools/JMdict_e.gz

# Execute the JMdict to SQLite conversion
dart --packages=".dart_tool/package_config.json" tools/jmdict_to_sqlite.dart tools/JMdict_e lib/assets/jpn.db

# Clean up the extracted file
rm tools/JMdict_e
