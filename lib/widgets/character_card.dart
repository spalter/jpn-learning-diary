import 'package:flutter/material.dart';

/// A reusable card widget for displaying Japanese characters.
///
/// Used for displaying hiragana, katakana, and kanji characters
/// with optional romanization.
class CharacterCard extends StatefulWidget {
  /// The Japanese character to display (e.g., 'あ', 'ア', '漢').
  final String character;
  
  /// The romanized version of the character (e.g., 'a', 'ka', 'kan').
  final String romanization;
  
  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;
  
  /// Whether the card is selected/highlighted.
  final bool isSelected;

  const CharacterCard({
    super.key,
    required this.character,
    required this.romanization,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Card(
        elevation: widget.isSelected ? 8 : 2,
        color: widget.isSelected 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface.withAlpha(100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isHovering 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withAlpha(0),
            width: _isHovering ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.character,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.romanization,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
