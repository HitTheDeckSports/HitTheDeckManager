import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_status.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/services/deal_recursive_analysis_service.dart';

void main() {
  test(
    'recursively rolls nested Deal cash, repairs, and open inventory upward',
    () {
      final saleA = SaleTransaction(
        id: 'sale-a',
        inventoryItemId: 'item-a',
        salePriceCents: 50000,
        tradeInCreditCents: 35000,
        saleDate: DateTime(2026, 9, 1),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 50000,
      );
      final saleB = SaleTransaction(
        id: 'sale-b',
        inventoryItemId: 'item-b',
        salePriceCents: 30000,
        tradeInCreditCents: 10000,
        saleDate: DateTime(2026, 9, 2),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 15000,
        repairCostCents: 2500,
      );
      final saleD = SaleTransaction(
        id: 'sale-d',
        inventoryItemId: 'item-d',
        salePriceCents: 15000,
        saleDate: DateTime(2026, 9, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 10000,
        repairCostCents: 2000,
      );
      final saleC = SaleTransaction(
        id: 'sale-c',
        inventoryItemId: 'item-c',
        salePriceCents: 30000,
        tradeInCreditCents: 15000,
        saleDate: DateTime(2026, 9, 4),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      const items = [
        InventoryItem(
          id: 'item-a',
          category: InventoryCategory.bat,
          brand: 'A',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 50000,
          status: InventoryStatus.sold,
        ),
        InventoryItem(
          id: 'item-b',
          category: InventoryCategory.bat,
          brand: 'B',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 15000,
          status: InventoryStatus.sold,
        ),
        InventoryItem(
          id: 'item-c',
          category: InventoryCategory.bat,
          brand: 'C',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 20000,
          status: InventoryStatus.sold,
        ),
        InventoryItem(
          id: 'item-d',
          category: InventoryCategory.bat,
          brand: 'D',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 10000,
          status: InventoryStatus.sold,
        ),
        InventoryItem(
          id: 'item-e',
          category: InventoryCategory.bat,
          brand: 'E',
          acquisitionType: AcquisitionType.traded,
          acquisitionValueCents: 15000,
          askingPriceCents: 15000,
          status: InventoryStatus.available,
        ),
      ];

      final deals = [
        Deal(
          id: 'deal-1',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: const ['item-b', 'item-c'],
          lineageInventoryItemIds: const ['item-b', 'item-c'],
          createdAt: DateTime(2026, 9, 1),
        ),
        Deal(
          id: 'deal-2',
          parentSaleTransactionId: 'sale-b',
          childInventoryItemIds: const ['item-d'],
          lineageInventoryItemIds: const ['item-d'],
          createdAt: DateTime(2026, 9, 2),
        ),
        Deal(
          id: 'deal-3',
          parentSaleTransactionId: 'sale-c',
          childInventoryItemIds: const ['item-e'],
          lineageInventoryItemIds: const ['item-e'],
          createdAt: DateTime(2026, 9, 4),
        ),
      ];

      final repairs = [
        RepairTransaction(
          id: 'repair-b',
          inventoryItemId: 'item-b',
          repairDate: DateTime(2026, 9, 2),
          costCents: 2500,
          description: 'Repair B',
        ),
        RepairTransaction(
          id: 'repair-d',
          inventoryItemId: 'item-d',
          repairDate: DateTime(2026, 9, 3),
          costCents: 2000,
          description: 'Repair D',
        ),
        RepairTransaction(
          id: 'repair-e',
          inventoryItemId: 'item-e',
          repairDate: DateTime(2026, 9, 5),
          costCents: 1500,
          description: 'Repair E',
        ),
      ];

      final result = DealRecursiveAnalysisService.calculate(
        deal: deals.first,
        deals: deals,
        inventoryItems: items,
        sales: [saleA, saleB, saleD, saleC],
        repairs: repairs,
        disposals: const [],
        trades: const [],
        warrantyReplacements: const [],
      );

      expect(result.totalCashReceivedCents, 65000);
      expect(result.totalRepairCostCents, 6000);
      expect(result.currentProfitCents, 9000);
      expect(result.projectedOpenInventoryValueCents, 15000);
      expect(result.projectedProfitCents, 24000);
      expect(result.openBranchCount, 1);
      expect(result.status, DealStatus.partiallyRealized);

      final branchB = result.branches[0];
      expect(branchB.realizedProfitCents, 15500);
      expect(branchB.projectedProfitCents, 15500);
      expect(branchB.openInventoryCount, 0);

      final branchC = result.branches[1];
      expect(branchC.realizedProfitCents, -6500);
      expect(branchC.projectedProfitCents, 8500);
      expect(branchC.openInventoryCount, 1);
    },
  );

  test('blank asking price contributes zero projected value', () {
    final sale = SaleTransaction(
      id: 'sale-root',
      inventoryItemId: 'root',
      salePriceCents: 20000,
      tradeInCreditCents: 10000,
      saleDate: DateTime(2026, 9, 1),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 15000,
    );

    const root = InventoryItem(
      id: 'root',
      category: InventoryCategory.bat,
      brand: 'Root',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.sold,
    );
    const child = InventoryItem(
      id: 'child',
      category: InventoryCategory.bat,
      brand: 'Child',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 10000,
      status: InventoryStatus.available,
    );
    const deal = Deal(
      id: 'deal',
      parentSaleTransactionId: 'sale-root',
      childInventoryItemIds: ['child'],
      lineageInventoryItemIds: ['child'],
    );

    final result = DealRecursiveAnalysisService.calculate(
      deal: deal,
      deals: const [deal],
      inventoryItems: const [root, child],
      sales: [sale],
      repairs: const [],
      disposals: const [],
      trades: const [],
      warrantyReplacements: const [],
    );

    expect(result.currentProfitCents, -5000);
    expect(result.projectedProfitCents, -5000);
  });
}
