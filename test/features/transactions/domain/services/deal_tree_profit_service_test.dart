import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/warranty_replacement_deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/services/deal_lineage_service.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/services/deal_tree_profit_service.dart';

void main() {
  test('shows profitable and unprofitable branches separately', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b', 'item-c'],
      lineageInventoryItemIds: ['item-b', 'item-c', 'item-d'],
    );

    final trade = TradeTransaction(
      id: 'trade-b',
      saleTransactionId: 'sale-b',
      outgoingInventoryItemIds: const ['item-b'],
      incomingInventoryItemIds: const ['item-d'],
      tradeDate: DateTime(2026, 9, 1),
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: [trade],
      warrantyReplacements: const [],
    );

    final summary = DealTreeProfitService.calculate(
      tree: tree,
      parentSale: SaleTransaction(
        id: 'sale-a',
        inventoryItemId: 'item-a',
        salePriceCents: 30000,
        saleDate: DateTime(2026, 8, 1),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 10000,
        tradeInCreditCents: 22500,
      ),
      lineageInventoryItems: const [
        InventoryItem(
          id: 'item-b',
          category: InventoryCategory.bat,
          brand: 'B',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 12500,
          status: InventoryStatus.sold,
        ),
        InventoryItem(
          id: 'item-c',
          category: InventoryCategory.bat,
          brand: 'C',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 10000,
          status: InventoryStatus.sold,
        ),
        InventoryItem(
          id: 'item-d',
          category: InventoryCategory.bat,
          brand: 'D',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 15000,
          status: InventoryStatus.sold,
        ),
      ],
      lineageSales: [
        SaleTransaction(
          id: 'sale-b',
          inventoryItemId: 'item-b',
          salePriceCents: 20000,
          saleDate: DateTime(2026, 9, 1),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 12500,
          tradeInCreditCents: 15000,
        ),
        SaleTransaction(
          id: 'sale-c',
          inventoryItemId: 'item-c',
          salePriceCents: 8000,
          saleDate: DateTime(2026, 9, 2),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
        ),
        SaleTransaction(
          id: 'sale-d',
          inventoryItemId: 'item-d',
          salePriceCents: 18000,
          saleDate: DateTime(2026, 9, 3),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 15000,
        ),
      ],
      lineageRepairs: const [],
      lineageDisposals: const [],
      warrantyReplacements: const [],
    );

    final branchB = summary.branchFor('item-b');
    final branchC = summary.branchFor('item-c');

    expect(summary.parentTransactionProfitCents, 20000);
    expect(branchB?.realizedProfitCents, 10500);
    expect(branchC?.realizedProfitCents, -2000);
    expect(summary.realizedDealProfitCents, 28500);
    expect(summary.projectedDealProfitCents, 28500);
  });

  test('projected open branch profit subtracts repair costs', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b'],
      lineageInventoryItemIds: ['item-b'],
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: const [],
      warrantyReplacements: const [],
    );

    final summary = DealTreeProfitService.calculate(
      tree: tree,
      parentSale: SaleTransaction(
        id: 'sale-a',
        inventoryItemId: 'item-a',
        salePriceCents: 20000,
        saleDate: DateTime(2026, 8, 1),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 10000,
      ),
      lineageInventoryItems: const [
        InventoryItem(
          id: 'item-b',
          category: InventoryCategory.bat,
          brand: 'B',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 10000,
          askingPriceCents: 15000,
        ),
      ],
      lineageSales: const [],
      lineageRepairs: [
        RepairTransaction(
          id: 'repair-b',
          inventoryItemId: 'item-b',
          repairDate: DateTime(2026, 9, 1),
          costCents: 2000,
          description: 'Repair',
        ),
      ],
      lineageDisposals: const [],
      warrantyReplacements: const [],
    );

    final branch = summary.branchFor('item-b');

    expect(branch?.realizedProfitCents, 0);
    expect(branch?.projectedOpenProfitCents, 3000);
    expect(branch?.projectedBranchProfitCents, 3000);
    expect(branch?.openInventoryCount, 1);
  });

  test('warranty continuation does not duplicate acquisition basis', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b'],
      lineageInventoryItemIds: ['item-b', 'item-w'],
    );

    final warranty = WarrantyReplacementDeal(
      id: 'warranty-a',
      disposalTransactionId: 'disposal-b',
      disposedInventoryItemId: 'item-b',
      replacementInventoryItemId: 'item-w',
      replacementDate: DateTime(2026, 9, 2),
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: const [],
      warrantyReplacements: [warranty],
    );

    final summary = DealTreeProfitService.calculate(
      tree: tree,
      parentSale: SaleTransaction(
        id: 'sale-a',
        inventoryItemId: 'item-a',
        salePriceCents: 20000,
        saleDate: DateTime(2026, 8, 1),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 10000,
      ),
      lineageInventoryItems: const [
        InventoryItem(
          id: 'item-b',
          category: InventoryCategory.bat,
          brand: 'B',
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
          askingPriceCents: 18000,
        ),
      ],
      lineageSales: const [],
      lineageRepairs: [
        RepairTransaction(
          id: 'repair-b',
          inventoryItemId: 'item-b',
          repairDate: DateTime(2026, 9, 1),
          costCents: 1000,
          description: 'Repair before warranty',
        ),
      ],
      lineageDisposals: [
        DisposalTransaction(
          id: 'disposal-b',
          inventoryItemId: 'item-b',
          disposalDate: DateTime(2026, 9, 2),
          reason: DisposalReason.warrantyReplacement,
          replacementInventoryItemId: 'item-w',
        ),
      ],
      warrantyReplacements: [warranty],
    );

    final branch = summary.branchFor('item-b');

    expect(branch?.realizedProfitCents, -1000);
    expect(branch?.projectedOpenProfitCents, 6000);
    expect(branch?.projectedBranchProfitCents, 5000);
    expect(branch?.openInventoryCount, 1);
  });

  test('standard disposal realizes acquisition and repair loss', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b'],
      lineageInventoryItemIds: ['item-b'],
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: const [],
      warrantyReplacements: const [],
    );

    final summary = DealTreeProfitService.calculate(
      tree: tree,
      parentSale: SaleTransaction(
        id: 'sale-a',
        inventoryItemId: 'item-a',
        salePriceCents: 20000,
        saleDate: DateTime(2026, 8, 1),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 10000,
      ),
      lineageInventoryItems: const [
        InventoryItem(
          id: 'item-b',
          category: InventoryCategory.bat,
          brand: 'B',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 12000,
          status: InventoryStatus.disposed,
        ),
      ],
      lineageSales: const [],
      lineageRepairs: [
        RepairTransaction(
          id: 'repair-b',
          inventoryItemId: 'item-b',
          repairDate: DateTime(2026, 9, 1),
          costCents: 2000,
          description: 'Repair',
        ),
      ],
      lineageDisposals: [
        DisposalTransaction(
          id: 'disposal-b',
          inventoryItemId: 'item-b',
          disposalDate: DateTime(2026, 9, 2),
          reason: DisposalReason.damagedBeyondRepair,
        ),
      ],
      warrantyReplacements: const [],
    );

    final branch = summary.branchFor('item-b');

    expect(branch?.realizedProfitCents, -14000);
    expect(branch?.standardDisposalCount, 1);
    expect(branch?.openInventoryCount, 0);
  });

  test('blank asking price is open but contributes zero projection', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b'],
      lineageInventoryItemIds: ['item-b'],
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: const [],
      warrantyReplacements: const [],
    );

    final summary = DealTreeProfitService.calculate(
      tree: tree,
      parentSale: SaleTransaction(
        id: 'sale-a',
        inventoryItemId: 'item-a',
        salePriceCents: 10000,
        saleDate: DateTime(2026, 8, 1),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 5000,
      ),
      lineageInventoryItems: const [
        InventoryItem(
          id: 'item-b',
          category: InventoryCategory.bat,
          brand: 'B',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 4000,
        ),
      ],
      lineageSales: const [],
      lineageRepairs: const [],
      lineageDisposals: const [],
      warrantyReplacements: const [],
    );

    final branch = summary.branchFor('item-b');

    expect(branch?.projectedOpenProfitCents, 0);
    expect(branch?.openInventoryCount, 1);
  });
}
