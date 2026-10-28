
import 'package:flutter_test/flutter_test.dart';
import 'package:sopan_learning_app/main.dart';

void main() {
  testWidgets('Sopan Learning app starts on login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SopanLearningApp());

    expect(find.text('SOPAN LEARNING'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
