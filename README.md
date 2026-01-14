<div align="center">
  <img src="assets/icon/app_icon.png" alt="JPN Learning Diary" width="150"/>
  
# JPN Learning Diary
  
  A desktop app to track your Japanese language learning progress, take notes and practice.
  
  ![Flutter](https://img.shields.io/badge/Flutter-3.10.4-02569B?logo=flutter)
  ![Platform](https://img.shields.io/badge/Platform-Windows%20|%20macOS%20|%20Linux-lightgrey)
</div>

---

## Features

### Character Dictionaries

- **Hiragana Dictionary** - Complete gojūon, dakuten, han-dakuten, and yōon characters
- **Katakana Dictionary** - Full katakana character set with romanization
- **Kanji Dictionary** - 6000+ kanji with meanings, readings, stroke counts, and JLPT levels

### Learning Diary

- Track learned words and phrases with:
  - Japanese text (kanji/kana)
  - Furigana reading guides
  - Romaji romanization
  - English meanings
  - Personal notes

### Practice Modes

- **Diary Quiz** - Practice your saved vocabulary with interactive typing tests
- **Kanji Quiz** - Test your kanji knowledge based on characters in your diary
- **Study Mode** - Bring your japanese text and explore it word by word

### Local Data

- All data stored locally in SQLite database
- No internet connection required

## Installation

Download the latest release for your platform from the [Releases](https://github.com/spalter/jpn-learning-diary/releases) page.

## Development

### Pre

### Debugging

```bash
# Clone the repository
git clone https://github.com/spalter/jpn-learning-diary.git
cd jpn-learning-diary

# Get dependencies
flutter pub get

# Download the Words/Kanji data from kanjiapi.dev and converts it into a DB file that can
# be used by the JPN Learning Diary App.
./tools/convert.sh

# Run in debug mode
flutter run

# Example to run without window effects (for testing)
flutter run --dart-define=args=--no-effects
```

### Release Builds

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

The built application will be in:

- Windows: `build/windows/x64/runner/Release/`
- macOS: `build/macos/Build/Products/Release/`
- Linux: `build/linux/x64/release/bundle/`

## Credits

- Flutter [flutter.dev](https://flutter.dev/).
- Takoboto [takoboto.jp](https://takoboto.jp/).
- The Kanji dictionary is based on [kanjiapi.dev](https://kanjiapi.dev/). Huge prop to them for compling so much data and make it available.
