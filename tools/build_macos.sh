#!/bin/bash

# Build the Flutter macOS app in release mode
flutter build macos --release

# Copy the built app to Applications folder
cp -r build/macos/Build/Products/Release/jpn_learning_diary.app "/Applications/JPN Learning Diary.app"

echo "Build complete and app deployed to Applications folder"

