import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/forms/sell_inventory_form_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  group('SellInventoryFormController', () {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 32500,
      status: InventoryStatus.available,
    );

    test('starts with today as the sale date', () {
      final beforeBuild = DateTime.now();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(sellInventoryFormControllerProvider);

      final afterBuild = DateTime.now();

      expect(state.saleDate, isNotNull);
      expect(state.saleDate!.isBefore(beforeBuild), isFalse);
      expect(state.saleDate!.isAfter(afterBuild), isFalse);
      expect(state.selectedItem, isNull);
      expect(state.salePrice, isEmpty);
      expect(state.paymentMethod, PaymentMethod.cash);
    });

    test('selecting an item preloads its asking price', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        sellInventoryFormControllerProvider.notifier,
      );

      controller.setSelectedItem(item);

      final state = container.read(sellInventoryFormControllerProvider);

      expect(state.selectedItem, item);
      expect(state.salePrice, '325.00');
    });

    test(
      'selecting an item without an asking price leaves sale price blank',
      () {
        const itemWithoutPrice = InventoryItem(
          id: 'item-2',
          inventoryNumber: 'GLV-2608-0001',
          category: InventoryCategory.glove,
          brand: 'Wilson',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 15000,
          status: InventoryStatus.available,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final controller = container.read(
          sellInventoryFormControllerProvider.notifier,
        );

        controller.setSelectedItem(itemWithoutPrice);

        final state = container.read(sellInventoryFormControllerProvider);

        expect(state.selectedItem, itemWithoutPrice);
        expect(state.salePrice, isEmpty);
      },
    );

    test('updates sell-inventory form fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        sellInventoryFormControllerProvider.notifier,
      );

      final saleDate = DateTime(2026, 8, 3);

      controller.setSelectedItem(item);
      controller.setSalePrice('350.00');
      controller.setSaleDate(saleDate);
      controller.setPaymentMethod(PaymentMethod.zelle);
      controller.setBuyerContactId('contact-1');
      controller.setNotes('Sold at tournament.');

      final state = container.read(sellInventoryFormControllerProvider);

      expect(state.selectedItem, item);
      expect(state.salePrice, '350.00');
      expect(state.saleDate, saleDate);
      expect(state.paymentMethod, PaymentMethod.zelle);
      expect(state.buyerContactId, 'contact-1');
      expect(state.notes, 'Sold at tournament.');
      expect(state.profitCents, 15000);
    });

    test('returns null and keeps state when submission is invalid', () async {
      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: [item],
      );

      final transactionRepository = InMemoryTransactionRepository();

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
      );

      addTearDown(container.dispose);
      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);

      final controller = container.read(
        sellInventoryFormControllerProvider.notifier,
      );

      controller.setSelectedItem(item);
      controller.setSalePrice('invalid');
      controller.setSaleDate(DateTime(2026, 8, 3));

      final result = await controller.submit();

      expect(result, isNull);

      final state = container.read(sellInventoryFormControllerProvider);

      expect(state.selectedItem, item);
      expect(state.salePrice, 'invalid');

      final storedItem = await inventoryRepository.getInventoryItem('item-1');

      expect(storedItem?.status, InventoryStatus.available);
      expect(await transactionRepository.getSales(), isEmpty);
    });

    test('completes a sale and resets after successful submission', () async {
      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: [item],
      );

      final transactionRepository = InMemoryTransactionRepository();

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
      );

      addTearDown(container.dispose);
      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);

      final controller = container.read(
        sellInventoryFormControllerProvider.notifier,
      );

      final saleDate = DateTime(2026, 8, 3);

      controller.setSelectedItem(item);
      controller.setSalePrice('325.00');
      controller.setSaleDate(saleDate);
      controller.setPaymentMethod(PaymentMethod.card);
      controller.setBuyerContactId('contact-1');
      controller.setNotes('Completed sale.');

      final result = await controller.submit();

      expect(result, isNotNull);
      expect(result?.sale.id, isNotNull);
      expect(result?.sale.inventoryItemId, 'item-1');
      expect(result?.sale.salePriceCents, 32500);
      expect(result?.sale.saleDate, saleDate);
      expect(result?.sale.paymentMethod, PaymentMethod.card);
      expect(result?.sale.buyerContactId, 'contact-1');
      expect(result?.sale.notes, 'Completed sale.');
      expect(result?.sale.profitCents, 12500);
      expect(result?.soldItem.status, InventoryStatus.sold);

      final storedItem = await inventoryRepository.getInventoryItem('item-1');

      final storedSale = await transactionRepository.getSaleForInventoryItem(
        'item-1',
      );

      expect(storedItem?.status, InventoryStatus.sold);
      expect(storedSale, result?.sale);

      final resetState = container.read(sellInventoryFormControllerProvider);

      expect(resetState.selectedItem, isNull);
      expect(resetState.salePrice, isEmpty);
      expect(resetState.saleDate, isNotNull);
      expect(resetState.paymentMethod, PaymentMethod.cash);
      expect(resetState.buyerContactId, isNull);
      expect(resetState.notes, isEmpty);
    });

    test('reset restores the default form state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        sellInventoryFormControllerProvider.notifier,
      );

      controller.setSelectedItem(item);
      controller.setSalePrice('350.00');
      controller.setPaymentMethod(PaymentMethod.paypal);
      controller.setBuyerContactId('contact-1');
      controller.setNotes('Temporary notes.');

      controller.reset();

      final state = container.read(sellInventoryFormControllerProvider);

      expect(state.selectedItem, isNull);
      expect(state.salePrice, isEmpty);
      expect(state.saleDate, isNotNull);
      expect(state.paymentMethod, PaymentMethod.cash);
      expect(state.buyerContactId, isNull);
      expect(state.notes, isEmpty);
    });
  });
}
