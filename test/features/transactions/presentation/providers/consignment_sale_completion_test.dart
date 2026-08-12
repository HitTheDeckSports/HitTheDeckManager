import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/sale_completion_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  const item = InventoryItem(
    id: 'item-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    acquisitionType: AcquisitionType.consignment,
    acquisitionValueCents: 0,
    status: InventoryStatus.available,
  );

  test(
    'consignment sale records payout as cost and commission as profit',
    () async {
      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: const [item],
      );
      final transactionRepository = InMemoryTransactionRepository(
        initialConsignments: [
          ConsignmentTransaction(
            id: 'consignment-a',
            inventoryItemId: 'item-a',
            consignmentDate: DateTime(2026, 8, 7),
            commissionCents: 5000,
          ),
        ],
      );
      final dealRepository = InMemoryDealRepository();

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(dealRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          dealRepositoryProvider.overrideWithValue(dealRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(saleCompletionControllerProvider.future);

      final result = await container
          .read(saleCompletionControllerProvider.notifier)
          .completeSale(
            item: item,
            sale: SaleTransaction(
              inventoryItemId: 'item-a',
              salePriceCents: 20000,
              saleDate: DateTime(2026, 8, 8),
              paymentMethod: PaymentMethod.cash,
              acquisitionValueCents: 0,
            ),
          );

      final savedSale = result.sale;
      final consignment = await transactionRepository
          .getConsignmentForInventoryItem('item-a');

      expect(savedSale.salePriceCents, 20000);
      expect(savedSale.acquisitionValueCents, 15000);
      expect(savedSale.profitCents, 5000);
      expect(consignment?.saleTransactionId, savedSale.id);
      expect(
        consignment?.consignorPayoutCentsForSale(savedSale.salePriceCents),
        15000,
      );
    },
  );

  test('consigned inventory cannot sell without agreement', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository();
    final dealRepository = InMemoryDealRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
        dealRepositoryProvider.overrideWithValue(dealRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(saleCompletionControllerProvider.future);

    await expectLater(
      container
          .read(saleCompletionControllerProvider.notifier)
          .completeSale(
            item: item,
            sale: SaleTransaction(
              inventoryItemId: 'item-a',
              salePriceCents: 20000,
              saleDate: DateTime(2026, 8, 8),
              paymentMethod: PaymentMethod.cash,
              acquisitionValueCents: 0,
            ),
          ),
      throwsA(isA<StateError>()),
    );

    expect(await transactionRepository.getSales(), isEmpty);
    expect(
      (await inventoryRepository.getInventoryItem('item-a'))?.status,
      InventoryStatus.available,
    );
  });
}
