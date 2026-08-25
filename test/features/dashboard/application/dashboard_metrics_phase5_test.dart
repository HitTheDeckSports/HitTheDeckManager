import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_date_range.dart';
import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_metrics.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  group('DashboardMetrics Phase 5 foundation', () {
    test(
      'selected date range controls revenue cost profit margin and units',
      () {
        final sales = [
          SaleTransaction(
            id: 'today',
            inventoryItemId: 'item-1',
            salePriceCents: 30000,
            saleDate: DateTime(2026, 8, 24),
            paymentMethod: PaymentMethod.cash,
            acquisitionValueCents: 18000,
            repairCostCents: 2000,
          ),
          SaleTransaction(
            id: 'prior',
            inventoryItemId: 'item-2',
            salePriceCents: 20000,
            saleDate: DateTime(2026, 8, 20),
            paymentMethod: PaymentMethod.cash,
            acquisitionValueCents: 10000,
            repairCostCents: 1000,
          ),
        ];

        final metrics = DashboardMetrics.calculate(
          inventoryItems: const [],
          saleTransactions: sales,
          asOf: DateTime(2026, 8, 24),
          dateRange: DashboardDateRange.forPreset(
            DashboardDateRangePreset.today,
            asOf: DateTime(2026, 8, 24),
          ),
        );

        expect(metrics.totalRevenueCents, 30000);
        expect(metrics.totalCostCents, 20000);
        expect(metrics.totalProfitCents, 10000);
        expect(metrics.grossMargin, closeTo(1 / 3, 0.000001));
        expect(metrics.unitsSold, 1);
        expect(metrics.dateRangeLabel, 'Today');
      },
    );

    test('open inventory cost includes repair costs', () {
      final inventory = [
        InventoryItem(
          id: 'item-1',
          category: InventoryCategory.bat,
          brand: 'Combat',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 20000,
          askingPriceCents: 35000,
          purchaseDate: DateTime(2026, 8, 1),
          status: InventoryStatus.available,
        ),
      ];

      final repairs = [
        RepairTransaction(
          id: 'repair-1',
          inventoryItemId: 'item-1',
          repairDate: DateTime(2026, 8, 5),
          costCents: 2500,
          description: 'Grip',
        ),
      ];

      final metrics = DashboardMetrics.calculate(
        inventoryItems: inventory,
        saleTransactions: const [],
        repairTransactions: repairs,
        asOf: DateTime(2026, 8, 24),
      );

      expect(metrics.openInventoryValueCents, 35000);
      expect(metrics.openInventoryCostCents, 22500);
      expect(metrics.openPotentialProfitCents, 12500);
    });

    test('quick snapshot uses live inventory and selected units sold', () {
      final inventory = [
        InventoryItem(
          id: 'available-1',
          category: InventoryCategory.bat,
          brand: 'Available 1',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          purchaseDate: DateTime(2026, 8, 14),
          status: InventoryStatus.available,
        ),
        InventoryItem(
          id: 'available-2',
          category: InventoryCategory.glove,
          brand: 'Available 2',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          purchaseDate: DateTime(2026, 8, 4),
          status: InventoryStatus.available,
        ),
        InventoryItem(
          id: 'inactive',
          category: InventoryCategory.bat,
          brand: 'Inactive',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          purchaseDate: DateTime(2026, 7, 25),
          status: InventoryStatus.inactive,
        ),
        InventoryItem(
          id: 'broken',
          category: InventoryCategory.bat,
          brand: 'Broken',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          purchaseDate: DateTime(2026, 8, 24),
          status: InventoryStatus.broken,
        ),
        const InventoryItem(
          id: 'sold',
          category: InventoryCategory.bat,
          brand: 'Sold',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          status: InventoryStatus.sold,
        ),
      ];

      final sales = [
        SaleTransaction(
          id: 'sale-1',
          inventoryItemId: 'sold',
          salePriceCents: 20000,
          saleDate: DateTime(2026, 8, 24),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
        ),
      ];

      final metrics = DashboardMetrics.calculate(
        inventoryItems: inventory,
        saleTransactions: sales,
        asOf: DateTime(2026, 8, 24),
      );

      expect(metrics.availableItems, 2);
      expect(metrics.unitsSold, 1);
      expect(metrics.brokenItems, 1);

      // Open dated inventory ages: 10, 20, 30, 0 days => average 15.
      expect(metrics.averageDaysInInventory, 15);
    });

    test('missing purchase dates are excluded from average inventory age', () {
      final inventory = [
        InventoryItem(
          id: 'dated',
          category: InventoryCategory.bat,
          brand: 'Dated',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          purchaseDate: DateTime(2026, 8, 14),
          status: InventoryStatus.available,
        ),
        const InventoryItem(
          id: 'unknown-date',
          category: InventoryCategory.bat,
          brand: 'Unknown',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 10000,
          status: InventoryStatus.available,
        ),
      ];

      final metrics = DashboardMetrics.calculate(
        inventoryItems: inventory,
        saleTransactions: const [],
        asOf: DateTime(2026, 8, 24),
      );

      expect(metrics.averageDaysInInventory, 10);
    });
  });
}
