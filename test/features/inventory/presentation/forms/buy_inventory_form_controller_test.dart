import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_controller.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_state.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  group('BuyInventoryFormController', () {
    test('starts with the default form state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(buyInventoryFormControllerProvider);

      expect(state.category, InventoryCategory.bat);
      expect(state.brand, isEmpty);
      expect(state.acquisitionType, AcquisitionType.purchased);
      expect(state.acquisitionValue, isEmpty);
    });

    test('updates form fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        buyInventoryFormControllerProvider.notifier,
      );

      controller.setCategory(InventoryCategory.glove);
      controller.setBrand('Wilson');
      controller.setModel('A2000');
      controller.setAcquisitionType(AcquisitionType.traded);
      controller.setAcquisitionValue('175.00');
      controller.setCondition(InventoryCondition.good);
      controller.setGloveSizeInches('11.5');
      controller.setHandOrientation('Right Hand Throw');

      final state = container.read(buyInventoryFormControllerProvider);

      expect(state.category, InventoryCategory.glove);
      expect(state.brand, 'Wilson');
      expect(state.model, 'A2000');
      expect(state.acquisitionType, AcquisitionType.traded);
      expect(state.acquisitionValue, '175.00');
      expect(state.condition, InventoryCondition.good);
      expect(state.gloveSizeInches, '11.5');
      expect(state.handOrientation, 'Right Hand Throw');
    });
    test('initializes the form from an existing inventory item', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final existingItem = InventoryItem(
        id: 'item-1',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 20000,
        condition: InventoryCondition.likeNew,
        status: InventoryStatus.inactive,
        purchaseDate: DateTime(2026, 8, 2),
        newValueCents: 49999,
        askingPriceCents: 32500,
        minimumPriceCents: 27500,
        notes: 'Original notes.',
        lengthInches: 32,
        weightOunces: 29,
        drop: -3,
        certification: 'BBCOR',
      );

      final controller = container.read(
        buyInventoryFormControllerProvider.notifier,
      );

      controller.initializeFromItem(existingItem);

      final state = container.read(buyInventoryFormControllerProvider);

      expect(state.category, InventoryCategory.bat);
      expect(state.brand, 'Combat');
      expect(state.model, 'Spec H1');
      expect(state.acquisitionType, AcquisitionType.traded);
      expect(state.acquisitionValue, '200.00');
      expect(state.condition, InventoryCondition.likeNew);
      expect(state.purchaseDate, DateTime(2026, 8, 2));
      expect(state.newValue, '499.99');
      expect(state.askingPrice, '325.00');
      expect(state.minimumPrice, '275.00');
      expect(state.notes, 'Original notes.');
      expect(state.lengthInches, '32');
      expect(state.weightOunces, '29');
      expect(state.drop, '-3');
      expect(state.certification, 'BBCOR');
    });

    test('returns null and keeps state when submission is invalid', () async {
      final repository = InMemoryInventoryRepository();

      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final controller = container.read(
        buyInventoryFormControllerProvider.notifier,
      );

      controller.setBrand('');
      controller.setAcquisitionValue('invalid');

      final result = await controller.submit();

      expect(result, isNull);

      final state = container.read(buyInventoryFormControllerProvider);

      expect(state.brand, isEmpty);
      expect(state.acquisitionValue, 'invalid');

      final inventory = await repository.getInventory();
      expect(inventory, isEmpty);
    });

    test('creates an item and resets after successful submission', () async {
      final repository = InMemoryInventoryRepository();

      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final controller = container.read(
        buyInventoryFormControllerProvider.notifier,
      );

      controller.setCategory(InventoryCategory.bat);
      controller.setBrand('Combat');
      controller.setModel('Spec H1');
      controller.setAcquisitionValue('200.00');
      controller.setAskingPrice('325.00');
      controller.setLengthInches('32');
      controller.setWeightOunces('29');

      final savedItem = await controller.submit();

      expect(savedItem, isNotNull);
      expect(savedItem?.id, isNotNull);
      expect(savedItem?.inventoryNumber, startsWith('BAT-'));
      expect(savedItem?.brand, 'Combat');
      expect(savedItem?.model, 'Spec H1');
      expect(savedItem?.acquisitionValueCents, 20000);
      expect(savedItem?.askingPriceCents, 32500);

      final inventory = await repository.getInventory();

      expect(inventory, contains(savedItem));
      expect(inventory, hasLength(1));

      final resetState = container.read(buyInventoryFormControllerProvider);

      expect(resetState, isA<BuyInventoryFormState>());
      expect(resetState.brand, isEmpty);
      expect(resetState.acquisitionValue, isEmpty);
      expect(resetState.category, InventoryCategory.bat);
    });
    test(
      'updates an existing item and preserves its identity and status',
      () async {
        const existingItem = InventoryItem(
          id: 'item-1',
          inventoryNumber: 'BAT-2608-0001',
          category: InventoryCategory.bat,
          brand: 'Combat',
          model: 'Spec H1',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 20000,
          askingPriceCents: 32500,
          status: InventoryStatus.inactive,
          lengthInches: 32,
          weightOunces: 29,
          drop: -3,
          certification: 'BBCOR',
        );

        final repository = InMemoryInventoryRepository(
          initialItems: [existingItem],
        );

        final container = ProviderContainer(
          overrides: [
            inventoryRepositoryProvider.overrideWithValue(repository),
          ],
        );

        addTearDown(container.dispose);
        addTearDown(repository.dispose);

        final controller = container.read(
          buyInventoryFormControllerProvider.notifier,
        );

        controller.initializeFromItem(existingItem);
        controller.setBrand('Combat Sports');
        controller.setModel('Updated Spec H1');
        controller.setAskingPrice('350.00');
        controller.setWeightOunces('27');
        controller.setNotes('Updated notes.');

        final updatedItem = await controller.submitUpdate(existingItem);

        expect(updatedItem, isNotNull);
        expect(updatedItem?.id, 'item-1');
        expect(updatedItem?.inventoryNumber, 'BAT-2608-0001');
        expect(updatedItem?.status, InventoryStatus.inactive);
        expect(updatedItem?.brand, 'Combat Sports');
        expect(updatedItem?.model, 'Updated Spec H1');
        expect(updatedItem?.askingPriceCents, 35000);
        expect(updatedItem?.lengthInches, 32);
        expect(updatedItem?.weightOunces, 27);
        expect(updatedItem?.drop, -5);
        expect(updatedItem?.notes, 'Updated notes.');

        final repositoryItem = await repository.getInventoryItem('item-1');

        expect(repositoryItem, updatedItem);

        final resetState = container.read(buyInventoryFormControllerProvider);

        expect(resetState.category, InventoryCategory.bat);
        expect(resetState.brand, isEmpty);
        expect(resetState.model, isEmpty);
        expect(resetState.acquisitionValue, isEmpty);
      },
    );

    test('reset restores the default form state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        buyInventoryFormControllerProvider.notifier,
      );

      controller.setCategory(InventoryCategory.helmet);
      controller.setBrand('Easton');
      controller.setAcquisitionValue('50.00');

      controller.reset();

      final state = container.read(buyInventoryFormControllerProvider);

      expect(state.category, InventoryCategory.bat);
      expect(state.brand, isEmpty);
      expect(state.acquisitionValue, isEmpty);
    });
  });
}
