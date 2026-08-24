import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import 'report_date_range.dart';

enum SalesAnalysisDimension { category, brand, model }

class SalesAnalysisRow {
  const SalesAnalysisRow({
    required this.label,
    required this.units,
    required this.revenueCents,
    required this.profitCents,
    required this.inventoryItemIds,
  });

  final String label;
  final int units;
  final int revenueCents;
  final int profitCents;
  final List<String> inventoryItemIds;
}

class SalesAnalysisReport {
  const SalesAnalysisReport({required this.dimension, required this.rows});

  final SalesAnalysisDimension dimension;
  final List<SalesAnalysisRow> rows;

  factory SalesAnalysisReport.calculate({
    required SalesAnalysisDimension dimension,
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> sales,
    required ReportDateRange dateRange,
  }) {
    final inventoryById = <String, InventoryItem>{
      for (final item in inventoryItems)
        if (item.id != null) item.id!: item,
    };
    final groups = <String, _MutableSalesRow>{};

    for (final sale in sales) {
      if (!dateRange.contains(sale.saleDate)) continue;
      final item = inventoryById[sale.inventoryItemId];
      final label = _labelFor(dimension, item);
      final row = groups.putIfAbsent(label, _MutableSalesRow.new);
      row.units += 1;
      row.revenueCents += sale.salePriceCents;
      row.profitCents += sale.profitCents ?? 0;
      row.inventoryItemIds.add(sale.inventoryItemId);
    }

    final rows =
        groups.entries
            .map(
              (entry) => SalesAnalysisRow(
                label: entry.key,
                units: entry.value.units,
                revenueCents: entry.value.revenueCents,
                profitCents: entry.value.profitCents,
                inventoryItemIds: List.unmodifiable(
                  entry.value.inventoryItemIds,
                ),
              ),
            )
            .toList()
          ..sort((a, b) {
            final byRevenue = b.revenueCents.compareTo(a.revenueCents);
            return byRevenue != 0
                ? byRevenue
                : a.label.toLowerCase().compareTo(b.label.toLowerCase());
          });

    return SalesAnalysisReport(
      dimension: dimension,
      rows: List.unmodifiable(rows),
    );
  }

  static String _labelFor(
    SalesAnalysisDimension dimension,
    InventoryItem? item,
  ) {
    if (item == null) return 'Unknown';
    return switch (dimension) {
      SalesAnalysisDimension.category => item.category.label,
      SalesAnalysisDimension.brand =>
        item.brand.trim().isEmpty ? 'Unknown Brand' : item.brand.trim(),
      SalesAnalysisDimension.model =>
        (item.model ?? '').trim().isEmpty
            ? 'Unknown Model'
            : item.model!.trim(),
    };
  }
}

class _MutableSalesRow {
  int units = 0;
  int revenueCents = 0;
  int profitCents = 0;
  final inventoryItemIds = <String>[];
}
