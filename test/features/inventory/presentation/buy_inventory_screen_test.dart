import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/buy_inventory_screen.dart';

void main() {
  Widget createTestApp() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: BuyInventoryScreen(),
        ),
      ),
    );
  }

  testWidgets('displays the initial Buy Inventory fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Buy Inventory'), findsOneWidget);
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Acquisition Type'), findsOneWidget);
    expect(find.text('Acquisition Value'), findsOneWidget);
    expect(find.text('Validate Information'), findsOneWidget);

    expect(
      find.byKey(const Key('buyInventoryCategoryField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('buyInventoryBrandField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('buyInventoryModelField')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('buyInventoryAcquisitionTypeField'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('buyInventoryAcquisitionValueField'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('buyInventoryValidateButton')),
      findsOneWidget,
    );
  });

  testWidgets('shows required-field errors for blank submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final validateButton = find.byKey(
      const Key('buyInventoryValidateButton'),
    );

    await tester.ensureVisible(validateButton);
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Brand is required.'), findsOneWidget);
    expect(
      find.text('Acquisition value is required.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error for invalid acquisition value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(
        const Key('buyInventoryAcquisitionValueField'),
      ),
      'invalid',
    );

    final validateButton = find.byKey(
      const Key('buyInventoryValidateButton'),
    );

    await tester.ensureVisible(validateButton);
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid Acquisition value.'),
      findsOneWidget,
    );
  });

  testWidgets('shows confirmation when basic information is valid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryModelField')),
      'Spec H1',
    );

    await tester.enterText(
      find.byKey(
        const Key('buyInventoryAcquisitionValueField'),
      ),
      '200.00',
    );

    final validateButton = find.byKey(
      const Key('buyInventoryValidateButton'),
    );

    await tester.ensureVisible(validateButton);
    await tester.tap(validateButton);
    await tester.pump();

    expect(
      find.text('Basic inventory information is valid.'),
      findsOneWidget,
    );
    expect(find.text('Brand is required.'), findsNothing);
    expect(
      find.text('Acquisition value is required.'),
      findsNothing,
    );
  });
}