import 'package:flutter_test/flutter_test.dart';
import 'package:tradex/main.dart';

void main() {
  testWidgets('Tradex smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TradexApp());
    expect(find.text('TRADEX'), findsOneWidget);
  });
}
