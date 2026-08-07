import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_status.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test('Deal summary provider calculates Bat A/B completed profit', () async {
    final parentSale = SaleTransaction(
      id: 'sale-a',
      inventoryItemId: 'bat-a',
      salePriceCents: 20000,
      tradeInCreditCents: 10000,
      saleDate: DateTime(2026, 8, 6),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 15000,
    );

    final childSale = SaleTransaction(
      id: 'sale-b',
      inventoryItemId: 'bat-b',
      salePriceCents: 20000,
      saleDate: DateTime(2026, 8, 10),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 10000,
    );

    const child = InventoryItem(
      id: 'bat-b',
      category: InventoryCategory.bat,
      brand: 'Bat B',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 10000,
      status: InventoryStatus.sold,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [child],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale, childSale],
    );
    final dealRepository = InMemoryDealRepository(
      initialDeals: const [
        Deal(
          id: 'deal-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: ['bat-b'],
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
        dealRepositoryProvider.overrideWithValue(dealRepository),
      ],
    );

    addTearDown(container.dispose);
    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);

    final summary = await container.read(dealSummaryProvider('deal-a').future);

    expect(summary?.status, DealStatus.completed);
    expect(summary?.parentTransactionProfitCents, 5000);
    expect(summary?.realizedChildProfitCents, 10000);
    expect(summary?.realizedDealProfitCents, 15000);
  });
}
