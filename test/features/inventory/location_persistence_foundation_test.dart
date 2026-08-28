import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/mappers/firestore_inventory_mapper.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_controller.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_state.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  group('Inventory location persistence foundation', () {
    test('InventoryItem copyWith preserves and can clear locationId', () {
      const item = InventoryItem(
        id: 'item-1',
        category: InventoryCategory.bat,
        brand: 'Rawlings',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
        locationId: 'location-main-rack',
      );

      expect(
        item.copyWith(brand: 'Rawlings Updated').locationId,
        'location-main-rack',
      );
      expect(item.copyWith(locationId: null).locationId, isNull);
    });

    test('Firestore mapper writes locationId', () {
      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Rawlings',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
        locationId: 'location-facility-a',
      );

      final data = FirestoreInventoryMapper.toFirestore(item);

      expect(data['locationId'], 'location-facility-a');
    });

    test('form state carries location from and back to InventoryItem', () {
      const item = InventoryItem(
        id: 'item-2',
        inventoryNumber: 'BAT-2608-0100',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        locationId: 'location-storage',
      );

      final state = BuyInventoryFormState.fromInventoryItem(item);
      final rebuilt = state.toInventoryItem();

      expect(state.locationId, 'location-storage');
      expect(rebuilt, isNotNull);
      expect(rebuilt?.locationId, 'location-storage');
    });

    test('editing an existing item preserves its assigned location', () async {
      const existingItem = InventoryItem(
        id: 'item-3',
        inventoryNumber: 'BAT-2608-0101',
        category: InventoryCategory.bat,
        brand: 'Easton',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 15000,
        askingPriceCents: 25000,
        locationId: 'location-display-1',
      );

      final repository = InMemoryInventoryRepository(
        initialItems: [existingItem],
      );
      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final controller = container.read(
        buyInventoryFormControllerProvider.notifier,
      );

      controller.initializeFromItem(existingItem);
      controller.setBrand('Easton Updated');

      final updatedItem = await controller.submitUpdate(existingItem);

      expect(updatedItem, isNotNull);
      expect(updatedItem?.brand, 'Easton Updated');
      expect(updatedItem?.locationId, 'location-display-1');

      final stored = await repository.getInventoryItem('item-3');
      expect(stored?.locationId, 'location-display-1');
    });

    test('location setter supports assignment and Unassigned', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        buyInventoryFormControllerProvider.notifier,
      );

      controller.setLocationId('location-repair-area');
      expect(
        container.read(buyInventoryFormControllerProvider).locationId,
        'location-repair-area',
      );

      controller.setLocationId(null);
      expect(
        container.read(buyInventoryFormControllerProvider).locationId,
        isNull,
      );
    });
  });
}
