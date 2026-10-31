import 'package:flutter_test/flutter_test.dart';
import 'package:pml_7/main.dart';

void main() {
  testWidgets('Smoke test for PML 07 app', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('App Supa B'), findsOneWidget);
  });
}
