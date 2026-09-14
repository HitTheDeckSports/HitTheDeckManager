import '../../../inventory/domain/models/inventory_item.dart';
import '../models/deal.dart';
import '../models/deal_status.dart';
import '../models/disposal_transaction.dart';
import '../models/repair_transaction.dart';
import '../models/sale_transaction.dart';
import '../models/trade_transaction.dart';
import '../models/warranty_replacement_deal.dart';

class DealRecursiveFinancialAnalysis {
  const DealRecursiveFinancialAnalysis({
    required this.deal,
    required this.status,
    required this.currentProfitCents,
    required this.projectedProfitCents,
    required this.totalCashReceivedCents,
    required this.totalCashPaidCents,
    required this.rootAcquisitionCostCents,
    required this.totalRepairCostCents,
    required this.projectedOpenInventoryValueCents,
    required this.openBranchCount,
    required this.branches,
  });

  final Deal deal;
  final DealStatus status;
  final int currentProfitCents;
  final int projectedProfitCents;
  final int totalCashReceivedCents;
  final int totalCashPaidCents;
  final int rootAcquisitionCostCents;
  final int totalRepairCostCents;
  final int projectedOpenInventoryValueCents;
  final int openBranchCount;
  final List<DealBranchFinancialAnalysis> branches;
}

class DealBranchFinancialAnalysis {
  const DealBranchFinancialAnalysis({
    required this.rootChildInventoryItemId,
    required this.realizedProfitCents,
    required this.projectedProfitCents,
    required this.cashReceivedCents,
    required this.cashPaidCents,
    required this.repairCostCents,
    required this.projectedOpenInventoryValueCents,
    required this.openInventoryCount,
  });

  final String rootChildInventoryItemId;
  final int realizedProfitCents;
  final int projectedProfitCents;
  final int cashReceivedCents;
  final int cashPaidCents;
  final int repairCostCents;
  final int projectedOpenInventoryValueCents;
  final int openInventoryCount;

  bool get isClosed => openInventoryCount == 0;
}

abstract final class DealRecursiveAnalysisService {
  static DealRecursiveFinancialAnalysis calculate({
    required Deal deal,
    required List<Deal> deals,
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> sales,
    required List<RepairTransaction> repairs,
    required List<DisposalTransaction> disposals,
    required List<TradeTransaction> trades,
    required List<WarrantyReplacementDeal> warrantyReplacements,
  }) {
    final calculator = _Calculator(
      deals: deals,
      inventoryItems: inventoryItems,
      sales: sales,
      repairs: repairs,
      disposals: disposals,
      trades: trades,
      warrantyReplacements: warrantyReplacements,
    );

    return calculator.calculate(deal);
  }
}

class _Calculator {
  _Calculator({
    required List<Deal> deals,
    required List<InventoryItem> inventoryItems,
    required List<SaleTransaction> sales,
    required List<RepairTransaction> repairs,
    required List<DisposalTransaction> disposals,
    required List<TradeTransaction> trades,
    required List<WarrantyReplacementDeal> warrantyReplacements,
  }) : _dealByParentSaleId = {
         for (final deal in deals) deal.parentSaleTransactionId: deal,
       },
       _itemById = {
         for (final item in inventoryItems)
           if (item.id != null) item.id!: item,
       },
       _saleById = {
         for (final sale in sales)
           if (sale.id != null) sale.id!: sale,
       },
       _saleByInventoryId = {
         for (final sale in sales) sale.inventoryItemId: sale,
       },
       _repairsByInventoryId = _groupRepairs(repairs),
       _disposalByInventoryId = {
         for (final disposal in disposals) disposal.inventoryItemId: disposal,
       },
       _tradeBySaleId = {
         for (final trade in trades)
           if (trade.saleTransactionId != null) trade.saleTransactionId!: trade,
       },
       _standaloneTradesByOutgoingId = _groupStandaloneTrades(trades),
       _warrantyByDisposedId = {
         for (final warranty in warrantyReplacements)
           warranty.disposedInventoryItemId: warranty,
       };

  final Map<String, Deal> _dealByParentSaleId;
  final Map<String, InventoryItem> _itemById;
  final Map<String, SaleTransaction> _saleById;
  final Map<String, SaleTransaction> _saleByInventoryId;
  final Map<String, List<RepairTransaction>> _repairsByInventoryId;
  final Map<String, DisposalTransaction> _disposalByInventoryId;
  final Map<String, TradeTransaction> _tradeBySaleId;
  final Map<String, List<TradeTransaction>> _standaloneTradesByOutgoingId;
  final Map<String, WarrantyReplacementDeal> _warrantyByDisposedId;

