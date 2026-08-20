import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/search/inventory_search.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';

void main() {
  const items = [
    InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.available,
      condition: InventoryCondition.likeNew,
      certification: 'BBCOR',
      lengthInches: 32,
      weightOunces: 29,
      notes: 'Omaha limited edition',
    ),
    InventoryItem(
      id: 'item-2',
      inventoryNumber: 'GLV-2608-0002',
      category: InventoryCategory.glove,
      brand: 'Rawlings',
      model: 'Heart of the Hide',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 12000,
      status: InventoryStatus.inactive,
      condition: InventoryCondition.good,
      gloveSizeInches: 11.5,
      handOrientation: 'Right Hand Throw',
    ),
    InventoryItem(
      id: 'item-3',
      inventoryNumber: 'BAT-2608-0003',
      category: InventoryCategory.bat,
      brand: 'Easton',
      model: 'Hype Fire',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 18000,
      status: InventoryStatus.broken,
      certification: 'USSSA',
      lengthInches: 31,
      weightOunces: 23,
      drop: -8,
    ),
  ];

  group('InventorySearch', () {
    test('returns all items for a blank query', () {
      final results = InventorySearch.filter(items, '');
      expect(results, hasLength(3));
    });

    test('matches inventory number', () {
      final results = InventorySearch.filter(items, '2608-0001');
      expect(results, hasLength(1));
      expect(results.single.id, 'item-1');
    });

    test('matches brand and model case-insensitively', () {
      final results = InventorySearch.filter(items, 'combat spec h1');
      expect(results, hasLength(1));
      expect(results.single.id, 'item-1');
    });

    test('matches category and status', () {
      final results = InventorySearch.filter(items, 'glove inactive');
      expect(results, hasLength(1));
      expect(results.single.id, 'item-2');
    });

    test('matches certification', () {
      final results = InventorySearch.filter(items, 'USSSA');
      expect(results, hasLength(1));
      expect(results.single.id, 'item-3');
    });

    test('matches notes', () {
      final results = InventorySearch.filter(items, 'Omaha');
      expect(results, hasLength(1));
      expect(results.single.id, 'item-1');
    });

    test('matches numeric item details', () {
      final results = InventorySearch.filter(items, '11.5');
      expect(results, hasLength(1));
      expect(results.single.id, 'item-2');
    });

    test('requires all query terms to match', () {
      final results = InventorySearch.filter(items, 'Combat USSSA');
      expect(results, isEmpty);
    });

    test('returns no items when nothing matches', () {
      final results = InventorySearch.filter(items, 'Louisville Atlas');
      expect(results, isEmpty);
    });
  });
}
