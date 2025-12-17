import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/base_layout.dart';

/// Phrases and words tracking page.
///
/// Displays and manages learned Japanese phrases and vocabulary words.
/// Provides functionality to track learning progress and practice.
class PhrasesWordsPage extends StatelessWidget {
  const PhrasesWordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Phrases & Words',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Learned phrases and words will be displayed here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
