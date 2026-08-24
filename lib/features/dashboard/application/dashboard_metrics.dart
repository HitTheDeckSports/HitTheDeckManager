import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/repair_transaction.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import 'dashboard_date_range.dart';

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
    this.unitsSold = 0,
    this.availableItems = 0,
    this.averageDaysInInventory = 0,
    this.brokenItems = 0,
    this.dateRangeLabel = 'Month to Date',
  });

  final int totalRevenueCents;
  final int totalCostCents;
  final int totalProfitCents;

  /// Gross margin for the selected dashboard date range as a decimal.
  ///
  /// Example: 0.25 represents 25%.
  /// Returns 0 when there is no revenue in the selected range.
  final double grossMargin;

  final int openInventoryValueCents;
  final int openInventoryCostCents;
  final int openPotentialProfitCents;
  final int inventoryCount;

  /// Number of completed sale transactions in the selected date range.
  final int unitsSold;

  /// Live count of inventory currently Available for sale.
  final int availableItems;

  /// Live average age, in whole days, of all open inventory with a known
  /// purchase/acquisition date.
  ///
  /// Open inventory includes Available, Inactive, and Broken. Items with no
  /// known acquisition date are excluded from the average rather than being
  /// treated as zero-day inventory.
  final int averageDaysInInventory;

  /// Live count of inventory currently marked Broken.
  final int brokenItems;

  final String dateRangeLabel;

  factory DashboardMetrics.calculate({
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> saleTransactions,
    List<RepairTransaction> repairTransactions = const [],
    required DateTime asOf,
    DashboardDateRange? dateRange,
  }) {
    final effectiveRange =
        dateRange ??
        DashboardDateRange.forPreset(
          DashboardDateRangePreset.monthToDate,
          asOf: asOf,
        );

    final selectedSales = saleTransactions.where(
      (sale) => effectiveRange.contains(sale.saleDate),
    );

    var totalRevenueCents = 0;
    var totalCostCents = 0;
    var unitsSold = 0;

    for (final sale in selectedSales) {
      totalRevenueCents += sale.salePriceCents;
      totalCostCents += sale.totalCostBasisCents ?? 0;
      unitsSold += 1;
    }

    final totalProfitCents = totalRevenueCents - totalCostCents;

    final grossMargin = totalRevenueCents == 0
        ? 0.0
        : totalProfitCents / totalRevenueCents;

    final repairCostByInventoryItemId = <String, int>{};
    for (final repair in repairTransactions) {
      repairCostByInventoryItemId.update(
        repair.inventoryItemId,
        (current) => current + repair.costCents,
        ifAbsent: () => repair.costCents,
      );
    }

    var openInventoryValueCents = 0;
    var openInventoryCostCents = 0;
    var inventoryCount = 0;
    var availableItems = 0;
    var brokenItems = 0;
    var ageTotalDays = 0;
    var agedInventoryCount = 0;

    final asOfDate = DateTime(asOf.year, asOf.month, asOf.day);

    for (final item in inventoryItems) {
      if (item.status == InventoryStatus.available) {
        availableItems += 1;
      }

      if (item.status == InventoryStatus.broken) {
        brokenItems += 1;
      }

      if (!_isOpenInventoryStatus(item.status)) {
        continue;
      }

      inventoryCount += 1;
      openInventoryValueCents += item.askingPriceCents ?? 0;

      final repairCostCents = item.id == null
          ? 0
          : repairCostByInventoryItemId[item.id!] ?? 0;

      openInventoryCostCents += item.acquisitionValueCents + repairCostCents;

      final purchaseDate = item.purchaseDate;
      if (purchaseDate != null) {
        final purchaseDateOnly = DateTime(
          purchaseDate.year,
          purchaseDate.month,
          purchaseDate.day,
        );
        final days = asOfDate.difference(purchaseDateOnly).inDays;
        ageTotalDays += days < 0 ? 0 : days;
        agedInventoryCount += 1;
      }
    }

    final openPotentialProfitCents =
        openInventoryValueCents - openInventoryCostCents;

    final averageDaysInInventory = agedInventoryCount == 0
        ? 0
        : (ageTotalDays / agedInventoryCount).round();

    return DashboardMetrics(
      totalRevenueCents: totalRevenueCents,
      totalCostCents: totalCostCents,
      totalProfitCents: totalProfitCents,
      grossMargin: grossMargin,
      openInventoryValueCents: openInventoryValueCents,
      openInventoryCostCents: openInventoryCostCents,
      openPotentialProfitCents: openPotentialProfitCents,
      inventoryCount: inventoryCount,
      unitsSold: unitsSold,
      availableItems: availableItems,
      averageDaysInInventory: averageDaysInInventory,
      brokenItems: brokenItems,
      dateRangeLabel: effectiveRange.label,
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
