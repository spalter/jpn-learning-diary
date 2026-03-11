// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jpn_learning_diary/widgets/learning_mode_app_bar.dart';

/// Help page providing documentation for app features, shortcuts, and usage.
///
/// Displays categorized help content including keyboard shortcuts,
/// navigation guide, learning modes, and settings explanations.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key, this.isDialog = false});

  /// Whether the help page is displayed as a dialog popup.
  final bool isDialog;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;
  bool get _isMac => Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildWelcomeSection(context),
        const SizedBox(height: 32),
        _buildNavigationSection(context),
        const SizedBox(height: 32),
        _buildDiarySection(context),
        const SizedBox(height: 32),
        if (!_isMobile) ...[
          _buildKeyboardShortcutsSection(context),
          const SizedBox(height: 32),
        ],
        _buildLearningModesSection(context),
        const SizedBox(height: 32),
        _buildFlashcardSection(context),
        const SizedBox(height: 32),
        _buildSettingsSection(context),
        const SizedBox(height: 32),
        _buildCreditsSection(context),
      ],
    );

    if (isDialog) {
      return Column(
        children: [
          AppBar(
            title: const Text('Help'),
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 0,
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: const LearningModeAppBar(title: 'Help'),
      body: content,
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'lib/assets/bird_cropped.png',
              width: 80,
              height: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Welcome!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ようこそ!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Japanese Learning Diary helps you track your Japanese language learning journey. '
                    'Record vocabulary, phrases, and notes as you study, then practice with various learning modes.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.hasData
                          ? 'Version ${snapshot.data!.version}'
                          : 'Loading version...';
                      return Text(
                        version,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(150),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Navigation',
      icon: Icons.navigation,
      children: [
        _buildHelpItem(
          context,
          icon: Icons.menu_book,
          title: 'Diary',
          description:
              'Your main collection of Japanese phrases, words, and notes. '
              'Add entries with Japanese text, romaji, meanings, and personal notes.',
        ),
        _buildHelpItem(
          context,
          iconText: 'あ',
          title: 'Hiragana',
          description:
              'Reference chart for hiragana characters with readings and example words.',
        ),
        _buildHelpItem(
          context,
          iconText: 'ア',
          title: 'Katakana',
          description:
              'Reference chart for katakana characters with readings and example words.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.school,
          title: 'Learning',
          description:
              'Access learning modes, quizzes, and track your progress statistics.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.settings,
          title: 'Settings',
          description:
              'Configure app preferences, themes, database management, and cloud sync.',
        ),
      ],
    );
  }

  Widget _buildKeyboardShortcutsSection(BuildContext context) {
    final modKey = _isMac ? '⌘' : 'Ctrl';
    
    return _buildSectionCard(
      context: context,
      title: 'Keyboard Shortcuts',
      icon: Icons.keyboard,
      children: [
        _buildSubsection(context, 'General'),
        _buildShortcutItem(context, '$modKey + N', 'New diary entry'),
        _buildShortcutItem(context, '$modKey + F', 'Search diary entries'),
        _buildShortcutItem(context, '$modKey + ,', 'Open settings'),
        _buildShortcutItem(context, '?', 'Open help (this page)'),
        _buildShortcutItem(context, 'Escape', 'Unfocus / close dialogs'),
        _buildShortcutItem(context, 'F11', 'Toggle fullscreen'),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Navigation'),
        _buildShortcutItem(context, '$modKey + 1', 'Go to Diary'),
        _buildShortcutItem(context, '$modKey + 2', 'Go to Hiragana'),
        _buildShortcutItem(context, '$modKey + 3', 'Go to Katakana'),
        _buildShortcutItem(context, '$modKey + 4', 'Go to Learning'),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Vim-style Navigation'),
        _buildShortcutItem(context, 'H / J / K / L', 'Move focus left / down / up / right'),
        Text(
          'Vim keys only work when not typing in a text field.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
        ),
      ],
    );
  }

  Widget _buildLearningModesSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Learning Modes',
      icon: Icons.school,
      children: [
        _buildHelpItem(
          context,
          icon: Icons.auto_stories,
          title: 'Study',
          description:
              'Paste or type Japanese text (multiple lines supported) and the app will automatically '
              'separate lines and tokenize words. Each line is analyzed to find matching words, kanji, '
              'and dictionary entries, with results appearing by selecting a word to help you understand the text. '
              'Tap any word to see its breakdown. Long press a word to search for it on takoboto.jp '
              'for detailed definitions. Toggle the tokenized view to see word boundaries clearly separated.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.edit_note,
          title: 'Diary Quiz',
          description:
              'Selects random entries from your diary and presents them as flashcards. '
              'Reveal the answer and rate yourself from Again to Easy, just like the '
              'flashcard decks. Great for reviewing what you\'ve learned.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.history_edu,
          title: 'Kanji Quiz',
          description:
              'Finds kanji characters in your diary entries and presents them as flashcards '
              'focused on kanji words only. Rate each card to cycle through the deck until '
              'you feel confident. Perfect for reinforcing kanji recognition.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.menu_book,
          title: 'Vocabulary Quiz',
          description:
              'Practice with vocabulary from the Japanese dictionary, independent of your diary '
              'content. Cards are presented in the same reveal-and-rate style, letting you '
              'work through a broader range of words at your own pace.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.collections_bookmark,
          title: 'My Quizzes',
          description:
              'Import custom quizzes from CSV files to practice with JLPT vocabulary or your '
              'own content. Questions are presented with multiple choice answers.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.style,
          title: 'Flashcard Decks',
          description:
              'Import Anki-compatible APKG decks and study them with a spaced-repetition '
              'style workflow. See the Flashcard Decks section below for details.',
        ),
      ],
    );
  }

  Widget _buildFlashcardSection(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return _buildSectionCard(
      context: context,
      title: 'Flashcard Overview',
      icon: Icons.style,
      children: [
        Text(
          'The app supports Anki-compatible flashcard decks in the APKG format. '
          'You can export decks from Anki Desktop via File → Export, or browse '
          'thousands of community-shared decks at ankiweb.net. Once you have an '
          'APKG file, open it from the Learning section to add it to your collection.',
          style: textStyle,
        ),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Study Modes'),
        Text(
          'Each deck offers two ways to study. "New Cards" presents cards you '
          'have not yet reviewed, keeping them in the original deck order so you '
          'can work through a course sequentially. "Review" gathers cards you '
          'have studied before and shuffles them, giving you a randomized '
          'refresher session. Cards you have already mastered are automatically '
          'excluded from both modes.',
          style: textStyle,
        ),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Rating Your Answers'),
        Text(
          'After revealing a card, you rate how well you knew the answer using '
          'one of four options. "Again" means you did not recall it at all — the '
          'card goes back into the current session so you see it once more. '
          '"Hard" means you got it, but with difficulty — the card is also '
          're-enqueued for another pass. "Good" means you knew the answer '
          'comfortably — the card stays in the session for one more round of '
          'reinforcement. "Easy" means you recalled it instantly, and the card '
          'is removed from the current session right away.',
          style: textStyle,
        ),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Progress & Mastery'),
        Text(
          'Your progress is tracked per card across sessions. A card is '
          'considered mastered once you have rated it "Easy" and reviewed it at '
          'least twice in total. The deck selection screen shows how far along '
          'you are with a mastery percentage and a count of reviewed versus '
          'total cards. This progress persists between sessions, so you can '
          'pick up right where you left off.',
          style: textStyle,
        ),
        if (!_isMobile) ...[
          const SizedBox(height: 16),
          _buildSubsection(context, 'Keyboard Shortcuts'),
          Text(
            'Press Space to reveal the answer, then use the number keys 1 '
            'through 4 to rate: 1 for Again, 2 for Hard, 3 for Good, and 4 '
            'for Easy.',
            style: textStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildDiarySection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Diary Entries',
      icon: Icons.edit_note,
      children: [
        Text(
          'Each diary entry can contain:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        _buildBulletPoint(context, 'Japanese text (with optional furigana)'),
        _buildBulletPoint(context, 'Romaji transcription'),
        _buildBulletPoint(context, 'English meaning or translation'),
        _buildBulletPoint(context, 'Personal notes and context'),
        _buildBulletPoint(context, 'Tags for organization'),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Entry Actions'),
        _buildHelpItem(
          context,
          icon: Icons.touch_app,
          title: 'Single Tap',
          description: 'Copy the entry text to clipboard.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.pan_tool,
          title: 'Long Press',
          description: 'Open the entry for editing.',
        ),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Furigana Format'),
        Text(
          'Add readings above kanji using: [漢字](かんじ)\n'
          'Example: [日本語](にほんご)を[勉強](べんきょう)する',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Settings Overview',
      icon: Icons.settings,
      children: [
        _buildHelpItem(
          context,
          icon: Icons.palette,
          title: 'Color Theme',
          description:
              'Choose your preferred accent color from a variety of options. '
              'Light and dark mode automatically follow your system settings.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.view_module,
          title: 'View Mode',
          description:
              'Switch between list and grid layouts for diary entries (desktop only).',
        ),
        _buildHelpItem(
          context,
          icon: Icons.storage,
          title: 'Database Location',
          description:
              'Select a custom database file location, for example in Dropbox, '
              'Google Drive, or another cloud folder to automatically sync across devices.',
        ),
      ],
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    IconData? icon,
    String? iconText,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: iconText != null
                  ? Text(
                      iconText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(200),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(
    BuildContext context,
    String shortcut,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(100),
              ),
            ),
            child: Text(
              shortcut,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Credits',
      icon: Icons.favorite,
      children: [
        Text(
          'Japanese Learning Diary is an open source project.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => launchUrl(
            Uri.parse('https://github.com/spalter/jpn-learning-diary'),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'github.com/spalter/jpn-learning-diary',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSubsection(context, 'Data Sources'),
        _buildHelpItem(
          context,
          icon: Icons.auto_stories,
          title: 'kanjiapi.dev',
          description:
              'Provides kanji data including readings, meanings, and stroke information.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.translate,
          title: 'EDRDG (JMdict)',
          description:
              'The Electronic Dictionary Research and Development Group maintains '
              'the JMdict Japanese-English dictionary used for word lookups and search.',
        ),
        _buildHelpItem(
          context,
          icon: Icons.style,
          title: 'Anki',
          description:
              'Flashcard deck import uses the APKG format created by the Anki '
              'spaced-repetition software. Decks can be exported from Anki Desktop '
              'or downloaded from ankiweb.net.',
        ),
        const SizedBox(height: 12),
        Text(
          'See Licenses in Settings for full attribution.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
        ),
      ],
    );
  }

  Widget _buildSubsection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
