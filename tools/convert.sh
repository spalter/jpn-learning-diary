#/bin/bash

# Simple script to download the jpn data, extract it and covert it.
# URL https://kanjiapi.dev/kanjiapi_full.zip:w

# Download the zip file
curl -L -o tools/kanjiapi_full.zip https://kanjiapi.dev/kanjiapi_full.zip

# Unzip the JSON file to tools directory
unzip -j tools/kanjiapi_full.zip kanjiapi_full.json -d tools

# Execute the Dart command
dart --packages=".dart_tool/package_config.json" tools/json_to_sqlite.dart tools/kanjiapi_full.json lib/assets/jpn.db

# Optional: Clean up the zip file
rm tools/kanjiapi_full.zip

