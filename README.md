<div align="center">
  <img src="assets/icon/app_icon.png" alt="JPN Learning Diary" width="150"/>
  
# JPN Learning Diary
  
  A beautiful, modern desktop app to track your Japanese language learning progress.
  
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
  - Date tracking

### Practice Modes

- **Diary Quiz** - Practice your saved vocabulary with interactive typing tests
- **Kanji Quiz** - Test your kanji knowledge based on characters in your diary

### Search

- Search across diary entries and kanji database simultaneously
- Finds matches in Japanese text, readings, meanings, and notes
- Instant results as you type

### Modern UI

- **Tokyo Night** and **Tokyo Day** themes with automatic system theme switching
- Windows Mica effect for modern translucent appearance
- Responsive design that adapts to window size
- Clean, flat card-based interface

### Local Data

- All data stored locally in SQLite database
- No internet connection required

### Quick Actions

- **One-tap copy** - Tap any element to copy Japanese text to clipboard
- **Long-press edit** - Hold entries to edit or delete them
- **Double-top search** - Search for selected entries in the app

## Installation

Download the latest release for your platform from the [Releases](https://github.com/spalter/jpn-learning-diary/releases) page.

## Data Location

Your local database is stored at:

### Windows

```cmd
C:\Users\<YourUsername>\AppData\Roaming\com.example\jpn_learning_diary\diary.db
```

### macOS

```bash
/Users/<username>/Library/Containers/com.example.jpnLearningDiary/Data/Documents/diary.db
```

### Linux

```bash
~/.local/share/jpn_learning_diary/diary.db
```

## Development

### Requirements

- [Flutter SDK](https://flutter.dev/) 3.10.4 or higher
- [Git](https://git-scm.com/)
- Platform-specific toolchains:
  - **Windows**: Visual Studio 2022 with C++ desktop development
  - **macOS**: Xcode
  - **Linux**: Required development libraries

### Setup

```bash
# Clone the repository
git clone https://github.com/spalter/jpn-learning-diary.git
cd jpn-learning-diary

# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Run without window effects (for testing)
flutter run --dart-define=args=--no-effects
```

### Build / Release

The app requires the dataset from [kanjiapi.dev](https://kanjiapi.dev/). Download the data and run the `tool/json_to_sqlite.dart` script.

```bash
# Convert the aata
dart --packages=".dart_tool/package_config.json" tool/json_to_sqlite.dart tool/kanjiapi_full.json lib/assets/jpn.db   

# Check the DB
dart --packages=".dart_tool/package_config.json" tool/check_db.dart lib/assets/jpn.db
```

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

- Flutter [flutter.dev](https://flutter.dev/)
- The Kanji dictionary is based on [kanjiapi.dev](https://kanjiapi.dev/). Huge prop to them for compling so much data and make it available.

## Contributing

Contributions are welcome! If you'd like to improve the app, please follow these steps:

1. **Fork the repository**  
   Click the "Fork" button at the top right of this repository to create your own copy.

2. **Clone your fork**  

   ```bash
   git clone https://github.com/YOUR-USERNAME/jpn_learning_diary.git
   cd jpn_learning_diary
   ```

3. **Create a feature branch**  

   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**  
   - Write clean, well-documented code
   - Follow the existing code style
   - Test your changes thoroughly

5. **Commit your changes**  

   ```bash
   git add .
   git commit -m "Add: Description of your changes"
   ```

6. **Push to your fork**  

   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**  
   Go to the original repository and click "New Pull Request". Select your fork and branch, then describe your changes.

### Guidelines

- Keep PRs focused on a single feature or fix
- Include a clear description of what your PR does
- Update documentation if needed
- Make sure the app builds successfully before submitting
