import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/reports/application/recursive_deal_report.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/warranty_replacement_deal.dart';

void main() {
  test('builds report rows with branch accounting and warranty continuity', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b', 'item-c'],
      lineageInventoryItemIds: ['item-b', 'item-c', 'item-d', 'item-w'],
    );

    final report = RecursiveDealReport.calculate(
      deals: const [deal],
      inventoryItems: const [
        InventoryItem(
          id: 'item-b',
          category: InventoryCategory.bat,
          brand: 'B',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 10000,
          status: InventoryStatus.sold,
        ),
        InventoryItem(
          id: 'item-c',
          category: InventoryCategory.bat,
          brand: 'C',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 8000,
          askingPriceCents: 10000,
        ),
        InventoryItem(
          id: 'item-d',
          category: InventoryCategory.bat,
          brand: 'D',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 12000,
          status: InventoryStatus.disposed,
        ),
        InventoryItem(
          id: 'item-w',
          category: InventoryCategory.bat,
          brand: 'W',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 12000,
          askingPriceCents: 17000,
        ),
      ],
      sales: [
        SaleTransaction(
          id: 'sale-a',
          inventoryItemId: 'item-a',
          salePriceCents: 25000,
          saleDate: DateTime(2026, 8, 1),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
        ),
        SaleTransaction(
          id: 'sale-b',
          inventoryItemId: 'item-b',
          salePriceCents: 15000,
          saleDate: DateTime(2026, 9, 1),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
          tradeInCreditCents: 12000,
        ),
      ],
      repairs: [
        RepairTransaction(
          id: 'repair-d',
          inventoryItemId: 'item-d',
          repairDate: DateTime(2026, 9, 2),
          costCents: 1000,
          description: 'Repair before warranty',
        ),
      ],
      trades: [
        TradeTransaction(
          id: 'trade-b',
          saleTransactionId: 'sale-b',
          outgoingInventoryItemIds: const ['item-b'],
          incomingInventoryItemIds: const ['item-d'],
          tradeDate: DateTime(2026, 9, 1),
        ),
      ],
      disposals: [
        DisposalTransaction(
          id: 'disposal-d',
          inventoryItemId: 'item-d',
          disposalDate: DateTime(2026, 9, 3),
          reason: DisposalReason.warrantyReplacement,
          replacementInventoryItemId: 'item-w',
        ),
      ],
      warrantyReplacements: [
        WarrantyReplacementDeal(
          id: 'warranty-d',
          disposalTransactionId: 'disposal-d',
          disposedInventoryItemId: 'item-d',
          replacementInventoryItemId: 'item-w',
          replacementDate: DateTime(2026, 9, 3),
        ),
      ],
    );

    expect(report.rows, hasLength(1));

    final row = report.rows.single;
    final branchB = row.summary.branchFor('item-b');
    final branchC = row.summary.branchFor('item-c');

    expect(row.tree.nodeFor('item-w')?.rootChildInventoryItemId, 'item-b');
    expect(branchB?.realizedProfitCents, 4000);
    expect(branchB?.projectedOpenProfitCents, 5000);
    expect(branchC?.projectedOpenProfitCents, 2000);
    expect(row.summary.parentTransactionProfitCents, 15000);
    expect(row.summary.projectedDealProfitCents, 26000);
  });

  test('throws when a Deal parent sale is unavailable', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'missing-sale',
      childInventoryItemIds: ['item-b'],
      lineageInventoryItemIds: ['item-b'],
    );

    expect(
      () => RecursiveDealReport.calculate(
        deals: const [deal],
        inventoryItems: const [
          InventoryItem(
            id: 'item-b',
            category: InventoryCategory.bat,
            brand: 'B',
            acquisitionType: AcquisitionType.traded,
            acquisitionValueCents: 10000,
          ),
        ],
        sales: const [],
        repairs: const [],
        trades: const [],
        disposals: const [],
        warrantyReplacements: const [],
      ),
      throwsStateError,
    );
  });
}
