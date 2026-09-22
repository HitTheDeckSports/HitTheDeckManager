import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/filters/inventory_filter.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_location.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/widgets/inventory_filter_dialog.dart';

void main() {
  testWidgets(
    'filter dialog uses compact summary rows and returns selections',
    (tester) async {
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
                        availableLocations: [
                          InventoryLocation(id: 'showroom', name: 'Showroom'),
                          InventoryLocation(id: 'warehouse', name: 'Warehouse'),
                        ],
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
      expect(
        find.byKey(const Key('inventoryFilterCategoryRow')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventoryFilterBrandRow')), findsOneWidget);
      expect(
        find.byKey(const Key('inventoryFilterConditionRow')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventoryFilterStatusRow')), findsOneWidget);
      expect(
        find.byKey(const Key('inventoryFilterLocationRow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventoryFilterPurchaseDateRow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventoryFilterCostRangeRow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventoryFilterAskingPriceRow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventoryFilterDaysInInventoryRow')),
        findsOneWidget,
      );
      expect(find.text('Any'), findsWidgets);

      await tester.tap(find.byKey(const Key('inventoryFilterCategoryRow')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('inventoryFilterCategory-InventoryCategory.bat'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('inventoryFilterCategory-InventoryCategory.glove'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('inventoryFilterCategorySheetApply')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventoryFilterBrandRow')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('inventoryFilterBrand-Combat')),
      );
      await tester.tap(
        find.byKey(const ValueKey('inventoryFilterBrand-Easton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('inventoryFilterBrandSheetApply')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventoryFilterConditionRow')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('inventoryFilterCondition-InventoryCondition.newItem'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('inventoryFilterCondition-InventoryCondition.likeNew'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('inventoryFilterConditionSheetApply')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('inventoryFilterConditionRow')),
          matching: find.text('2 selected'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('inventoryFilterStatusRow')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('inventoryFilterStatus-InventoryStatus.available'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('inventoryFilterStatus-InventoryStatus.inactive'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('inventoryFilterStatusSheetApply')),
      );
      await tester.pumpAndSettle();
      for (final rowKey in const [
        'inventoryFilterCategoryRow',
        'inventoryFilterBrandRow',
        'inventoryFilterConditionRow',
        'inventoryFilterStatusRow',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(Key(rowKey)),
            matching: find.text('2 selected'),
          ),
          findsOneWidget,
        );
      }

      await tester.tap(find.byKey(const Key('inventoryFilterLocationRow')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventoryFilterLocationUnassigned')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('inventoryFilterLocation-showroom')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('inventoryFilterLocation-showroom')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('inventoryFilterLocationSheetApply')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Showroom'), findsWidgets);

      await tester.tap(find.byKey(const Key('inventoryFilterApplyButton')));
      await tester.pumpAndSettle();

      expect(result?.selectedCategories, {
        InventoryCategory.bat,
        InventoryCategory.glove,
      });
      expect(result?.selectedBrands, {'Combat', 'Easton'});
      expect(result?.selectedConditions, {
        InventoryCondition.newItem,
        InventoryCondition.likeNew,
      });
      expect(result?.selectedStatuses, {
        InventoryStatus.available,
        InventoryStatus.inactive,
      });
      expect(result?.selectedLocationIds, {'showroom'});
      expect(result?.includeUnassignedLocation, isFalse);
    },
  );

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
                        selectedCategories: {InventoryCategory.bat},
                        selectedBrands: {'Combat'},
                        selectedConditions: {InventoryCondition.good},
                        selectedStatuses: {InventoryStatus.sold},
                        selectedLocationIds: {'showroom'},
                        includeUnassignedLocation: true,
                      ),
                      availableBrands: ['Combat'],
                      availableLocations: [
                        InventoryLocation(id: 'showroom', name: 'Showroom'),
                      ],
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
    expect(result!.selectedCategories, isEmpty);
    expect(result!.selectedBrands, isEmpty);
    expect(result!.selectedConditions, isEmpty);
    expect(result!.selectedStatuses, isEmpty);
    expect(result!.selectedLocationIds, isEmpty);
    expect(result!.includeUnassignedLocation, isFalse);
  });
}
