import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  group('Inventory providers', () {
    test(
      'repository provider can be overridden with an inventory repository',
      () {
        final repository = InMemoryInventoryRepository();
        final container = ProviderContainer(
          overrides: [
            inventoryRepositoryProvider.overrideWithValue(repository),
          ],
        );

        addTearDown(container.dispose);
        addTearDown(repository.dispose);

        final resolvedRepository = container.read(inventoryRepositoryProvider);

        expect(resolvedRepository, isA<InventoryRepository>());
        expect(resolvedRepository, same(repository));
      },
    );

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

      final subscription = container.listen(
        inventoryItemsProvider,
        (previous, next) {},
      );

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final inventory = await container.read(inventoryItemsProvider.future);

      expect(inventory, contains(item));
      expect(inventory, hasLength(1));
    });

    test('inventory items provider emits repository changes', () async {
      final repository = InMemoryInventoryRepository();

      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );

      final emissions = <List<InventoryItem>>[];

      final subscription = container.listen(inventoryItemsProvider, (
        previous,
        next,
      ) {
        next.whenData(emissions.add);
      }, fireImmediately: true);

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      await Future<void>.delayed(Duration.zero);

      const item = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      await repository.createInventoryItem(item);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
      expect(emissions.first, isEmpty);
      expect(emissions.last, contains(item));
    });
  });
}
