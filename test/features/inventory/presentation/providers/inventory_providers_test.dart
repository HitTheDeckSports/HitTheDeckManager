import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  group('Inventory providers', () {
    test('repository provider returns an inventory repository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(inventoryRepositoryProvider);

      expect(repository, isA<InventoryRepository>());
      expect(repository, isA<InMemoryInventoryRepository>());
    });

    test('inventory items provider returns repository items', () async {
      const item = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      final repository = InMemoryInventoryRepository(initialItems: [item]);

      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final inventory = await container.read(inventoryItemsProvider.future);

      expect(inventory, contains(item));
      expect(inventory, hasLength(1));
    });
  });
}