  DealRecursiveFinancialAnalysis calculate(Deal deal) {
    final visitingDeals = <String>{};
    final flow = _flowForDeal(deal, visitingDeals);

    final parentSale = _saleById[deal.parentSaleTransactionId];
    if (parentSale == null) {
      throw StateError(
        'The parent sale for Deal ${deal.id ?? deal.parentSaleTransactionId} is unavailable.',
      );
    }

    final rootItem = _itemById[parentSale.inventoryItemId];
    final rootBasis =
        parentSale.acquisitionValueCents ?? rootItem?.acquisitionValueCents;
    if (rootBasis == null) {
      throw StateError(
        'The original inventory basis for Deal ${deal.id ?? deal.parentSaleTransactionId} is unavailable.',
      );
    }

    final branches = <DealBranchFinancialAnalysis>[];
    var openBranchCount = 0;
    var anyBranchActivity = false;

    for (final childId in deal.childInventoryItemIds) {
      final child = _requireItem(childId);
      final branchFlow = _flowForItem(childId, <String>{}, visitingDeals);
      final realized =
          branchFlow.cashReceivedCents -
          branchFlow.cashPaidCents -
          child.acquisitionValueCents -
          branchFlow.repairCostCents;
      final projected = realized + branchFlow.projectedOpenInventoryValueCents;

      if (branchFlow.openInventoryCount > 0) {
        openBranchCount += 1;
      }
      if (branchFlow.activityCount > 0) {
        anyBranchActivity = true;
      }

      branches.add(
        DealBranchFinancialAnalysis(
          rootChildInventoryItemId: childId,
          realizedProfitCents: realized,
          projectedProfitCents: projected,
          cashReceivedCents: branchFlow.cashReceivedCents,
          cashPaidCents: branchFlow.cashPaidCents,
          repairCostCents: branchFlow.repairCostCents,
          projectedOpenInventoryValueCents:
              branchFlow.projectedOpenInventoryValueCents,
          openInventoryCount: branchFlow.openInventoryCount,
        ),
      );
    }

    final currentProfit =
        flow.cashReceivedCents -
        flow.cashPaidCents -
        rootBasis -
        flow.repairCostCents;
    final projectedProfit =
        currentProfit + flow.projectedOpenInventoryValueCents;

    final status = openBranchCount == 0
        ? DealStatus.completed
        : anyBranchActivity
        ? DealStatus.partiallyRealized
        : DealStatus.open;

    return DealRecursiveFinancialAnalysis(
      deal: deal,
      status: status,
      currentProfitCents: currentProfit,
      projectedProfitCents: projectedProfit,
      totalCashReceivedCents: flow.cashReceivedCents,
      totalCashPaidCents: flow.cashPaidCents,
      rootAcquisitionCostCents: rootBasis,
      totalRepairCostCents: flow.repairCostCents,
      projectedOpenInventoryValueCents: flow.projectedOpenInventoryValueCents,
      openBranchCount: openBranchCount,
      branches: List.unmodifiable(branches),
    );
  }

  _FlowTotals _flowForDeal(Deal deal, Set<String> visitingDeals) {
    final identity = deal.id ?? deal.parentSaleTransactionId;
    if (!visitingDeals.add(identity)) {
      throw StateError('Deal hierarchy contains a cycle involving $identity.');
    }

    final parentSale = _saleById[deal.parentSaleTransactionId];
    if (parentSale == null) {
      throw StateError(
        'The parent sale for Deal ${deal.id ?? deal.parentSaleTransactionId} is unavailable.',
      );
    }

    var result = _FlowTotals(
      cashReceivedCents: parentSale.cashReceivedCents,
      cashPaidCents: _tradeBySaleId[parentSale.id]?.cashPaidCents ?? 0,
      repairCostCents: _repairCost(parentSale.inventoryItemId),
      activityCount: 1,
    );

    for (final childId in deal.childInventoryItemIds) {
      result += _flowForItem(childId, <String>{}, visitingDeals);
    }

    visitingDeals.remove(identity);
    return result;
  }

