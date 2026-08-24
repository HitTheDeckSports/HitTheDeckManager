import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/deal.dart';
import '../../transactions/domain/models/deal_status.dart';
import '../../transactions/domain/models/repair_transaction.dart';
import '../../transactions/domain/models/sale_transaction.dart';

class DealRollupReportRow {
  const DealRollupReportRow({
    required this.deal,
    required this.status,
    required this.realizedProfitCents,
    required this.projectedProfitCents,
    required this.realizedInventoryCount,
    required this.openInventoryCount,
    required this.descendantDealCount,
    required this.cycleDetected,
    required this.depthLimitReached,
    required this.inventoryItemIds,
    required this.dealKeys,
  });

  final Deal deal;
  final DealStatus status;
  final int realizedProfitCents;
  final int projectedProfitCents;
  final int realizedInventoryCount;
  final int openInventoryCount;
  final int descendantDealCount;
  final bool cycleDetected;
  final bool depthLimitReached;
  final List<String> inventoryItemIds;
  final List<String> dealKeys;
}

class DealRollupReport {
  const DealRollupReport({required this.rows});
  final List<DealRollupReportRow> rows;

  factory DealRollupReport.calculate({
    required List<Deal> deals,
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> sales,
    required List<RepairTransaction> repairs,
    int maxDepth = 10,
  }) {
    if (maxDepth < 0) {
      throw ArgumentError.value(maxDepth, 'maxDepth', 'Must be non-negative.');
    }

    final inventoryById = <String, InventoryItem>{
      for (final item in inventoryItems)
        if (item.id != null) item.id!: item,
    };
    final saleById = <String, SaleTransaction>{
      for (final sale in sales)
        if (sale.id != null) sale.id!: sale,
    };
    final saleByInventoryId = <String, SaleTransaction>{
      for (final sale in sales) sale.inventoryItemId: sale,
    };
    final dealByParentSaleId = <String, Deal>{
      for (final deal in deals) deal.parentSaleTransactionId: deal,
    };
    final repairCostByItemId = <String, int>{};
    for (final repair in repairs) {
      repairCostByItemId.update(
        repair.inventoryItemId,
        (value) => value + repair.costCents,
        ifAbsent: () => repair.costCents,
      );
    }

    final childInventoryIds = <String>{
      for (final deal in deals) ...deal.childInventoryItemIds,
    };
    final roots = <Deal>[];
    for (final deal in deals) {
      final parentSale = saleById[deal.parentSaleTransactionId];
      final nested =
          parentSale != null &&
          childInventoryIds.contains(parentSale.inventoryItemId);
      if (!nested) roots.add(deal);
    }
    if (roots.isEmpty && deals.isNotEmpty) roots.addAll(deals);

    final rows = <DealRollupReportRow>[];
    final covered = <String>{};
    for (final deal in roots) {
      final row = _calculateOne(
        deal: deal,
        inventoryById: inventoryById,
        saleById: saleById,
        saleByInventoryId: saleByInventoryId,
        dealByParentSaleId: dealByParentSaleId,
        repairCostByItemId: repairCostByItemId,
        maxDepth: maxDepth,
      );
      rows.add(row);
      covered.addAll(row.dealKeys);
    }

    for (final deal in deals) {
      if (covered.contains(_dealKey(deal))) continue;
      rows.add(
        _calculateOne(
          deal: deal,
          inventoryById: inventoryById,
          saleById: saleById,
          saleByInventoryId: saleByInventoryId,
          dealByParentSaleId: dealByParentSaleId,
          repairCostByItemId: repairCostByItemId,
          maxDepth: maxDepth,
        ),
      );
    }

    return DealRollupReport(rows: List.unmodifiable(rows));
  }

