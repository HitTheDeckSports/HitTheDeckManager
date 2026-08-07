import '../../../inventory/domain/models/inventory_item.dart';
import '../models/deal.dart';
import '../models/deal_status.dart';
import '../models/deal_summary.dart';
import '../models/sale_transaction.dart';

abstract final class DealProfitService {
  static DealSummary calculate({
    required Deal deal,
    required SaleTransaction parentSale,
    required List<InventoryItem> childInventoryItems,
    required List<SaleTransaction> childSales,
  }) {
    if (!deal.isValid) {
      throw StateError('The Deal contains invalid relationship information.');
    }

    if (parentSale.id != deal.parentSaleTransactionId) {
      throw StateError('The parent sale does not match the Deal.');
    }

    final parentProfit = parentSale.profitCents;

    if (parentProfit == null) {
      throw StateError('The parent sale does not contain profit data.');
    }

    final childById = <String, InventoryItem>{
      for (final item in childInventoryItems)
        if (item.id != null) item.id!: item,
    };

    final saleByInventoryId = <String, SaleTransaction>{
      for (final sale in childSales) sale.inventoryItemId: sale,
    };

    var realizedChildProfit = 0;
    var projectedChildProfit = 0;
    var realizedChildCount = 0;
    var openChildCount = 0;

    for (final childId in deal.childInventoryItemIds) {
      final childItem = childById[childId];

      if (childItem == null) {
        throw StateError('Deal child inventory item $childId is unavailable.');
      }

      final childSale = saleByInventoryId[childId];

      if (childSale != null) {
        final childProfit = childSale.profitCents;

        if (childProfit == null) {
          throw StateError(
            'Child sale ${childSale.id ?? childId} does not contain profit data.',
          );
        }

        realizedChildProfit += childProfit;
        realizedChildCount += 1;
        continue;
      }

      openChildCount += 1;

      final askingPrice = childItem.askingPriceCents;

      if (askingPrice != null) {
        projectedChildProfit += askingPrice - childItem.acquisitionValueCents;
      }
    }

    final status = switch ((realizedChildCount, openChildCount)) {
      (0, _) => DealStatus.open,
      (_, 0) => DealStatus.completed,
      _ => DealStatus.partiallyRealized,
    };

    final realizedDealProfit = parentProfit + realizedChildProfit;
    final projectedDealProfit = realizedDealProfit + projectedChildProfit;

    return DealSummary(
      deal: deal,
      status: status,
      parentTransactionProfitCents: parentProfit,
      realizedChildProfitCents: realizedChildProfit,
      projectedChildProfitCents: projectedChildProfit,
      realizedDealProfitCents: realizedDealProfit,
      projectedDealProfitCents: projectedDealProfit,
      realizedChildCount: realizedChildCount,
      openChildCount: openChildCount,
    );
  }
}
