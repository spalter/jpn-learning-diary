import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';

/// Katakana alphabet learning and practice page.
///
/// Displays the katakana character set and provides tools for
/// learning and practicing katakana reading and writing.
class KatakanaPage extends StatelessWidget {
  const KatakanaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ア',
              style: TextStyle(
                fontSize: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Katakana Alphabet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Katakana characters will be displayed here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
