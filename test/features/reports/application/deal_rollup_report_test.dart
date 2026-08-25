import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/reports/application/deal_rollup_report.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_status.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  test('deal rollup follows nested deals and projects open descendants', () {
    const rootDeal = Deal(
      id: 'deal-root',
      parentSaleTransactionId: 'sale-root',
      childInventoryItemIds: ['trade-1'],
    );
    const nestedDeal = Deal(
      id: 'deal-nested',
      parentSaleTransactionId: 'sale-trade-1',
      childInventoryItemIds: ['trade-2'],
    );
    final report = DealRollupReport.calculate(
      deals: const [rootDeal, nestedDeal],
      inventoryItems: [
        const InventoryItem(
          id: 'trade-1',
          category: InventoryCategory.bat,
          brand: 'Easton',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 10000,
          status: InventoryStatus.sold,
        ),
        const InventoryItem(
          id: 'trade-2',
          category: InventoryCategory.glove,
          brand: 'Wilson',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 8000,
          askingPriceCents: 15000,
        ),
      ],
      sales: [
        SaleTransaction(
          id: 'sale-root',
          inventoryItemId: 'original',
          salePriceCents: 30000,
          saleDate: DateTime(2026, 8, 1),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 20000,
        ),
        SaleTransaction(
          id: 'sale-trade-1',
          inventoryItemId: 'trade-1',
          salePriceCents: 18000,
          saleDate: DateTime(2026, 8, 10),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
        ),
      ],
      repairs: const [],
    );

    final row = report.rows.single;
    expect(row.status, DealStatus.partiallyRealized);
    expect(row.realizedProfitCents, 18000);
    expect(row.projectedProfitCents, 25000);
    expect(row.descendantDealCount, 1);
    expect(row.cycleDetected, isFalse);
  });

  test('deal rollup honors configurable maximum depth', () {
    const rootDeal = Deal(
      id: 'deal-root',
      parentSaleTransactionId: 'sale-root',
      childInventoryItemIds: ['trade-1'],
    );
    const nestedDeal = Deal(
      id: 'deal-nested',
      parentSaleTransactionId: 'sale-trade-1',
      childInventoryItemIds: ['trade-2'],
    );
    final report = DealRollupReport.calculate(
      deals: const [rootDeal, nestedDeal],
      inventoryItems: [
        const InventoryItem(
          id: 'trade-1',
          category: InventoryCategory.bat,
          brand: 'Easton',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 10000,
          status: InventoryStatus.sold,
        ),
        const InventoryItem(
          id: 'trade-2',
          category: InventoryCategory.glove,
          brand: 'Wilson',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 8000,
          askingPriceCents: 15000,
        ),
      ],
      sales: [
        SaleTransaction(
          id: 'sale-root',
          inventoryItemId: 'original',
          salePriceCents: 30000,
          saleDate: DateTime(2026, 8, 1),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 20000,
        ),
        SaleTransaction(
          id: 'sale-trade-1',
          inventoryItemId: 'trade-1',
          salePriceCents: 18000,
          saleDate: DateTime(2026, 8, 10),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
        ),
      ],
      repairs: const [],
      maxDepth: 0,
    );

    final row = report.rows.firstWhere((row) => row.deal.id == 'deal-root');
    expect(row.depthLimitReached, isTrue);
    expect(row.descendantDealCount, 0);
  });
}
