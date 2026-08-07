import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/incoming_trade_item_draft.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/sale_completion_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  const soldItem = InventoryItem(
    id: 'sold-item',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 15000,
    status: InventoryStatus.available,
  );

  SaleTransaction sale() {
    return SaleTransaction(
      inventoryItemId: 'sold-item',
      salePriceCents: 20000,
      saleDate: DateTime(2026, 8, 6),
      paymentMethod: PaymentMethod.cash,
      buyerContactId: 'buyer-1',
      acquisitionValueCents: 15000,
    );
  }

  test('trade-in sale automatically creates a linked one-level Deal', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem],
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

    final result = await container
        .read(saleCompletionControllerProvider.notifier)
        .completeSale(
          item: soldItem,
          sale: sale(),
          tradeInItems: const [
            IncomingTradeItemDraft(
              category: InventoryCategory.bat,
              brand: 'Sample Bat B',
              acquisitionValueCents: 10000,
            ),
          ],
        );

    final trades = await transactionRepository.getTrades();
    final deals = await dealRepository.getDeals();

    expect(trades, hasLength(1));
    expect(deals, hasLength(1));
    expect(deals.single.parentSaleTransactionId, result.sale.id);
    expect(
      deals.single.childInventoryItemIds,
      trades.single.incomingInventoryItemIds,
    );
    expect(deals.single.childInventoryItemIds, hasLength(1));
  });

  test('normal sale does not create a Deal', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem],
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

    await container
        .read(saleCompletionControllerProvider.notifier)
        .completeSale(item: soldItem, sale: sale());

    expect(await transactionRepository.getTrades(), isEmpty);
    expect(await dealRepository.getDeals(), isEmpty);
  });

  test('Deal creation failure rolls back sale, trade, and inventory', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem],
    );
    final transactionRepository = InMemoryTransactionRepository();
    final dealRepository = _FailingDealRepository();

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
            item: soldItem,
            sale: sale(),
            tradeInItems: const [
              IncomingTradeItemDraft(
                category: InventoryCategory.bat,
                brand: 'Sample Bat B',
                acquisitionValueCents: 10000,
              ),
            ],
          ),
      throwsA(isA<StateError>()),
    );

    final inventory = await inventoryRepository.getInventory();

    expect(inventory, hasLength(1));
    expect(inventory.single.id, 'sold-item');
    expect(inventory.single.status, InventoryStatus.available);
    expect(await transactionRepository.getSales(), isEmpty);
    expect(await transactionRepository.getTrades(), isEmpty);
    expect(await dealRepository.getDeals(), isEmpty);
  });
}

class _FailingDealRepository extends InMemoryDealRepository {
  @override
  Future<Deal> createDeal(Deal deal) {
    throw StateError('Simulated Deal creation failure.');
  }
}
