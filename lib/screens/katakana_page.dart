import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/app_menu.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';

class KatakanaPage extends StatefulWidget {
  const KatakanaPage({super.key});

  @override
  State<KatakanaPage> createState() => _KatakanaPageState();
}

class _KatakanaPageState extends State<KatakanaPage> {
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
