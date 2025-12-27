import 'package:flutter_test/flutter_test.dart';
import 'package:payload/main.dart';

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    await tester.pumpWidget(const PayloadApp());
    expect(find.text('PAYLOAD'), findsOneWidget);
  });
}
