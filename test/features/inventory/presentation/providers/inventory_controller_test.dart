import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_controller.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';

void main() {
  group('InventoryController', () {
    test(
      'creates an inventory item and refreshes the inventory list',
      () async {
        final repository = InMemoryInventoryRepository();

        final container = ProviderContainer(
          overrides: [
            inventoryRepositoryProvider.overrideWithValue(repository),
          ],
        );

        final inventoryEmissions = <List<InventoryItem>>[];

        final inventorySubscription = container.listen(inventoryItemsProvider, (
          previous,
          next,
        ) {
          next.whenData(inventoryEmissions.add);
        }, fireImmediately: true);

        addTearDown(inventorySubscription.close);
        addTearDown(container.dispose);
        addTearDown(repository.dispose);

        await Future<void>.delayed(Duration.zero);

        const item = InventoryItem(
          category: InventoryCategory.bat,
          brand: 'Combat',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 20000,
        );

        final savedItem = await container
            .read(inventoryControllerProvider.notifier)
            .createItem(item);

        await Future<void>.delayed(Duration.zero);

        expect(savedItem.id, isNotNull);
        expect(inventoryEmissions.first, isEmpty);
        expect(inventoryEmissions.last, contains(savedItem));
        expect(
          container.read(inventoryControllerProvider),
          const AsyncData<void>(null),
        );
      },
    );

    test('updates an existing inventory item', () async {
      const original = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        askingPriceCents: 30000,
      );

      final repository = InMemoryInventoryRepository(initialItems: [original]);

      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final updated = original.copyWith(
        askingPriceCents: 32500,
        status: InventoryStatus.sold,
      );

      final result = await container
          .read(inventoryControllerProvider.notifier)
          .updateItem(updated);

      final storedItem = await repository.getInventoryItem('item-1');

      expect(result, equals(updated));
      expect(storedItem, equals(updated));
      expect(storedItem?.askingPriceCents, 32500);
      expect(storedItem?.status, InventoryStatus.sold);
    });

    test(
      'updates inventory status while preserving all other item data',
      () async {
        final original = InventoryItem(
          id: 'item-1',
          inventoryNumber: 'BAT-2608-0001',
          category: InventoryCategory.bat,
          brand: 'Combat',
          model: 'Spec H1',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 20000,
          condition: InventoryCondition.likeNew,
          status: InventoryStatus.available,
          purchaseDate: DateTime(2026, 8, 3),
          newValueCents: 49999,
          askingPriceCents: 32500,
          minimumPriceCents: 27500,
          notes: 'Limited-edition bat.',
          lengthInches: 32,
          weightOunces: 29,
          drop: -3,
          certification: 'BBCOR',
        );

        final repository = InMemoryInventoryRepository(
          initialItems: [original],
        );

        final container = ProviderContainer(
          overrides: [
            inventoryRepositoryProvider.overrideWithValue(repository),
          ],
        );

        addTearDown(container.dispose);
        addTearDown(repository.dispose);

        final controller = container.read(inventoryControllerProvider.notifier);

        final inactiveItem = await controller.updateStatus(
          item: original,
          status: InventoryStatus.inactive,
        );

        expect(inactiveItem.status, InventoryStatus.inactive);
        expect(inactiveItem.id, original.id);
        expect(inactiveItem.inventoryNumber, original.inventoryNumber);
        expect(inactiveItem.category, original.category);
        expect(inactiveItem.brand, original.brand);
        expect(inactiveItem.model, original.model);
        expect(inactiveItem.acquisitionType, original.acquisitionType);
        expect(
          inactiveItem.acquisitionValueCents,
          original.acquisitionValueCents,
        );
        expect(inactiveItem.condition, original.condition);
        expect(inactiveItem.purchaseDate, original.purchaseDate);
        expect(inactiveItem.newValueCents, original.newValueCents);
        expect(inactiveItem.askingPriceCents, original.askingPriceCents);
        expect(inactiveItem.minimumPriceCents, original.minimumPriceCents);
        expect(inactiveItem.notes, original.notes);
        expect(inactiveItem.lengthInches, original.lengthInches);
        expect(inactiveItem.weightOunces, original.weightOunces);
        expect(inactiveItem.drop, original.drop);
        expect(inactiveItem.certification, original.certification);

        final availableItem = await controller.updateStatus(
          item: inactiveItem,
          status: InventoryStatus.available,
        );

        expect(availableItem.status, InventoryStatus.available);

        final brokenItem = await controller.updateStatus(
          item: availableItem,
          status: InventoryStatus.broken,
        );

        expect(brokenItem.status, InventoryStatus.broken);

        final storedItem = await repository.getInventoryItem('item-1');

        expect(storedItem, brokenItem);
        expect(storedItem?.status, InventoryStatus.broken);

        expect(
          container.read(inventoryControllerProvider),
          const AsyncData<void>(null),
        );
      },
    );

    test('deletes an inventory item', () async {
      const item = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.helmet,
        brand: 'Easton',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 5000,
      );

      final repository = InMemoryInventoryRepository(initialItems: [item]);

      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(inventoryControllerProvider.notifier)
          .deleteItem('item-1');

      final deletedItem = await repository.getInventoryItem('item-1');

      expect(deletedItem, isNull);
      expect(
        container.read(inventoryControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('exposes repository errors through controller state', () async {
      final repository = InMemoryInventoryRepository();

      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      const invalidItem = InventoryItem(
        category: InventoryCategory.bat,
        brand: '',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: -100,
      );

      await expectLater(
        () => container
            .read(inventoryControllerProvider.notifier)
            .createItem(invalidItem),
        throwsA(isA<ValidationException>()),
      );

      expect(container.read(inventoryControllerProvider).hasError, isTrue);
    });
  });
}
