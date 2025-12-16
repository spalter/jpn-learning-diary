import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/widgets/app_menu.dart';
import 'package:jpn_learning_diary/widgets/app_navigation_bar.dart';

class HiraganaPage extends StatefulWidget {
  const HiraganaPage({super.key});

  @override
  State<HiraganaPage> createState() => _HiraganaPageState();
}

class _HiraganaPageState extends State<HiraganaPage> {
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
