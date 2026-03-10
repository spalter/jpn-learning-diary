// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jpn_learning_diary/models/jmdict_entry.dart';
import 'package:jpn_learning_diary/widgets/app_card.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card widget for displaying a JMdict dictionary entry.
///
/// This widget presents JMdict data in a clean, flat design that matches the
/// kanji card style throughout the app. It organizes complex dictionary data
/// into a readable format, displaying the headword, reading, meanings, and
/// metadata badges.
///
/// * [entry]: The JMdict data object containing the dictionary entry details.
class JMdictCard extends StatefulWidget {
  /// The JMdict entry data to display.
  final JMdictEntry entry;

  /// Global key to access the navigation bar for inserting search text.
  final GlobalKey<AppNavigationBarState>? navigationBarKey;

  /// Callback to set search text directly (alternative to navigationBarKey).
  final void Function(String)? onSearchTextSet;

  /// Optional callback for tap action. overrides default copy behavior.
  final VoidCallback? onTap;

  /// Optional callback for double-tap action.
  final VoidCallback? onDoubleTap;

  /// Creates a JMdict card.
  ///
  /// The [entry] parameter is required and contains all the information
  /// to be displayed in the card.
  const JMdictCard({
    super.key,
    required this.entry,
    this.navigationBarKey,
    this.onSearchTextSet,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<JMdictCard> createState() => _JMdictCardState();
}

/// Internal state for [JMdictCard] that manages hover interactions.
///
/// Tracks the mouse hover state to provide visual feedback when the user
/// hovers over the card in minimal (list) mode.
class _JMdictCardState extends State<JMdictCard> {
  /// Whether the mouse is currently hovering over this card.
  bool _isHovering = false;

  /// Builds the JMdict card with hover effects and interaction handlers.
  ///
  /// The card adapts its appearance based on the style setting, applying a
  /// subtle color change on hover when in minimal mode. Gesture handlers
  /// enable tap-to-copy, double-tap-to-search, and long-press-to-lookup.
  @override
  Widget build(BuildContext context) {
    // Apply hover color effect to minimal style (now default)
    final useHoverColor = _isHovering;
    final primaryColor = useHoverColor
        ? Theme.of(context).colorScheme.primary
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AppCard(
        style: AppCardStyle.minimal,
        margin: const EdgeInsets.only(bottom: 12, right: 16),
        padding: const EdgeInsets.all(16),
        onTap: widget.onTap ?? () => _handleCopyToClipboard(context),
        onDoubleTap: widget.onDoubleTap,
        onLongPress: () => _handleOpenDictionary(context),
        child: _buildCardContent(context, primaryColor),
      ),
    );
  }

  /// Builds the card content, with scrolling for bordered style or
  /// expanding naturally for minimal (list view) style.
  Widget _buildCardContent(BuildContext context, Color? primaryColor) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary word and reading
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large word display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary form (kanji or kana)
                Text(
                  widget.entry.primaryForm,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                // Reading (if different from primary form)
                if (widget.entry.kanji.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.entry.primaryReading,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 16),
            // Metadata badges
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.entry.isCommon)
                    _buildBadge(context, 'Common', Icons.star),
                  ..._buildPosBadges(context),
                ],
              ),
            ),
          ],
        ),

        // Alternative kanji forms
        if (widget.entry.kanji.length > 1) ...[
          const SizedBox(height: 12),
          _buildAlternativeForms(
            context,
            'Also written as',
            widget.entry.kanji.skip(1).map((k) => k.keb).toList(),
            Icons.edit,
          ),
        ],

        // Alternative readings
        if (widget.entry.readings.length > 1) ...[
          const SizedBox(height: 12),
          _buildAlternativeForms(
            context,
            'Also read as',
            widget.entry.readings.skip(1).map((r) => r.reb).toList(),
            Icons.record_voice_over,
          ),
        ],

        const SizedBox(height: 16),

        // Senses/Meanings
        ..._buildSenses(context),
      ],
    );

    return content;
  }

  /// Builds badges for part-of-speech tags from the first sense.
  List<Widget> _buildPosBadges(BuildContext context) {
    if (widget.entry.senses.isEmpty) return [];

    final pos = widget.entry.senses.first.partsOfSpeech;
    // Show up to 2 POS tags
    return pos
        .take(2)
        .map((p) => _buildBadge(context, _formatPos(p), Icons.category))
        .toList();
  }

  /// Formats a part-of-speech code into a readable label.
  String _formatPos(String pos) {
    // JMdict entity codes and their readable equivalents
    // These map both the raw entity codes (if not expanded) and full descriptions
    final posMap = {
      // Entity codes (if XML entities weren't expanded)
      '&n;': 'Noun',
      '&v1;': 'Ichidan',
      '&v5u;': 'Godan-u',
      '&v5k;': 'Godan-ku',
      '&v5g;': 'Godan-gu',
      '&v5s;': 'Godan-su',
      '&v5t;': 'Godan-tsu',
      '&v5n;': 'Godan-nu',
      '&v5b;': 'Godan-bu',
      '&v5m;': 'Godan-mu',
      '&v5r;': 'Godan-ru',
      '&v5r-i;': 'Godan-ru (irr)',
      '&v5k-s;': 'Godan-iku',
      '&v5u-s;': 'Godan-u (sp)',
      '&v5aru;': 'Godan-aru',
      '&v5uru;': 'Godan-uru',
      '&vk;': 'Kuru verb',
      '&vs;': 'Suru verb',
      '&vs-i;': 'Suru (irr)',
      '&vs-s;': 'Suru (sp)',
      '&vz;': 'Ichidan-zuru',
      '&vi;': 'Intrans.',
      '&vt;': 'Trans.',
      '&adj-i;': 'i-Adj',
      '&adj-na;': 'na-Adj',
      '&adj-no;': 'no-Adj',
      '&adj-pn;': 'Pre-noun',
      '&adj-t;': 'taru-Adj',
      '&adj-f;': 'Prenominal',
      '&adv;': 'Adverb',
      '&adv-to;': 'Adverb-to',
      '&aux;': 'Auxiliary',
      '&aux-v;': 'Aux. verb',
      '&aux-adj;': 'Aux. adj',
      '&conj;': 'Conj.',
      '&ctr;': 'Counter',
      '&exp;': 'Expression',
      '&int;': 'Interj.',
      '&n-adv;': 'Adv. noun',
      '&n-suf;': 'Noun suf.',
      '&n-pref;': 'Noun pref.',
      '&n-t;': 'Temp. noun',
      '&num;': 'Numeric',
      '&pn;': 'Pronoun',
      '&pref;': 'Prefix',
      '&prt;': 'Particle',
      '&suf;': 'Suffix',
      '&unc;': 'Unclass.',
      '&n-pr;': 'Proper noun',
      // Full descriptions (if entities were expanded)
      'noun (common) (futsuumeishi)': 'Noun',
      'adverb (fukushi)': 'Adverb',
      'Ichidan verb': 'Ichidan',
      'intransitive verb': 'Intrans.',
      'transitive verb': 'Trans.',
      'Expressions (phrases, clauses, etc.)': 'Expression',
      'adjective (keiyoushi)': 'i-Adj',
      'adjectival nouns or quasi-adjectives (keiyodoshi)': 'na-Adj',
      "nouns which may take the genitive case particle `no'": 'no-Adj',
      'pre-noun adjectival (rentaishi)': 'Pre-noun',
      "'taru' adjective": 'taru-Adj',
      'noun or verb acting prenominally': 'Prenominal',
      "adverb taking the `to' particle": 'Adverb-to',
      'auxiliary': 'Auxiliary',
      'auxiliary verb': 'Aux. verb',
      'auxiliary adjective': 'Aux. adj',
      'conjunction': 'Conj.',
      'counter': 'Counter',
      'interjection (kandoushi)': 'Interj.',
      'adverbial noun (fukushitekimeishi)': 'Adv. noun',
      'noun, used as a suffix': 'Noun suf.',
      'noun, used as a prefix': 'Noun pref.',
      'noun (temporal) (jisoumeishi)': 'Temp. noun',
      'numeric': 'Numeric',
      'pronoun': 'Pronoun',
      'prefix': 'Prefix',
      'particle': 'Particle',
      'suffix': 'Suffix',
      'unclassified': 'Unclass.',
      'proper noun': 'Proper noun',
      'noun or participle which takes the aux. verb suru': 'Suru verb',
      'suru verb - irregular': 'Suru (irr)',
      'suru verb - special class': 'Suru (sp)',
      'Kuru verb - special class': 'Kuru verb',
      'Ichidan verb - zuru verb (alternative form of -jiru verbs)':
          'Ichidan-zuru',
      // Misc tags
      '&uk;': 'Usually kana',
      '&uK;': 'Usually kanji',
      '&col;': 'Colloquial',
      '&hon;': 'Honorific',
      '&hum;': 'Humble',
      '&pol;': 'Polite',
      '&arch;': 'Archaic',
      '&obs;': 'Obsolete',
      '&sl;': 'Slang',
      '&fam;': 'Familiar',
      '&fem;': 'Female',
      '&male;': 'Male',
      '&id;': 'Idiomatic',
      '&abbr;': 'Abbrev.',
      '&sens;': 'Sensitive',
      '&vulg;': 'Vulgar',
      '&derog;': 'Derogatory',
      'word usually written using kana alone': 'Usually kana',
      'word usually written using kanji alone': 'Usually kanji',
      'colloquialism': 'Colloquial',
      'honorific or respectful (sonkeigo) language': 'Honorific',
      'humble (kenjougo) language': 'Humble',
      'polite (teineigo) language': 'Polite',
      'archaism': 'Archaic',
      'obsolete term': 'Obsolete',
      'slang': 'Slang',
      'familiar language': 'Familiar',
      'female term or language': 'Female',
      'male term or language': 'Male',
      'idiomatic expression': 'Idiomatic',
      'abbreviation': 'Abbrev.',
      'sensitive': 'Sensitive',
      'vulgar expression or word': 'Vulgar',
      'derogatory': 'Derogatory',
    };

    // Direct lookup
    if (posMap.containsKey(pos)) {
      return posMap[pos]!;
    }

    // Check for Godan verbs (both entity and expanded forms)
    if (pos.contains('Godan verb') || pos.startsWith('&v5')) {
      final match = RegExp(r"Godan verb with `(\w+)'").firstMatch(pos);
      if (match != null) {
        return 'Godan-${match.group(1)}';
      }
      return 'Godan';
    }

    // Truncate if too long
    return pos.length > 12 ? '${pos.substring(0, 10)}…' : pos;
  }

  /// Formats a misc or field tag into a readable label.
  String _formatTag(String tag) {
    final tagMap = {
      // Misc entity codes
      '&uk;': 'Usually kana',
      '&uK;': 'Usually kanji',
      '&col;': 'Colloquial',
      '&hon;': 'Honorific',
      '&hum;': 'Humble',
      '&pol;': 'Polite',
      '&arch;': 'Archaic',
      '&obs;': 'Obsolete',
      '&obsc;': 'Obscure',
      '&sl;': 'Slang',
      '&fam;': 'Familiar',
      '&fem;': 'Female',
      '&male;': 'Male',
      '&id;': 'Idiomatic',
      '&abbr;': 'Abbreviation',
      '&sens;': 'Sensitive',
      '&vulg;': 'Vulgar',
      '&derog;': 'Derogatory',
      '&rare;': 'Rare',
      '&chn;': "Children's",
      '&poet;': 'Poetic',
      '&proverb;': 'Proverb',
      '&on-mim;': 'Onomatopoeia',
      '&joc;': 'Humorous',
      '&m-sl;': 'Manga slang',
      '&male-sl;': 'Male slang',
      '&X;': 'Rude/X-rated',
      '&ateji;': 'Ateji',
      '&gikun;': 'Gikun',
      '&ik;': 'Irregular kana',
      '&iK;': 'Irregular kanji',
      '&io;': 'Irregular okurigana',
      '&oK;': 'Outdated kanji',
      '&ok;': 'Outdated kana',
      '&oik;': 'Old/irregular kana',
      '&eK;': 'Kanji only',
      '&ek;': 'Kana only',
      // Field entity codes
      '&comp;': 'Computing',
      '&med;': 'Medicine',
      '&law;': 'Law',
      '&ling;': 'Linguistics',
      '&math;': 'Math',
      '&physics;': 'Physics',
      '&chem;': 'Chemistry',
      '&biol;': 'Biology',
      '&bot;': 'Botany',
      '&zool;': 'Zoology',
      '&anat;': 'Anatomy',
      '&geol;': 'Geology',
      '&geom;': 'Geometry',
      '&astron;': 'Astronomy',
      '&bus;': 'Business',
      '&econ;': 'Economics',
      '&finc;': 'Finance',
      '&engr;': 'Engineering',
      '&archit;': 'Architecture',
      '&music;': 'Music',
      '&MA;': 'Martial arts',
      '&mil;': 'Military',
      '&food;': 'Food',
      '&sports;': 'Sports',
      '&sumo;': 'Sumo',
      '&baseb;': 'Baseball',
      '&Buddh;': 'Buddhism',
      '&Shinto;': 'Shinto',
      // Dialect codes
      '&kyb;': 'Kyoto-ben',
      '&osb;': 'Osaka-ben',
      '&ksb;': 'Kansai-ben',
      '&ktb;': 'Kantou-ben',
      '&tsb;': 'Tosa-ben',
      '&thb;': 'Touhoku-ben',
      '&tsug;': 'Tsugaru-ben',
      '&kyu;': 'Kyuushuu-ben',
      '&rkb;': 'Ryuukyuu-ben',
      '&nab;': 'Nagano-ben',
      '&hob;': 'Hokkaido-ben',
      // Expanded forms
      'word usually written using kana alone': 'Usually kana',
      'word usually written using kanji alone': 'Usually kanji',
      'colloquialism': 'Colloquial',
      'honorific or respectful (sonkeigo) language': 'Honorific',
      'humble (kenjougo) language': 'Humble',
      'polite (teineigo) language': 'Polite',
      'archaism': 'Archaic',
      'obsolete term': 'Obsolete',
      'obscure term': 'Obscure',
      'slang': 'Slang',
      'familiar language': 'Familiar',
      'female term or language': 'Female',
      'male term or language': 'Male',
      'idiomatic expression': 'Idiomatic',
      'abbreviation': 'Abbreviation',
      'sensitive': 'Sensitive',
      'vulgar expression or word': 'Vulgar',
      'derogatory': 'Derogatory',
      'rare': 'Rare',
      "children's language": "Children's",
      'poetical term': 'Poetic',
      'proverb': 'Proverb',
      'onomatopoeic or mimetic word': 'Onomatopoeia',
      'jocular, humorous term': 'Humorous',
      'manga slang': 'Manga slang',
      'male slang': 'Male slang',
      'rude or X-rated term (not displayed in educational software)':
          'Rude/X-rated',
      'ateji (phonetic) reading': 'Ateji',
      'gikun (meaning as reading)  or jukujikun (special kanji reading)':
          'Gikun',
      'word containing irregular kana usage': 'Irregular kana',
      'word containing irregular kanji usage': 'Irregular kanji',
      'irregular okurigana usage': 'Irregular okurigana',
      'word containing out-dated kanji': 'Outdated kanji',
      'out-dated or obsolete kana usage': 'Outdated kana',
      'old or irregular kana form': 'Old/irregular kana',
      'exclusively kanji': 'Kanji only',
      'exclusively kana': 'Kana only',
      // Fields expanded
      'computer terminology': 'Computing',
      'medicine, etc. term': 'Medicine',
      'law, etc. term': 'Law',
      'linguistics terminology': 'Linguistics',
      'mathematics': 'Math',
      'physics terminology': 'Physics',
      'chemistry term': 'Chemistry',
      'biology term': 'Biology',
      'botany term': 'Botany',
      'zoology term': 'Zoology',
      'anatomical term': 'Anatomy',
      'geology, etc. term': 'Geology',
      'geometry term': 'Geometry',
      'astronomy, etc. term': 'Astronomy',
      'business term': 'Business',
      'economics term': 'Economics',
      'finance term': 'Finance',
      'engineering term': 'Engineering',
      'architecture term': 'Architecture',
      'music term': 'Music',
      'martial arts term': 'Martial arts',
      'military': 'Military',
      'food term': 'Food',
      'sports term': 'Sports',
      'sumo term': 'Sumo',
      'baseball term': 'Baseball',
      'Buddhist term': 'Buddhism',
      'Shinto term': 'Shinto',
      // Dialects expanded
      'Kyoto-ben': 'Kyoto-ben',
      'Osaka-ben': 'Osaka-ben',
      'Kansai-ben': 'Kansai-ben',
      'Kantou-ben': 'Kantou-ben',
      'Tosa-ben': 'Tosa-ben',
      'Touhoku-ben': 'Touhoku-ben',
      'Tsugaru-ben': 'Tsugaru-ben',
      'Kyuushuu-ben': 'Kyuushuu-ben',
      'Ryuukyuu-ben': 'Ryuukyuu-ben',
      'Nagano-ben': 'Nagano-ben',
      'Hokkaido-ben': 'Hokkaido-ben',
    };

    return tagMap[tag] ?? tag;
  }

  /// Builds the list of senses with their glosses.
  List<Widget> _buildSenses(BuildContext context) {
    final widgets = <Widget>[];

    for (var i = 0; i < widget.entry.senses.length; i++) {
      final sense = widget.entry.senses[i];

      if (i > 0) {
        widgets.add(const SizedBox(height: 12));
      }

      // Sense number and glosses
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sense number
            if (widget.entry.senses.length > 1)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Glosses
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // POS tags for this sense (if different from first)
                  if (i > 0 && sense.partsOfSpeech.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        sense.partsOfSpeech.map(_formatPos).join(', '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(179),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  // Gloss text
                  Text(
                    sense.glosses.map((g) => g.gloss).join('; '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // Additional info (field, misc, etc.)
                  if (sense.fields.isNotEmpty || sense.misc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        ...sense.fields,
                        ...sense.misc,
                      ].map(_formatTag).join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return widgets;
  }

  /// Copies the primary form to the system clipboard and shows a snackbar.
  Future<void> _handleCopyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.entry.primaryForm));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${widget.entry.primaryForm}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Opens the word in the Takoboto online dictionary for detailed information.
  ///
  /// Launches the default browser with a pre-filled search query for this word.
  Future<void> _handleOpenDictionary(BuildContext context) async {
    final encodedWord = Uri.encodeComponent(widget.entry.primaryForm);
    final url = Uri.parse('https://takoboto.jp/?q=$encodedWord');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open URL: $url'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Builds a small badge with an icon and label to display metadata.
  Widget _buildBadge(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Builds a section showing alternative forms (kanji or readings).
  Widget _buildAlternativeForms(
    BuildContext context,
    String title,
    List<String> forms,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withAlpha(179),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withAlpha(179),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: forms
                    .map(
                      (form) => Text(
                        form,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
