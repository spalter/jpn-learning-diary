import 'package:flutter_test/flutter_test.dart';
import 'package:jpn_learning_diary/main.dart';

void main() {
  testWidgets('Home Page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JapaneseLearningDiary());
  });
}