  _FlowTotals _flowForItem(
    String itemId,
    Set<String> visitingItems,
    Set<String> visitingDeals,
  ) {
    if (!visitingItems.add(itemId)) {
      throw StateError('Deal inventory lineage contains a cycle at $itemId.');
    }

    final item = _requireItem(itemId);
    final sale = _saleByInventoryId[itemId];

    if (sale != null) {
      final nestedDeal = sale.id == null ? null : _dealByParentSaleId[sale.id!];
      visitingItems.remove(itemId);

      if (nestedDeal != null) {
        return _flowForDeal(nestedDeal, visitingDeals);
      }

      return _FlowTotals(
        cashReceivedCents: sale.cashReceivedCents,
        cashPaidCents: _tradeBySaleId[sale.id]?.cashPaidCents ?? 0,
        repairCostCents: _repairCost(itemId),
        activityCount: 1,
      );
    }

    final disposal = _disposalByInventoryId[itemId];
    if (disposal != null) {
      final warranty = _warrantyByDisposedId[itemId];
      var result = _FlowTotals(
        repairCostCents: _repairCost(itemId),
        activityCount: 1,
      );

      if (warranty != null) {
        result += _flowForItem(
          warranty.replacementInventoryItemId,
          visitingItems,
          visitingDeals,
        );
      }

      visitingItems.remove(itemId);
      return result;
    }

    final standaloneTrades =
        _standaloneTradesByOutgoingId[itemId] ?? const <TradeTransaction>[];
    if (standaloneTrades.isNotEmpty) {
      var result = _FlowTotals(repairCostCents: _repairCost(itemId));

      for (final trade in standaloneTrades) {
        result += _FlowTotals(
          cashReceivedCents: trade.cashReceivedCents,
          cashPaidCents: trade.cashPaidCents,
          activityCount: 1,
        );
        for (final incomingId in trade.incomingInventoryItemIds) {
          result += _flowForItem(incomingId, visitingItems, visitingDeals);
        }
      }

      visitingItems.remove(itemId);
      return result;
    }

    visitingItems.remove(itemId);
    return _FlowTotals(
      repairCostCents: _repairCost(itemId),
      projectedOpenInventoryValueCents: item.askingPriceCents ?? 0,
      openInventoryCount: 1,
    );
  }

  InventoryItem _requireItem(String id) {
    final item = _itemById[id];
    if (item == null) {
      throw StateError('Deal inventory item $id is unavailable.');
    }
    return item;
  }

  int _repairCost(String inventoryItemId) {
    return (_repairsByInventoryId[inventoryItemId] ??
            const <RepairTransaction>[])
        .fold<int>(0, (sum, repair) => sum + repair.costCents);
  }
}

class _FlowTotals {
  const _FlowTotals({
    this.cashReceivedCents = 0,
    this.cashPaidCents = 0,
    this.repairCostCents = 0,
    this.projectedOpenInventoryValueCents = 0,
    this.openInventoryCount = 0,
    this.activityCount = 0,
  });

  final int cashReceivedCents;
  final int cashPaidCents;
  final int repairCostCents;
  final int projectedOpenInventoryValueCents;
  final int openInventoryCount;
  final int activityCount;

  _FlowTotals operator +(_FlowTotals other) {
    return _FlowTotals(
      cashReceivedCents: cashReceivedCents + other.cashReceivedCents,
      cashPaidCents: cashPaidCents + other.cashPaidCents,
      repairCostCents: repairCostCents + other.repairCostCents,
      projectedOpenInventoryValueCents:
          projectedOpenInventoryValueCents +
          other.projectedOpenInventoryValueCents,
      openInventoryCount: openInventoryCount + other.openInventoryCount,
      activityCount: activityCount + other.activityCount,
    );
  }
}

Map<String, List<RepairTransaction>> _groupRepairs(
  List<RepairTransaction> repairs,
) {
  final result = <String, List<RepairTransaction>>{};
  for (final repair in repairs) {
    result.putIfAbsent(repair.inventoryItemId, () => []).add(repair);
  }
  return result;
}

Map<String, List<TradeTransaction>> _groupStandaloneTrades(
  List<TradeTransaction> trades,
) {
  final result = <String, List<TradeTransaction>>{};
  for (final trade in trades) {
    if (trade.saleTransactionId != null) continue;
    for (final outgoingId in trade.outgoingInventoryItemIds) {
      result.putIfAbsent(outgoingId, () => []).add(trade);
    }
  }
  return result;
}
