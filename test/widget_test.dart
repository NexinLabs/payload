import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payload/main.dart';

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PayloadApp()));
    await tester.pumpAndSettle();
    expect(find.text('PAYLOAD'), findsOneWidget);
  });
}
