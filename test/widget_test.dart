// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/app/app.dart';

void main() {
  testWidgets('app loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HitTheDeckApp());

    expect(find.text('Hit the Deck Manager'), findsOneWidget);
    expect(find.text('Inventory Management'), findsOneWidget);
    expect(find.text('Buy Inventory'), findsOneWidget);
    expect(find.text('Sell Inventory'), findsOneWidget);
  });
}
