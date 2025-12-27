import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payload/main.dart';
import 'package:payload/config.dart';

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PayloadApp()));
    await tester.pumpAndSettle();
    expect(find.text(Config.appName.toUpperCase()), findsOneWidget);
  });
}
