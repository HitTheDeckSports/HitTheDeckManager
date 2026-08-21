import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/filters/inventory_filter.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/widgets/inventory_filter_dialog.dart';

void main() {
  testWidgets('filter dialog exposes approved inventory filters', (
    tester,
  ) async {
    InventoryFilterCriteria? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showDialog<InventoryFilterCriteria>(
                    context: context,
                    builder: (context) => const InventoryFilterDialog(
                      initialCriteria: InventoryFilterCriteria(),
                      availableBrands: ['Combat', 'Easton'],
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventoryFilterDialog')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterCategory')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterBrand')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterCondition')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterStatus')), findsOneWidget);
    expect(
      find.byKey(const Key('inventoryFilterPurchaseFrom')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventoryFilterPurchaseTo')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterMinCost')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterMaxCost')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterMinAsking')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterMaxAsking')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterMinDays')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterMaxDays')), findsOneWidget);

    await tester.tap(find.byKey(const Key('inventoryFilterCategory')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bat').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventoryFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(result?.category, InventoryCategory.bat);
  });

  testWidgets('clear filters returns empty criteria', (tester) async {
    InventoryFilterCriteria? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showDialog<InventoryFilterCriteria>(
                    context: context,
                    builder: (context) => const InventoryFilterDialog(
                      initialCriteria: InventoryFilterCriteria(
                        status: InventoryStatus.sold,
                      ),
                      availableBrands: ['Combat'],
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventoryFilterClearButton')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isActive, isFalse);
  });
}
