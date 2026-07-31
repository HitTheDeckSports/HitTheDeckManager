import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';

void main() {
  group('InMemoryInventoryRepository', () {
    test('creates an item and assigns an id', () async {
      final repository = InMemoryInventoryRepository();

      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      final savedItem = await repository.createInventoryItem(item);
      final inventory = await repository.getInventory();

      expect(savedItem.id, isNotNull);
      expect(savedItem.inventoryNumber, isNotNull);
      expect(savedItem.inventoryNumber, startsWith('BAT-'));
      expect(inventory, contains(savedItem));
    });

    test('returns an item by id', () async {
      final repository = InMemoryInventoryRepository();

      const item = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.glove,
        brand: 'Wilson',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 15000,
      );

      await repository.createInventoryItem(item);

      final result = await repository.getInventoryItem('item-1');

      expect(result, equals(item));
    });

    test('returns null when an item does not exist', () async {
      final repository = InMemoryInventoryRepository();

      final result = await repository.getInventoryItem('missing-item');

      expect(result, isNull);
    });

    test('updates an existing item', () async {
      final repository = InMemoryInventoryRepository();

      const item = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        askingPriceCents: 30000,
      );

      await repository.createInventoryItem(item);

      final updatedItem = item.copyWith(
        askingPriceCents: 32500,
        status: InventoryStatus.sold,
      );

      final result = await repository.updateInventoryItem(updatedItem);
      final storedItem = await repository.getInventoryItem('item-1');

      expect(result.askingPriceCents, 32500);
      expect(result.status, InventoryStatus.sold);
      expect(storedItem, equals(updatedItem));
    });

    test('deletes an existing item', () async {
      final repository = InMemoryInventoryRepository();

      const item = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.helmet,
        brand: 'Easton',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 5000,
      );

      await repository.createInventoryItem(item);
      await repository.deleteInventoryItem('item-1');

      final result = await repository.getInventoryItem('item-1');

      expect(result, isNull);
    });

    test('rejects invalid items', () async {
      final repository = InMemoryInventoryRepository();

      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: '',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: -100,
      );

      expect(
        () => repository.createInventoryItem(item),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate ids', () async {
      final repository = InMemoryInventoryRepository();

      const first = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      const second = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.glove,
        brand: 'Wilson',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 15000,
      );

      await repository.createInventoryItem(first);

      expect(
        () => repository.createInventoryItem(second),
        throwsA(isA<DuplicateException>()),
      );
    });

    test('rejects updating an item without an id', () async {
      final repository = InMemoryInventoryRepository();

      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      expect(
        () => repository.updateInventoryItem(item),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects deleting an unknown item', () async {
      final repository = InMemoryInventoryRepository();

      expect(
        () => repository.deleteInventoryItem('missing-item'),
        throwsA(isA<NotFoundException>()),
      );
    });
    test('assigns sequential inventory numbers when creating items', () async {
      final repository = InMemoryInventoryRepository();

      final first = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        purchaseDate: DateTime(2026, 7, 31),
      );

      final second = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 22000,
        purchaseDate: DateTime(2026, 7, 31),
      );

      final firstSaved = await repository.createInventoryItem(first);
      final secondSaved = await repository.createInventoryItem(second);

      expect(firstSaved.inventoryNumber, 'BAT-2607-0001');
      expect(secondSaved.inventoryNumber, 'BAT-2607-0002');
    });
  });
}
