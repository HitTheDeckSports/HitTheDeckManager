import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/deal.dart';
import '../../domain/models/deal_status.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/services/deal_recursive_analysis_service.dart';
import 'deal_providers.dart';
import 'transaction_providers.dart';
import 'warranty_replacement_providers.dart';

final dealLedgerSummariesProvider = FutureProvider<List<DealLedgerSummary>>((
  ref,
) async {
  // Register the Deals dependency synchronously. When the stream is still
  // loading, await only that already-watched dependency. Riverpod will rebuild
  // this provider when the Deals stream emits its value.
  final dealsAsync = ref.watch(dealsProvider);

  if (dealsAsync.hasError) {
    throw dealsAsync.error!;
  }

  if (!dealsAsync.hasValue) {
    await ref.watch(dealsProvider.future);
    return const <DealLedgerSummary>[];
  }

  final deals = dealsAsync.requireValue;
  if (deals.isEmpty) {
    return const <DealLedgerSummary>[];
  }

  // Register every remaining reactive dependency before the first await.
  // Watching providers after an async gap can allow the earlier dependency to
  // be disposed before a value is emitted in ProviderContainer tests.
  final inventoryFuture = ref.watch(inventoryItemsProvider.future);
  final salesFuture = ref.watch(saleTransactionsProvider.future);
  final repairsFuture = ref.watch(repairTransactionsProvider.future);
  final disposalsFuture = ref.watch(disposalTransactionsProvider.future);
  final tradesFuture = ref.watch(tradeTransactionsProvider.future);
  final warrantiesFuture = ref.watch(warrantyReplacementDealsProvider.future);

  final inventoryItems = await inventoryFuture;
  final sales = await salesFuture;
  final repairs = await repairsFuture;
  final disposals = await disposalsFuture;
  final trades = await tradesFuture;
  final warranties = await warrantiesFuture;

  final itemById = <String, InventoryItem>{
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

  final summaries = <DealLedgerSummary>[];

  for (final deal in deals) {
    final dealId = deal.id;
    final parentSale = saleById[deal.parentSaleTransactionId];

    if (dealId == null || dealId.isEmpty || parentSale == null) {
      continue;
    }

    final rootItem = itemById[parentSale.inventoryItemId];
    if (rootItem == null) {
      continue;
    }

    final financial = DealRecursiveAnalysisService.calculate(
      deal: deal,
      deals: deals,
      inventoryItems: inventoryItems,
      sales: sales,
      repairs: repairs,
      disposals: disposals,
      trades: trades,
      warrantyReplacements: warranties,
    );

    final relatedIds = <String>{};
    _collectRelatedInventoryIds(
      deal: deal,
      saleByInventoryId: saleByInventoryId,
      dealByParentSaleId: dealByParentSaleId,
      relatedIds: relatedIds,
      visitingDealIds: <String>{},
    );
    relatedIds.remove(rootItem.id);

    summaries.add(
      DealLedgerSummary(
        deal: deal,
        displayNumber: _displayNumber(deal, deals) ?? 'Pending',
        status: financial.status,
        currentProfitCents: financial.currentProfitCents,
        date: deal.createdAt ?? parentSale.saleDate,
        rootItem: rootItem,
        relatedInventoryItems: List.unmodifiable(
          relatedIds.map((id) => itemById[id]).whereType<InventoryItem>(),
        ),
      ),
    );
  }

  summaries.sort((a, b) => b.date.compareTo(a.date));
  return List.unmodifiable(summaries);
});

class DealLedgerSummary {
  const DealLedgerSummary({
    required this.deal,
    required this.displayNumber,
    required this.status,
    required this.currentProfitCents,
    required this.date,
    required this.rootItem,
    required this.relatedInventoryItems,
  });

  final Deal deal;
  final String displayNumber;
  final DealStatus status;
  final int currentProfitCents;
  final DateTime date;
  final InventoryItem rootItem;
  final List<InventoryItem> relatedInventoryItems;

  String get statusLabel => status.label;
}

void _collectRelatedInventoryIds({
  required Deal deal,
  required Map<String, SaleTransaction> saleByInventoryId,
  required Map<String, Deal> dealByParentSaleId,
  required Set<String> relatedIds,
  required Set<String> visitingDealIds,
}) {
  final identity = deal.id ?? deal.parentSaleTransactionId;
  if (!visitingDealIds.add(identity)) {
    return;
  }

  for (final inventoryId in deal.effectiveLineageInventoryItemIds) {
    relatedIds.add(inventoryId);

    final sale = saleByInventoryId[inventoryId];
    final nestedDeal = sale?.id == null ? null : dealByParentSaleId[sale!.id!];

    if (nestedDeal != null && nestedDeal.id != deal.id) {
      _collectRelatedInventoryIds(
        deal: nestedDeal,
        saleByInventoryId: saleByInventoryId,
        dealByParentSaleId: dealByParentSaleId,
        relatedIds: relatedIds,
        visitingDealIds: visitingDealIds,
      );
    }
  }

  visitingDealIds.remove(identity);
}

String? _displayNumber(Deal target, List<Deal> allDeals) {
  final createdAt = target.createdAt;
  if (createdAt == null) {
    return null;
  }

  final sameYear =
      allDeals.where((deal) => deal.createdAt?.year == createdAt.year).toList()
        ..sort((a, b) {
          final dateComparison = a.createdAt!.compareTo(b.createdAt!);
          if (dateComparison != 0) {
            return dateComparison;
          }
          return (a.id ?? '').compareTo(b.id ?? '');
        });

  final index = sameYear.indexWhere((deal) => deal.id == target.id);
  if (index < 0) {
    return null;
  }

  return '${createdAt.year}-${(index + 1).toString().padLeft(3, '0')}';
}
