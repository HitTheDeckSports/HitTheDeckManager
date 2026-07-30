import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/shared/presentation/widgets/app_page.dart';

void main() {
  testWidgets('AppPage displays its header and content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPage(
            title: 'Inventory',
            subtitle: 'Manage available equipment.',
            child: Text('Inventory content'),
          ),
        ),
      ),
    );

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Manage available equipment.'), findsOneWidget);
    expect(find.text('Inventory content'), findsOneWidget);
  });

  testWidgets('AppPage displays optional actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPage(
            title: 'Contacts',
            actions: [
              FilledButton(onPressed: () {}, child: const Text('Add Contact')),
            ],
            child: const Text('Contacts content'),
          ),
        ),
      ),
    );

    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Add Contact'), findsOneWidget);
    expect(find.text('Contacts content'), findsOneWidget);
  });
}
