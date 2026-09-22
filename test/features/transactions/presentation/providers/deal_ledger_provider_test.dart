import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_status.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_ledger_provider.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_providers.dart';

void main() {
  test(
    'ledger summaries preserve recursive Deal status and numbering',
    () async {
      const rootItem = InventoryItem(
        id: 'root-item',
        inventoryNumber: 'BAT-2609-0001',
        category: InventoryCategory.bat,
        brand: 'Root',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
        status: InventoryStatus.sold,
      );
      const firstChild = InventoryItem(
        id: 'child-a',
        inventoryNumber: 'BAT-2609-0002',
        category: InventoryCategory.bat,
        brand: 'Child A',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 8000,
        status: InventoryStatus.sold,
      );
      const openChild = InventoryItem(
        id: 'child-b',
        inventoryNumber: 'BAT-2609-0003',
        category: InventoryCategory.bat,
        brand: 'Child B',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 7000,
        askingPriceCents: 12000,
        status: InventoryStatus.available,
      );

      final rootSale = SaleTransaction(
        id: 'sale-root',
        inventoryItemId: 'root-item',
        salePriceCents: 20000,
        tradeInCreditCents: 8000,
        saleDate: DateTime(2026, 9, 1),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 10000,
      );
      final childSale = SaleTransaction(
        id: 'sale-child',
        inventoryItemId: 'child-a',
        salePriceCents: 18000,
        tradeInCreditCents: 7000,
        saleDate: DateTime(2026, 9, 2),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 8000,
      );

      final rootDeal = Deal(
        id: 'deal-root',
        parentSaleTransactionId: 'sale-root',
        childInventoryItemIds: const ['child-a'],
        createdAt: DateTime(2026, 9, 1),
      );
      final nestedDeal = Deal(
        id: 'deal-nested',
        parentSaleTransactionId: 'sale-child',
        childInventoryItemIds: const ['child-b'],
        createdAt: DateTime(2026, 9, 2),
      );

      final container = ProviderContainer(
        overrides: [
          dealsProvider.overrideWith(
            (ref) => Stream.value([rootDeal, nestedDeal]),
          ),
          inventoryItemsProvider.overrideWith(
            (ref) => Stream.value(const [rootItem, firstChild, openChild]),
          ),
          saleTransactionsProvider.overrideWith(
            (ref) => Stream.value([rootSale, childSale]),
          ),
          repairTransactionsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          disposalTransactionsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          tradeTransactionsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          warrantyReplacementDealsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Keep the async provider (and therefore its StreamProvider dependencies)
      // actively listened to while awaiting the result. A bare ProviderContainer
      // read can allow auto-disposed stream dependencies to tear down before
      // Stream.value emits in this unit-test harness.
      final subscription = container.listen(
        dealLedgerSummariesProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final summaries = await container.read(
        dealLedgerSummariesProvider.future,
      );

      expect(summaries, hasLength(2));

      final root = summaries.singleWhere(
        (summary) => summary.deal.id == 'deal-root',
      );
      final nested = summaries.singleWhere(
        (summary) => summary.deal.id == 'deal-nested',
      );

      expect(root.displayNumber, '2026-001');
      expect(root.status, DealStatus.partiallyRealized);
      expect(
        root.relatedInventoryItems.map((item) => item.inventoryNumber),
        containsAll(['BAT-2609-0002', 'BAT-2609-0003']),
      );

      expect(nested.displayNumber, '2026-002');
      expect(nested.status, DealStatus.open);
    },
  );
}
