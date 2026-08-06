import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/incoming_trade_item_draft.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/sale_completion_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test(
    'sale completion creates linked trade-in inventory and trade record',
    () async {
      const soldItem = InventoryItem(
        id: 'sold-item',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        status: InventoryStatus.available,
      );

      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: const [soldItem],
      );
      final transactionRepository = InMemoryTransactionRepository();

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(saleCompletionControllerProvider.future);

      final result = await container
          .read(saleCompletionControllerProvider.notifier)
          .completeSale(
            item: soldItem,
            sale: SaleTransaction(
              inventoryItemId: 'sold-item',
              salePriceCents: 32500,
              saleDate: DateTime(2026, 8, 6),
              paymentMethod: PaymentMethod.cash,
              buyerContactId: 'buyer-1',
              acquisitionValueCents: 20000,
            ),
            tradeInItems: const [
              IncomingTradeItemDraft(
                category: InventoryCategory.glove,
                brand: 'Rawlings',
                model: 'Heart of the Hide',
                condition: InventoryCondition.good,
                acquisitionValueCents: 15000,
              ),
            ],
          );

      expect(result.soldItem.status, InventoryStatus.sold);

      final trades = await transactionRepository.getTrades();
      expect(trades, hasLength(1));
      expect(trades.single.saleTransactionId, result.sale.id);
      expect(trades.single.outgoingInventoryItemIds, ['sold-item']);
      expect(trades.single.incomingInventoryItemIds, hasLength(1));

      final tradeIn = await inventoryRepository.getInventoryItem(
        trades.single.incomingInventoryItemIds.single,
      );

      expect(tradeIn?.acquisitionType, AcquisitionType.traded);
      expect(tradeIn?.status, InventoryStatus.available);
      expect(tradeIn?.sellerContactId, 'buyer-1');
      expect(tradeIn?.purchaseDate, DateTime(2026, 8, 6));
      expect(tradeIn?.acquisitionValueCents, 15000);
    },
  );
}
