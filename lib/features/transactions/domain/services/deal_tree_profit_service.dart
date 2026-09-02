import '../../../inventory/domain/models/inventory_item.dart';
import '../models/deal_branch_summary.dart';
import '../models/deal_lineage_tree.dart';
import '../models/deal_tree_profit_summary.dart';
import '../models/disposal_transaction.dart';
import '../models/repair_transaction.dart';
import '../models/sale_transaction.dart';
import '../models/warranty_replacement_deal.dart';

abstract final class DealTreeProfitService {
  static DealTreeProfitSummary calculate({
    required DealLineageTree tree,
    required SaleTransaction parentSale,
    required List<InventoryItem> lineageInventoryItems,
    required List<SaleTransaction> lineageSales,
    required List<RepairTransaction> lineageRepairs,
    required List<DisposalTransaction> lineageDisposals,
    required List<WarrantyReplacementDeal> warrantyReplacements,
  }) {
    if (parentSale.id != tree.deal.parentSaleTransactionId) {
      throw StateError('The parent sale does not match the Deal.');
    }

    final parentProfit = parentSale.profitCents;
    if (parentProfit == null) {
      throw StateError('The parent sale does not contain profit data.');
    }

    final itemById = <String, InventoryItem>{
      for (final item in lineageInventoryItems)
        if (item.id != null) item.id!: item,
    };

    final saleByInventoryId = <String, SaleTransaction>{};
    for (final sale in lineageSales) {
      if (saleByInventoryId.containsKey(sale.inventoryItemId)) {
        throw StateError(
          'Inventory item ${sale.inventoryItemId} has multiple sale records.',
        );
      }
      saleByInventoryId[sale.inventoryItemId] = sale;
    }

    final disposalByInventoryId = <String, DisposalTransaction>{};
    for (final disposal in lineageDisposals) {
      if (disposalByInventoryId.containsKey(disposal.inventoryItemId)) {
        throw StateError(
          'Inventory item ${disposal.inventoryItemId} has multiple disposal records.',
        );
      }
      disposalByInventoryId[disposal.inventoryItemId] = disposal;
    }

    final repairCostByInventoryId = <String, int>{};
    for (final repair in lineageRepairs) {
      repairCostByInventoryId.update(
        repair.inventoryItemId,
        (current) => current + repair.costCents,
        ifAbsent: () => repair.costCents,
      );
    }

    final warrantyReplacementByDisposedId = <String, WarrantyReplacementDeal>{
      for (final warranty in warrantyReplacements)
        warranty.disposedInventoryItemId: warranty,
    };

    final branches = <DealBranchSummary>[];

    for (final directChild in tree.directChildren) {
      var realizedProfit = 0;
      var projectedOpenProfit = 0;
      var realizedSaleCount = 0;
      var standardDisposalCount = 0;
      var openInventoryCount = 0;

      for (final node in tree.branchFor(directChild.inventoryItemId)) {
        final item = itemById[node.inventoryItemId];
        if (item == null) {
          throw StateError(
            'Deal-lineage inventory item ${node.inventoryItemId} is unavailable.',
          );
        }

        final sale = saleByInventoryId[node.inventoryItemId];
        final disposal = disposalByInventoryId[node.inventoryItemId];
        final repairCost = repairCostByInventoryId[node.inventoryItemId] ?? 0;

        if (sale != null && disposal != null) {
          throw StateError(
            'Inventory item ${node.inventoryItemId} cannot be both sold and disposed.',
          );
        }

        if (sale != null) {
          final saleProfit = sale.profitCents;
          if (saleProfit == null) {
            throw StateError(
              'Sale ${sale.id ?? node.inventoryItemId} does not contain profit data.',
            );
          }

          realizedProfit += saleProfit;
          realizedSaleCount += 1;
          continue;
        }

        if (disposal != null) {
          final warranty =
              warrantyReplacementByDisposedId[node.inventoryItemId];

          if (warranty != null) {
            // The acquisition basis continues into the warranty replacement,
            // but repairs already spent on the replaced physical item are
            // permanently incurred and must remain in branch profitability.
            realizedProfit -= repairCost;
            continue;
          }

          // A non-warranty disposal closes this item with no revenue.
          realizedProfit -= item.acquisitionValueCents + repairCost;
          standardDisposalCount += 1;
          continue;
        }

        openInventoryCount += 1;

        final askingPrice = item.askingPriceCents;
        if (askingPrice != null) {
          projectedOpenProfit +=
              askingPrice - item.acquisitionValueCents - repairCost;
        }
      }

      branches.add(
        DealBranchSummary(
          rootChildInventoryItemId: directChild.inventoryItemId,
          realizedProfitCents: realizedProfit,
          projectedOpenProfitCents: projectedOpenProfit,
          realizedSaleCount: realizedSaleCount,
          standardDisposalCount: standardDisposalCount,
          openInventoryCount: openInventoryCount,
        ),
      );
    }

    return DealTreeProfitSummary(
      deal: tree.deal,
      parentTransactionProfitCents: parentProfit,
      branches: branches,
    );
  }
}
