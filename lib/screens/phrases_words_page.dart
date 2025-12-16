import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/app_menu.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';

class PhrasesWordsPage extends StatefulWidget {
  const PhrasesWordsPage({super.key});

  @override
  State<PhrasesWordsPage> createState() => _PhrasesWordsPageState();
}

class _PhrasesWordsPageState extends State<PhrasesWordsPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavigationBar(textController: _textController),
      drawer: const AppMenu(),
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(100),
      body: Center(
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
