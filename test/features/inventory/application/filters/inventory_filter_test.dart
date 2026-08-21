import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/filters/inventory_filter.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';

void main() {
  final items = [
    InventoryItem(
      id: 'bat-1',
      category: InventoryCategory.bat,
      brand: 'Easton',
      model: 'Hype Fire',
      condition: InventoryCondition.newItem,
      status: InventoryStatus.available,
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 35000,
      purchaseDate: DateTime(2026, 7, 1),
    ),
    InventoryItem(
      id: 'glove-1',
      category: InventoryCategory.glove,
      brand: 'Rawlings',
      model: 'Heart of the Hide',
      condition: InventoryCondition.likeNew,
      status: InventoryStatus.sold,
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 10000,
      askingPriceCents: 22500,
      purchaseDate: DateTime(2026, 8, 10),
    ),
    const InventoryItem(
      id: 'bat-2',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      condition: InventoryCondition.good,
      status: InventoryStatus.inactive,
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 15000,
    ),
  ];

  test('empty criteria returns every item', () {
    final results = InventoryFilter.apply(
      items,
      const InventoryFilterCriteria(),
      asOf: DateTime(2026, 8, 21),
    );

    expect(results, hasLength(3));
  });

  test('filters by category brand condition and status', () {
    final results = InventoryFilter.apply(
      items,
      const InventoryFilterCriteria(
        category: InventoryCategory.bat,
        brand: 'Easton',
        condition: InventoryCondition.newItem,
        status: InventoryStatus.available,
      ),
      asOf: DateTime(2026, 8, 21),
    );

    expect(results.map((item) => item.id), ['bat-1']);
  });

  test('filters by inclusive purchase date range', () {
    final results = InventoryFilter.apply(
      items,
      InventoryFilterCriteria(
        purchaseDateFrom: DateTime(2026, 8, 1),
        purchaseDateTo: DateTime(2026, 8, 10),
      ),
      asOf: DateTime(2026, 8, 21),
    );

    expect(results.map((item) => item.id), ['glove-1']);
  });

  test('filters by acquisition cost range', () {
    final results = InventoryFilter.apply(
      items,
      const InventoryFilterCriteria(
        minimumAcquisitionValueCents: 12000,
        maximumAcquisitionValueCents: 20000,
      ),
      asOf: DateTime(2026, 8, 21),
    );

    expect(results.map((item) => item.id), ['bat-1', 'bat-2']);
  });

  test('filters by asking price range and excludes missing asking prices', () {
    final results = InventoryFilter.apply(
      items,
      const InventoryFilterCriteria(
        minimumAskingPriceCents: 30000,
        maximumAskingPriceCents: 40000,
      ),
      asOf: DateTime(2026, 8, 21),
    );

    expect(results.map((item) => item.id), ['bat-1']);
  });

  test('filters by days in inventory and excludes missing purchase dates', () {
    final results = InventoryFilter.apply(
      items,
      const InventoryFilterCriteria(
        minimumDaysInInventory: 30,
        maximumDaysInInventory: 60,
      ),
      asOf: DateTime(2026, 8, 21),
    );

    expect(results.map((item) => item.id), ['bat-1']);
  });

  test('multiple criteria combine with AND semantics', () {
    final results = InventoryFilter.apply(
      items,
      const InventoryFilterCriteria(
        category: InventoryCategory.glove,
        status: InventoryStatus.sold,
        maximumAcquisitionValueCents: 12000,
      ),
      asOf: DateTime(2026, 8, 21),
    );

    expect(results.map((item) => item.id), ['glove-1']);
  });

  test('activeCount reflects configured filters', () {
    const criteria = InventoryFilterCriteria(
      category: InventoryCategory.bat,
      status: InventoryStatus.available,
      minimumDaysInInventory: 10,
    );

    expect(criteria.isActive, isTrue);
    expect(criteria.activeCount, 3);
  });
}
