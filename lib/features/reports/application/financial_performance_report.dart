import '../../transactions/domain/models/sale_transaction.dart';
import 'report_date_range.dart';

class FinancialTrendPoint {
  const FinancialTrendPoint({
    required this.month,
    required this.revenueCents,
    required this.costCents,
    required this.profitCents,
    required this.unitsSold,
  });

  final DateTime month;
  final int revenueCents;
  final int costCents;
  final int profitCents;
  final int unitsSold;
}

class FinancialPerformanceReport {
  const FinancialPerformanceReport({
    required this.rangeLabel,
    required this.revenueCents,
    required this.costCents,
    required this.profitCents,
    required this.grossMargin,
    required this.unitsSold,
    required this.monthlyTrend,
    required this.saleIds,
  });

  final String rangeLabel;
  final int revenueCents;
  final int costCents;
  final int profitCents;
  final double grossMargin;
  final int unitsSold;
  final List<FinancialTrendPoint> monthlyTrend;
  final List<String> saleIds;

  factory FinancialPerformanceReport.calculate({
    required List<SaleTransaction> sales,
    required ReportDateRange dateRange,
  }) {
    var revenue = 0;
    var cost = 0;
    var units = 0;
    final saleIds = <String>[];
    final monthly = <DateTime, _MutableTrend>{};

    for (final sale in sales) {
      if (!dateRange.contains(sale.saleDate)) continue;
      final saleCost = sale.totalCostBasisCents ?? 0;
      final month = DateTime(sale.saleDate.year, sale.saleDate.month);
      revenue += sale.salePriceCents;
      cost += saleCost;
      units += 1;
      if (sale.id != null) saleIds.add(sale.id!);
      final trend = monthly.putIfAbsent(month, _MutableTrend.new);
      trend.revenueCents += sale.salePriceCents;
      trend.costCents += saleCost;
      trend.unitsSold += 1;
    }

    final profit = revenue - cost;
    final trendPoints =
        monthly.entries
            .map(
              (entry) => FinancialTrendPoint(
                month: entry.key,
                revenueCents: entry.value.revenueCents,
                costCents: entry.value.costCents,
                profitCents: entry.value.revenueCents - entry.value.costCents,
                unitsSold: entry.value.unitsSold,
              ),
            )
            .toList()
          ..sort((a, b) => a.month.compareTo(b.month));

    return FinancialPerformanceReport(
      rangeLabel: dateRange.label,
      revenueCents: revenue,
      costCents: cost,
      profitCents: profit,
      grossMargin: revenue == 0 ? 0 : profit / revenue,
      unitsSold: units,
      monthlyTrend: List.unmodifiable(trendPoints),
      saleIds: List.unmodifiable(saleIds),
    );
  }
}

class _MutableTrend {
  int revenueCents = 0;
  int costCents = 0;
  int unitsSold = 0;
}
