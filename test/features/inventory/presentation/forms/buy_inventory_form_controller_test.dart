import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
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
