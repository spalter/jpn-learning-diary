import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';

/// Hiragana alphabet learning and practice page.
///
/// Displays the hiragana character set and provides tools for
/// learning and practicing hiragana reading and writing.
class HiraganaPage extends StatelessWidget {
  const HiraganaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'あ',
              style: TextStyle(
                fontSize: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hiragana Alphabet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Hiragana characters will be displayed here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
