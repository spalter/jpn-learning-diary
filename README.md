# JPN Learning Diary

A simple app to track your japanese language learning progress.

## Features

* A Hiragana dictionary
* A Katakana dictionary
* A Kanji dictionary
* A diary for your learnings, words, phrases etc.
* Search through your diary and the dictionary
* Local data only (for now)

### Copy to Clipboard

Taping on a element will copy the japanese text to the systems clipboard.

### Modify and Delete Items

To modify items, hold on to the entry for a second, a popup with a edit form should appear. You can also delete entries from there.


### Local DB

The local database file should be in either of the following directories:

#### Macos

`/Users/<user>/Library/Containers/com.example.jpnLearningDiary/Data/Documents/diary.db`

#### Windows

Coming Soon™

#### Linux

Coming Soon™

## Development

### Requirements

* VSCode / Flutter
* Git

### Build / Release

```bash
flutter build macos --release
```

## Credits

* Flutter [flutter.dev](https://flutter.dev/)
* The Kanji dictionary is based on [davidluzgouveia/kanji-data](https://github.com/davidluzgouveia/kanji-data). Huge prop to them for compling so much data and make it available. 

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

