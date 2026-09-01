import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
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
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/sale_completion_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
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

      final dealRepository = InMemoryDealRepository();

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
      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(dealRepository.dispose);

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

    test(
      'refreshes lifetime Trade History when an existing item is sold in a trade',
      () async {
        const item = InventoryItem(
          id: 'item-1',
          inventoryNumber: 'BAT-2608-0001',
          category: InventoryCategory.bat,
          brand: 'Combat',
          model: 'Spec H1',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 20000,
          status: InventoryStatus.available,
        );

        final inventoryRepository = InMemoryInventoryRepository(
          initialItems: const [item],
        );
        final transactionRepository = InMemoryTransactionRepository();
        final dealRepository = InMemoryDealRepository();

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
        addTearDown(inventoryRepository.dispose);
        addTearDown(transactionRepository.dispose);
        addTearDown(dealRepository.dispose);

        expect(
          await container.read(tradesForInventoryItemProvider('item-1').future),
          isEmpty,
        );

        final sale = SaleTransaction(
          inventoryItemId: 'item-1',
          salePriceCents: 32500,
          saleDate: DateTime(2026, 9, 1),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 20000,
        );

        await container
            .read(saleCompletionControllerProvider.notifier)
            .completeSale(
              item: item,
              sale: sale,
              tradeInItems: const [
                IncomingTradeItemDraft(
                  brand: 'Easton',
                  model: 'Hype Fire',
                  acquisitionValueCents: 10000,
                ),
              ],
            );

        final refreshedTrades = await container.read(
          tradesForInventoryItemProvider('item-1').future,
        );

        expect(refreshedTrades, hasLength(1));
        expect(
          refreshedTrades.single.outgoingInventoryItemIds,
          contains('item-1'),
        );
        expect(refreshedTrades.single.incomingInventoryItemIds, hasLength(1));
      },
    );
    test(
      'extends the same Deal when a lineage item is later sold with trade-ins',
      () async {
        const item = InventoryItem(
          id: 'item-b',
          inventoryNumber: 'BAT-2608-0002',
          category: InventoryCategory.bat,
          brand: 'Easton',
          model: 'Hype Fire',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 20000,
          status: InventoryStatus.available,
        );

        const originalDeal = Deal(
          id: 'deal-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: ['item-b'],
          lineageInventoryItemIds: ['item-b'],
        );

        final inventoryRepository = InMemoryInventoryRepository(
          initialItems: const [item],
        );
        final transactionRepository = InMemoryTransactionRepository();
        final dealRepository = InMemoryDealRepository(
          initialDeals: const [originalDeal],
        );

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
        addTearDown(inventoryRepository.dispose);
        addTearDown(transactionRepository.dispose);
        addTearDown(dealRepository.dispose);

        final sale = SaleTransaction(
          inventoryItemId: 'item-b',
          salePriceCents: 30000,
          saleDate: DateTime(2026, 9, 2),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 20000,
        );

        await container
            .read(saleCompletionControllerProvider.notifier)
            .completeSale(
              item: item,
              sale: sale,
              tradeInItems: const [
                IncomingTradeItemDraft(
                  brand: 'Louisville Slugger',
                  model: 'Atlas',
                  acquisitionValueCents: 12000,
                ),
                IncomingTradeItemDraft(
                  brand: 'Rawlings',
                  model: 'Icon',
                  acquisitionValueCents: 8000,
                ),
              ],
            );

        final deals = await dealRepository.getDeals();
        expect(deals, hasLength(1));

        final extendedDeal = deals.single;
        expect(extendedDeal.id, 'deal-a');
        expect(extendedDeal.parentSaleTransactionId, 'sale-a');
        expect(extendedDeal.childInventoryItemIds, const ['item-b']);

        final trades = await transactionRepository.getTrades();
        expect(trades, hasLength(1));
        final newTradeInIds = trades.single.incomingInventoryItemIds;
        expect(newTradeInIds, hasLength(2));

        expect(
          extendedDeal.effectiveLineageInventoryItemIds,
          containsAll(['item-b', ...newTradeInIds]),
        );
        expect(extendedDeal.effectiveLineageInventoryItemIds, hasLength(3));

        for (final newItemId in newTradeInIds) {
          expect(
            (await dealRepository.getDealForLineageInventoryItem(
              newItemId,
            ))?.id,
            'deal-a',
          );
        }

        final descendantSale = await transactionRepository
            .getSaleForInventoryItem('item-b');
        expect(descendantSale, isNotNull);
        expect(
          await dealRepository.getDealForParentSale(descendantSale!.id!),
          isNull,
        );
      },
    );

    test(
      'new trade Deal initializes direct children and lineage together',
      () async {
        const item = InventoryItem(
          id: 'root-item',
          inventoryNumber: 'BAT-2608-0090',
          category: InventoryCategory.bat,
          brand: 'Combat',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 15000,
          status: InventoryStatus.available,
        );

        final inventoryRepository = InMemoryInventoryRepository(
          initialItems: const [item],
        );
        final transactionRepository = InMemoryTransactionRepository();
        final dealRepository = InMemoryDealRepository();

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
        addTearDown(inventoryRepository.dispose);
        addTearDown(transactionRepository.dispose);
        addTearDown(dealRepository.dispose);

        final sale = SaleTransaction(
          inventoryItemId: 'root-item',
          salePriceCents: 25000,
          saleDate: DateTime(2026, 9, 2),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 15000,
        );

        await container
            .read(saleCompletionControllerProvider.notifier)
            .completeSale(
              item: item,
              sale: sale,
              tradeInItems: const [
                IncomingTradeItemDraft(
                  brand: 'Marucci',
                  model: 'CatX',
                  acquisitionValueCents: 10000,
                ),
              ],
            );

        final deal = (await dealRepository.getDeals()).single;

        expect(deal.childInventoryItemIds, hasLength(1));
        expect(deal.lineageInventoryItemIds, deal.childInventoryItemIds);
      },
    );
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

      final dealRepository = InMemoryDealRepository();

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
      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(dealRepository.dispose);

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

      final dealRepository = InMemoryDealRepository();

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
      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(dealRepository.dispose);

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
