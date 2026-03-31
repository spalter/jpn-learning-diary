// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jpn_learning_diary/services/japanese_text_utils.dart';
import 'package:jpn_learning_diary/widgets/takoboto_viewer.dart';

/// Interactive vertical Japanese text display with token selection support.
///
/// This widget renders Japanese text in the traditional tategaki (vertical) format,
/// flowing from right to left. It analyzes the text to identify tokens and
/// makes them interactive for dictionary lookups, supporting both touch and
/// mouse interactions.
///
/// * [lines]: List of text lines to display vertically.
/// * [selectedWord]: The specific word token currently selected by the user.
/// * [annotations]: Map of words to user notes/annotations to display.
/// * [onWordTap]: Callback function triggered when a word is tapped.
/// * [scrollController]: Controller for the horizontal scroll view.
/// * [isMobile]: Whether the layout should adapt for mobile screen sizes.
class VerticalTextDisplay extends StatelessWidget {
  final List<String> lines;
  final String? selectedWord;
  final Map<String, String> annotations;
  final Function(String) onWordTap;
  final ScrollController scrollController;
  final bool isMobile;

  const VerticalTextDisplay({
    super.key,
    required this.lines,
    required this.selectedWord,
    required this.annotations,
    required this.onWordTap,
    required this.scrollController,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty || (lines.length == 1 && lines[0].isEmpty)) {
      return _buildEmptyStateHint(context);
    }

    final nonEmptyLines = lines.where((l) => l.trim().isNotEmpty).toList();

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final offset = scrollController.offset - event.scrollDelta.dy;
          scrollController.jumpTo(
            offset.clamp(0.0, scrollController.position.maxScrollExtent),
          );
        }
      },
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            for (int index = 0; index < nonEmptyLines.length; index++)
              _buildVerticalLineSection(
                context,
                index,
                nonEmptyLines[index],
                isLast: index == nonEmptyLines.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter some Japanese text above',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kanji found in each line will be displayed here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLineSection(
    BuildContext context,
    int lineIndex,
    String line, {
    bool isLast = false,
  }) {
    final bottomPadding = isMobile ? 110.0 : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: isLast ? 8 : 0,
            bottom: bottomPadding,
          ),
          child: _buildVerticalTokenizedText(context, line),
        ),
      ],
    );
  }

  Widget _buildVerticalTokenizedText(BuildContext context, String line) {
    final tokens = JapaneseTextUtils.tokenize(line)
        .where((t) => t.trim().isNotEmpty)
        .toList();

    return Wrap(
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.down,
      textDirection: TextDirection.rtl,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: isMobile ? 16 : 12,
      children: [
        for (var token in tokens)
          _buildVerticalToken(context, token, annotations[token]),
      ],
    );
  }

  Widget _buildVerticalToken(
    BuildContext context,
    String token,
    String? annotation,
  ) {
    final decorationPattern = RegExp(
      r'^[、。！？「」『』（）〈〉《》【】〔〕・…―ー～，．：；]+$',
    );
    final isPunctuation = decorationPattern.hasMatch(token);
    final baseStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 23);
    final style = GoogleFonts.kleeOne(textStyle: baseStyle, fontWeight: FontWeight.w600);
    final isSelected = token == selectedWord;
    const double tokenWidth = 22.0;

    if (isPunctuation) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final char in token.characters)
            VerticalCharacter(character: char, style: style),
        ],
      );
    }

    return ClickableVerticalWord(
      word: token,
      isSelected: isSelected,
      annotation: annotation,
      onTap: () => onWordTap(token),
      onLongPress: () => TakobotoViewer.showPopup(context, token),
      style: style,
      fixedWidth: tokenWidth,
      isMobile: isMobile,
    );
  }
}

class VerticalCharacter extends StatelessWidget {
  final String character;
  final TextStyle? style;

  const VerticalCharacter({
    super.key,
    required this.character,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final needsRotationPattern = RegExp(r'[「」『』（）〈〉《》【】〔〕…―ー～：；]');
    final needsTranslationPattern = RegExp(r'[、。，．]');

    if (needsRotationPattern.hasMatch(character)) {
      Widget rotated = RotatedBox(
        quarterTurns: 1,
        child: Text(character, style: style),
      );

      // The chouonpu (ー) and similar characters often appear off-center to the left 
      // when rotated because they sit on the horizontal baseline. We translate them 
      // slightly to the right to center them visually in the vertical text line.
      // Using Transform.translate ensures the layout box doesn't change, keeping
      // ruby annotations perfectly aligned.
      if (character == 'ー' || character == '―' || character == '…' || character == '～') {
        final fontSize = style?.fontSize ?? 23.0;
        return Transform.translate(
          offset: Offset(fontSize * 0.15, 0),
          child: rotated,
        );
      }

      return rotated;
    } else if (needsTranslationPattern.hasMatch(character)) {
      // In vertical text, commas and periods are placed at the top right
      // of the character cell. We translate them slightly to approximate this.
      final fontSize = style?.fontSize ?? 23.0;
      return Transform.translate(
        offset: Offset(fontSize * 0.5, -fontSize * 0.5),
        child: Text(character, style: style),
      );
    }

    return Text(character, style: style);
  }
}

class ClickableVerticalWord extends StatefulWidget {
  final String word;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final TextStyle? style;
  final bool isSelected;
  final String? annotation;
  final double? fixedWidth;
  final bool isMobile;

  const ClickableVerticalWord({
    super.key,
    required this.word,
    required this.onTap,
    this.onLongPress,
    this.style,
    this.isSelected = false,
    this.annotation,
    this.fixedWidth,
    this.isMobile = false,
  });

  @override
  State<ClickableVerticalWord> createState() => _ClickableVerticalWordState();
}

class _ClickableVerticalWordState extends State<ClickableVerticalWord> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.style?.color ?? Theme.of(context).colorScheme.onSurface;
    final hoverColor = Theme.of(context).colorScheme.primary;
    final selectedColor = Theme.of(context).colorScheme.primary;

    Color textColor;
    if (widget.isSelected) {
      textColor = selectedColor;
    } else if (_isHovering) {
      textColor = hoverColor;
    } else {
      textColor = baseColor;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMainWordColumn(context, textColor),
              if (widget.annotation != null && widget.annotation!.isNotEmpty)
                SizedBox(
                  width: 0,
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: widget.isMobile ? 8 : 2),
                      child: _buildAnnotationColumn(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainWordColumn(BuildContext context, Color textColor) {
    return SizedBox(
      width: widget.fixedWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (widget.isSelected)
            Positioned.fill(
              top: -1,
              bottom: -3,
              left: -4,
              right: -8,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final char in widget.word.characters)
                  VerticalCharacter(
                    character: char,
                    style: widget.style?.copyWith(
                          color: textColor,
                          fontWeight: widget.isSelected ? FontWeight.bold : null,
                        ) ??
                        TextStyle(
                          color: textColor,
                          fontWeight: widget.isSelected ? FontWeight.bold : null,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final char in widget.annotation!.characters)
          VerticalCharacter(
            character: char,
            style: TextStyle(
              fontSize: 12,
              height: 1.0,
              color: Theme.of(context).colorScheme.primary.withAlpha(180),
            ),
          ),
      ],
    );
  }
}