  static DealRollupReportRow _calculateOne({
    required Deal deal,
    required Map<String, InventoryItem> inventoryById,
    required Map<String, SaleTransaction> saleById,
    required Map<String, SaleTransaction> saleByInventoryId,
    required Map<String, Deal> dealByParentSaleId,
    required Map<String, int> repairCostByItemId,
    required int maxDepth,
  }) {
    final parentSale = saleById[deal.parentSaleTransactionId];
    if (parentSale == null) {
      throw StateError(
        'The parent sale for Deal ${_dealKey(deal)} is unavailable.',
      );
    }
    final parentProfit = parentSale.profitCents;
    if (parentProfit == null) {
      throw StateError(
        'The parent sale for Deal ${_dealKey(deal)} has no profit data.',
      );
    }

    final state = _RollupState(realizedProfitCents: parentProfit);
    _visitDeal(
      deal: deal,
      depth: 0,
      state: state,
      activePath: <String>{},
      inventoryById: inventoryById,
      saleByInventoryId: saleByInventoryId,
      dealByParentSaleId: dealByParentSaleId,
      repairCostByItemId: repairCostByItemId,
      maxDepth: maxDepth,
    );

    final status = switch ((
      state.realizedInventoryCount,
      state.openInventoryCount,
    )) {
      (0, _) => DealStatus.open,
      (_, 0) => DealStatus.completed,
      _ => DealStatus.partiallyRealized,
    };

    return DealRollupReportRow(
      deal: deal,
      status: status,
      realizedProfitCents: state.realizedProfitCents,
      projectedProfitCents:
          state.realizedProfitCents + state.projectedOpenProfitCents,
      realizedInventoryCount: state.realizedInventoryCount,
      openInventoryCount: state.openInventoryCount,
      descendantDealCount: state.dealKeys.length - 1,
      cycleDetected: state.cycleDetected,
      depthLimitReached: state.depthLimitReached,
      inventoryItemIds: List.unmodifiable(state.inventoryItemIds),
      dealKeys: List.unmodifiable(state.dealKeys),
    );
  }

  static void _visitDeal({
    required Deal deal,
    required int depth,
    required _RollupState state,
    required Set<String> activePath,
    required Map<String, InventoryItem> inventoryById,
    required Map<String, SaleTransaction> saleByInventoryId,
    required Map<String, Deal> dealByParentSaleId,
    required Map<String, int> repairCostByItemId,
    required int maxDepth,
  }) {
    final key = _dealKey(deal);
    if (activePath.contains(key)) {
      state.cycleDetected = true;
      return;
    }

    activePath.add(key);
    if (!state.dealKeys.contains(key)) {
      state.dealKeys.add(key);
    }

    for (final childId in deal.childInventoryItemIds) {
      if (!state.inventoryItemIds.contains(childId)) {
        state.inventoryItemIds.add(childId);
      }
      final item = inventoryById[childId];
      if (item == null) {
        throw StateError('Deal child inventory item $childId is unavailable.');
      }

      final childSale = saleByInventoryId[childId];
      if (childSale == null) {
        state.openInventoryCount += 1;
        final asking = item.askingPriceCents;
        if (asking != null) {
          final repairCost = repairCostByItemId[childId] ?? 0;
          state.projectedOpenProfitCents +=
              asking - item.acquisitionValueCents - repairCost;
        }
        continue;
      }

      state.realizedInventoryCount += 1;
      final childProfit = childSale.profitCents;
      if (childProfit == null) {
        throw StateError(
          'Child sale ${childSale.id ?? childId} has no profit data.',
        );
      }
      state.realizedProfitCents += childProfit;

      final childSaleId = childSale.id;
      if (childSaleId == null) continue;
      final nestedDeal = dealByParentSaleId[childSaleId];
      if (nestedDeal == null) continue;

      if (depth >= maxDepth) {
        state.depthLimitReached = true;
        continue;
      }

      _visitDeal(
        deal: nestedDeal,
        depth: depth + 1,
        state: state,
        activePath: activePath,
        inventoryById: inventoryById,
        saleByInventoryId: saleByInventoryId,
        dealByParentSaleId: dealByParentSaleId,
        repairCostByItemId: repairCostByItemId,
        maxDepth: maxDepth,
      );
    }

    activePath.remove(key);
  }

  static String _dealKey(Deal deal) =>
      deal.id ?? 'parent:${deal.parentSaleTransactionId}';
}

class _RollupState {
  _RollupState({required this.realizedProfitCents});
  int realizedProfitCents;
  int projectedOpenProfitCents = 0;
  int realizedInventoryCount = 0;
  int openInventoryCount = 0;
  bool cycleDetected = false;
  bool depthLimitReached = false;
  final inventoryItemIds = <String>[];
  final dealKeys = <String>[];
}
