import 'package:flutter_test/flutter_test.dart';
import 'package:documentation_generator/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DocGenApp());
    expect(find.text('Documentation Generator'), findsOneWidget);
    expect(find.text('Upload Video'), findsOneWidget);
    expect(find.text('Upload Screenshots'), findsOneWidget);
  });
}
