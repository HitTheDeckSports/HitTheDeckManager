import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/sale_transaction.dart';

final class DashboardMetrics {
  const DashboardMetrics({
    required this.totalRevenueCents,
    required this.totalCostCents,
    required this.totalProfitCents,
    required this.grossMargin,
    required this.openInventoryValueCents,
    required this.openInventoryCostCents,
    required this.openPotentialProfitCents,
    required this.inventoryCount,
  });

  final int totalRevenueCents;
  final int totalCostCents;
  final int totalProfitCents;

  /// Month-to-date gross margin expressed as a decimal.
  ///
  /// Example: 0.25 represents 25%.
  /// Returns 0 when there is no month-to-date revenue.
  final double grossMargin;

  final int openInventoryValueCents;
  final int openInventoryCostCents;
  final int openPotentialProfitCents;
  final int inventoryCount;

  factory DashboardMetrics.calculate({
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> saleTransactions,
    required DateTime asOf,
  }) {
    final monthStart = DateTime(asOf.year, asOf.month, 1);

    final nextMonthStart = asOf.month == 12
        ? DateTime(asOf.year + 1, 1, 1)
        : DateTime(asOf.year, asOf.month + 1, 1);

    final monthToDateSales = saleTransactions.where((sale) {
      return !sale.saleDate.isBefore(monthStart) &&
          sale.saleDate.isBefore(nextMonthStart) &&
          !sale.saleDate.isAfter(asOf);
    });

    var totalRevenueCents = 0;
    var totalCostCents = 0;

    for (final sale in monthToDateSales) {
      totalRevenueCents += sale.salePriceCents;
      totalCostCents += sale.acquisitionValueCents ?? 0;
    }

    final totalProfitCents = totalRevenueCents - totalCostCents;

    final grossMargin = totalRevenueCents == 0
        ? 0.0
        : totalProfitCents / totalRevenueCents;

    final openInventoryItems = inventoryItems.where(
      (item) => _isOpenInventoryStatus(item.status),
    );

    var openInventoryValueCents = 0;
    var openInventoryCostCents = 0;
    var inventoryCount = 0;

    for (final item in openInventoryItems) {
      inventoryCount += 1;
      openInventoryValueCents += item.askingPriceCents ?? 0;
      openInventoryCostCents += item.acquisitionValueCents;
    }

    final openPotentialProfitCents =
        openInventoryValueCents - openInventoryCostCents;

    return DashboardMetrics(
      totalRevenueCents: totalRevenueCents,
      totalCostCents: totalCostCents,
      totalProfitCents: totalProfitCents,
      grossMargin: grossMargin,
      openInventoryValueCents: openInventoryValueCents,
      openInventoryCostCents: openInventoryCostCents,
      openPotentialProfitCents: openPotentialProfitCents,
      inventoryCount: inventoryCount,
    );
  }

  static bool _isOpenInventoryStatus(InventoryStatus status) {
    return switch (status) {
      InventoryStatus.available => true,
      InventoryStatus.inactive => true,
      InventoryStatus.broken => true,
      InventoryStatus.sold => false,
      InventoryStatus.disposed => false,
    };
  }
}
