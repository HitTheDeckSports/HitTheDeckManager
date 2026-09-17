import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/deal.dart';
import '../../transactions/domain/models/deal_lineage_tree.dart';
import '../../transactions/domain/models/deal_tree_profit_summary.dart';
import '../../transactions/domain/models/disposal_transaction.dart';
import '../../transactions/domain/models/repair_transaction.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import '../../transactions/domain/models/trade_transaction.dart';
import '../../transactions/domain/models/warranty_replacement_deal.dart';
import '../../transactions/domain/services/deal_lineage_service.dart';
import '../../transactions/domain/models/deal_status.dart';
import '../../transactions/domain/services/deal_tree_profit_service.dart';
import '../../transactions/domain/services/deal_recursive_analysis_service.dart';

class RecursiveDealReportRow {
  RecursiveDealReportRow({
    required this.deal,
    required this.parentSale,
    required this.parentInventoryItem,
    required this.tree,
    required this.summary,
    required List<InventoryItem> lineageInventoryItems,
    this.recursiveAnalysis,
    this.displayNumber,
  }) : lineageInventoryItems = List.unmodifiable(lineageInventoryItems),
       _inventoryById = {
         for (final item in lineageInventoryItems)
           if (item.id != null) item.id!: item,
       };

  final Deal deal;
  final SaleTransaction parentSale;
  final InventoryItem? parentInventoryItem;
  final DealLineageTree tree;
  final DealTreeProfitSummary summary;
  final DealRecursiveFinancialAnalysis? recursiveAnalysis;
  final String? displayNumber;
  final List<InventoryItem> lineageInventoryItems;
  final Map<String, InventoryItem> _inventoryById;

  DealStatus get status => recursiveAnalysis?.status ?? summary.status;

  int get currentProfitCents =>
      recursiveAnalysis?.currentProfitCents ?? summary.realizedDealProfitCents;

  int get projectedProfitCents =>
      recursiveAnalysis?.projectedProfitCents ??
      summary.projectedDealProfitCents;

  int get openBranchCount =>
      recursiveAnalysis?.openBranchCount ??
      summary.branches.where((branch) => branch.openInventoryCount > 0).length;

  InventoryItem? inventoryItemFor(String inventoryItemId) {
    return _inventoryById[inventoryItemId];
  }
}

class RecursiveDealReport {
  const RecursiveDealReport({required this.rows});

  final List<RecursiveDealReportRow> rows;

  factory RecursiveDealReport.calculate({
    required List<Deal> deals,
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> sales,
    required List<RepairTransaction> repairs,
    required List<TradeTransaction> trades,
    required List<DisposalTransaction> disposals,
    required List<WarrantyReplacementDeal> warrantyReplacements,
  }) {
    final inventoryById = <String, InventoryItem>{
      for (final item in inventoryItems)
        if (item.id != null) item.id!: item,
    };

    final saleById = <String, SaleTransaction>{
      for (final sale in sales)
        if (sale.id != null) sale.id!: sale,
    };

    final rows = <RecursiveDealReportRow>[];
    final displayNumbers = _dealDisplayNumbers(deals);

    for (final deal in deals) {
      final parentSale = saleById[deal.parentSaleTransactionId];
      if (parentSale == null) {
        throw StateError(
          'The parent sale for Deal '
          '${deal.id ?? deal.parentSaleTransactionId} is unavailable.',
        );
      }

      final lineageIds = deal.effectiveLineageInventoryItemIds.toSet();

      final lineageItems = <InventoryItem>[];
      for (final inventoryItemId in deal.effectiveLineageInventoryItemIds) {
        final item = inventoryById[inventoryItemId];
        if (item == null) {
          throw StateError(
            'Deal-lineage inventory item $inventoryItemId is unavailable.',
          );
        }
        lineageItems.add(item);
      }

      final lineageSales = sales
          .where((sale) => lineageIds.contains(sale.inventoryItemId))
          .toList(growable: false);

      final lineageRepairs = repairs
          .where((repair) => lineageIds.contains(repair.inventoryItemId))
          .toList(growable: false);

      final lineageTrades = trades
          .where((trade) {
            return trade.outgoingInventoryItemIds.any(lineageIds.contains) ||
                trade.incomingInventoryItemIds.any(lineageIds.contains);
          })
          .toList(growable: false);

      final lineageDisposals = disposals
          .where((disposal) => lineageIds.contains(disposal.inventoryItemId))
          .toList(growable: false);

      final lineageWarranties = warrantyReplacements
          .where((warranty) {
            return lineageIds.contains(warranty.disposedInventoryItemId) ||
                lineageIds.contains(warranty.replacementInventoryItemId);
          })
          .toList(growable: false);

      final tree = DealLineageService.build(
        deal: deal,
        trades: lineageTrades,
        warrantyReplacements: lineageWarranties,
      );

      final summary = DealTreeProfitService.calculate(
        tree: tree,
        parentSale: parentSale,
        lineageInventoryItems: lineageItems,
        lineageSales: lineageSales,
        lineageRepairs: lineageRepairs,
        lineageDisposals: lineageDisposals,
        warrantyReplacements: lineageWarranties,
      );

      final recursiveAnalysis = DealRecursiveAnalysisService.calculate(
        deal: deal,
        deals: deals,
        inventoryItems: inventoryItems,
        sales: sales,
        repairs: repairs,
        disposals: disposals,
        trades: trades,
        warrantyReplacements: warrantyReplacements,
      );

      rows.add(
        RecursiveDealReportRow(
          deal: deal,
          parentSale: parentSale,
          parentInventoryItem: inventoryById[parentSale.inventoryItemId],
          tree: tree,
          summary: summary,
          lineageInventoryItems: lineageItems,
          recursiveAnalysis: recursiveAnalysis,
          displayNumber: deal.id == null ? null : displayNumbers[deal.id!],
        ),
      );
    }

    return RecursiveDealReport(rows: List.unmodifiable(rows));
  }
}

Map<String, String> _dealDisplayNumbers(List<Deal> deals) {
  final result = <String, String>{};
  final byYear = <int, List<Deal>>{};

  for (final deal in deals) {
    final id = deal.id;
    final createdAt = deal.createdAt;
    if (id == null || createdAt == null) {
      continue;
    }
    byYear.putIfAbsent(createdAt.year, () => <Deal>[]).add(deal);
  }

  for (final entry in byYear.entries) {
    final yearDeals = entry.value
      ..sort((first, second) {
        final timeComparison = first.createdAt!.compareTo(second.createdAt!);
        if (timeComparison != 0) {
          return timeComparison;
        }
        return (first.id ?? '').compareTo(second.id ?? '');
      });

    for (var index = 0; index < yearDeals.length; index++) {
      final id = yearDeals[index].id;
      if (id == null) {
        continue;
      }
      result[id] = '${entry.key}-${(index + 1).toString().padLeft(3, '0')}';
    }
  }

  return result;
}
