import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/deal.dart';
import '../../transactions/domain/models/repair_transaction.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import 'deal_rollup_report.dart';
import 'financial_performance_report.dart';
import 'inventory_aging_report.dart';
import 'report_date_range.dart';
import 'sales_analysis_report.dart';

class ReportsSnapshot {
  const ReportsSnapshot({
    required this.financialPerformance,
    required this.salesByCategory,
    required this.salesByBrand,
    required this.salesByModel,
    required this.inventoryAging,
    required this.deals,
  });

  final FinancialPerformanceReport financialPerformance;
  final SalesAnalysisReport salesByCategory;
  final SalesAnalysisReport salesByBrand;
  final SalesAnalysisReport salesByModel;
  final InventoryAgingReport inventoryAging;
  final DealRollupReport deals;

  factory ReportsSnapshot.calculate({
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> sales,
    required List<RepairTransaction> repairs,
    required List<Deal> deals,
    required DateTime asOf,
    required ReportDateRange dateRange,
    int dealMaxDepth = 10,
  }) {
    return ReportsSnapshot(
      financialPerformance: FinancialPerformanceReport.calculate(
        sales: sales,
        dateRange: dateRange,
      ),
      salesByCategory: SalesAnalysisReport.calculate(
        dimension: SalesAnalysisDimension.category,
        inventoryItems: inventoryItems,
        sales: sales,
        dateRange: dateRange,
      ),
      salesByBrand: SalesAnalysisReport.calculate(
        dimension: SalesAnalysisDimension.brand,
        inventoryItems: inventoryItems,
        sales: sales,
        dateRange: dateRange,
      ),
      salesByModel: SalesAnalysisReport.calculate(
        dimension: SalesAnalysisDimension.model,
        inventoryItems: inventoryItems,
        sales: sales,
        dateRange: dateRange,
      ),
      inventoryAging: InventoryAgingReport.calculate(
        inventoryItems: inventoryItems,
        repairs: repairs,
        asOf: asOf,
      ),
      deals: DealRollupReport.calculate(
        deals: deals,
        inventoryItems: inventoryItems,
        sales: sales,
        repairs: repairs,
        maxDepth: dealMaxDepth,
      ),
    );
  }
}
