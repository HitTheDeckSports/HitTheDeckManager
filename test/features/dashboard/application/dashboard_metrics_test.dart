import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_metrics.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  group('DashboardMetrics', () {
    test('calculates month-to-date sales metrics only', () {
      final sales = [
        SaleTransaction(
          id: 'sale-current-1',
          inventoryItemId: 'item-1',
          salePriceCents: 30000,
          saleDate: DateTime(2026, 8, 5),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 20000,
        ),
        SaleTransaction(
          id: 'sale-current-2',
          inventoryItemId: 'item-2',
          salePriceCents: 20000,
          saleDate: DateTime(2026, 8, 19),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
        ),
        SaleTransaction(
          id: 'sale-prior-month',
          inventoryItemId: 'item-3',
          salePriceCents: 50000,
          saleDate: DateTime(2026, 7, 31),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 25000,
        ),
        SaleTransaction(
          id: 'sale-future',
          inventoryItemId: 'item-4',
          salePriceCents: 60000,
          saleDate: DateTime(2026, 8, 25),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 30000,
        ),
      ];

      final metrics = DashboardMetrics.calculate(
        inventoryItems: const [],
        saleTransactions: sales,
        asOf: DateTime(2026, 8, 19, 23, 59, 59),
      );

      expect(metrics.totalRevenueCents, 50000);
      expect(metrics.totalCostCents, 30000);
      expect(metrics.totalProfitCents, 20000);
      expect(metrics.grossMargin, closeTo(0.40, 0.0001));
    });

    test(
      'includes Available Inactive and Broken inventory and excludes Sold and Disposed',
      () {
        final inventoryItems = [
          const InventoryItem(
            id: 'available',
            category: InventoryCategory.bat,
            brand: 'Available',
            acquisitionType: AcquisitionType.purchased,
            acquisitionValueCents: 10000,
            askingPriceCents: 20000,
            status: InventoryStatus.available,
          ),
          const InventoryItem(
            id: 'inactive',
            category: InventoryCategory.bat,
            brand: 'Inactive',
            acquisitionType: AcquisitionType.purchased,
            acquisitionValueCents: 5000,
            askingPriceCents: 9000,
            status: InventoryStatus.inactive,
          ),
          const InventoryItem(
            id: 'broken',
            category: InventoryCategory.bat,
            brand: 'Broken',
            acquisitionType: AcquisitionType.purchased,
            acquisitionValueCents: 3000,
            askingPriceCents: 4000,
            status: InventoryStatus.broken,
          ),
          const InventoryItem(
            id: 'sold',
            category: InventoryCategory.bat,
            brand: 'Sold',
            acquisitionType: AcquisitionType.purchased,
            acquisitionValueCents: 8000,
            askingPriceCents: 15000,
            status: InventoryStatus.sold,
          ),
          const InventoryItem(
            id: 'disposed',
            category: InventoryCategory.bat,
            brand: 'Disposed',
            acquisitionType: AcquisitionType.purchased,
            acquisitionValueCents: 6000,
            askingPriceCents: 12000,
            status: InventoryStatus.disposed,
          ),
        ];

        final metrics = DashboardMetrics.calculate(
          inventoryItems: inventoryItems,
          saleTransactions: const [],
          asOf: DateTime(2026, 8, 19),
        );

        expect(metrics.openInventoryValueCents, 33000);
        expect(metrics.openInventoryCostCents, 18000);
        expect(metrics.openPotentialProfitCents, 15000);
        expect(metrics.inventoryCount, 3);
      },
    );

    test('treats missing asking price as zero inventory value', () {
      final inventoryItems = [
        const InventoryItem(
          id: 'priced',
          category: InventoryCategory.bat,
          brand: 'Priced',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          askingPriceCents: 18000,
        ),
        const InventoryItem(
          id: 'unpriced',
          category: InventoryCategory.bat,
          brand: 'Unpriced',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 7000,
          askingPriceCents: null,
        ),
      ];

      final metrics = DashboardMetrics.calculate(
        inventoryItems: inventoryItems,
        saleTransactions: const [],
        asOf: DateTime(2026, 8, 19),
      );

      expect(metrics.openInventoryValueCents, 18000);
      expect(metrics.openInventoryCostCents, 17000);
      expect(metrics.openPotentialProfitCents, 1000);
      expect(metrics.inventoryCount, 2);
    });

    test('allows open potential profit to be negative', () {
      final inventoryItems = [
        const InventoryItem(
          id: 'unpriced',
          category: InventoryCategory.bat,
          brand: 'Unpriced',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 20000,
        ),
      ];

      final metrics = DashboardMetrics.calculate(
        inventoryItems: inventoryItems,
        saleTransactions: const [],
        asOf: DateTime(2026, 8, 19),
      );

      expect(metrics.openInventoryValueCents, 0);
      expect(metrics.openInventoryCostCents, 20000);
      expect(metrics.openPotentialProfitCents, -20000);
      expect(metrics.inventoryCount, 1);
    });

    test('returns zero gross margin when month-to-date revenue is zero', () {
      final metrics = DashboardMetrics.calculate(
        inventoryItems: const [],
        saleTransactions: const [],
        asOf: DateTime(2026, 8, 19),
      );

      expect(metrics.totalRevenueCents, 0);
      expect(metrics.totalCostCents, 0);
      expect(metrics.totalProfitCents, 0);
      expect(metrics.grossMargin, 0);
    });
  });
}
