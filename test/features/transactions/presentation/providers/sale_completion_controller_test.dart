import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/sale_completion_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  group('SaleCompletionController', () {
    test('creates a sale and marks the inventory item as sold', () async {
      const item = InventoryItem(
        id: 'item-1',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        status: InventoryStatus.available,
      );

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

      final sale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      final result = await container
          .read(saleCompletionControllerProvider.notifier)
          .completeSale(item: item, sale: sale);

      expect(result.sale.id, isNotNull);
      expect(result.sale.inventoryItemId, 'item-1');
      expect(result.sale.salePriceCents, 32500);
      expect(result.soldItem.status, InventoryStatus.sold);

      final storedItem = await inventoryRepository.getInventoryItem('item-1');

      final storedSale = await transactionRepository.getSaleForInventoryItem(
        'item-1',
      );

      expect(storedItem?.status, InventoryStatus.sold);
      expect(storedSale, result.sale);

      expect(
        container.read(saleCompletionControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('rejects a sale for inventory that is not available', () async {
      const item = InventoryItem(
        id: 'item-1',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        status: InventoryStatus.inactive,
      );

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

      final sale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      await expectLater(
        () => container
            .read(saleCompletionControllerProvider.notifier)
            .completeSale(item: item, sale: sale),
        throwsA(isA<StateError>()),
      );

      final storedItem = await inventoryRepository.getInventoryItem('item-1');

      expect(storedItem?.status, InventoryStatus.inactive);
      expect(await transactionRepository.getSales(), isEmpty);
      expect(container.read(saleCompletionControllerProvider).hasError, isTrue);
    });

    test('restores inventory status when sale creation fails', () async {
      const item = InventoryItem(
        id: 'item-1',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        status: InventoryStatus.available,
      );

      final existingSale = SaleTransaction(
        id: 'sale-1',
        inventoryItemId: 'item-1',
        salePriceCents: 30000,
        saleDate: DateTime(2026, 8, 2),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: [item],
      );

      final transactionRepository = InMemoryTransactionRepository(
        initialSales: [existingSale],
      );

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

      final duplicateSale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.card,
        acquisitionValueCents: 20000,
      );

      await expectLater(
        () => container
            .read(saleCompletionControllerProvider.notifier)
            .completeSale(item: item, sale: duplicateSale),
        throwsA(isA<DuplicateException>()),
      );

      final storedItem = await inventoryRepository.getInventoryItem('item-1');

      expect(storedItem?.status, InventoryStatus.available);

      final sales = await transactionRepository.getSales();

      expect(sales, hasLength(1));
      expect(sales.single, existingSale);
      expect(container.read(saleCompletionControllerProvider).hasError, isTrue);
    });
  });
}
