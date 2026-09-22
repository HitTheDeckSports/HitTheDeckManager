import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/deal.dart';
import '../../domain/models/disposal_transaction.dart';
import '../../domain/models/repair_transaction.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/models/warranty_replacement_deal.dart';
import '../../domain/services/deal_lineage_service.dart';
import '../../domain/services/deal_recursive_analysis_service.dart';
import 'deal_providers.dart';
import 'transaction_providers.dart';
import 'warranty_replacement_providers.dart';

final dealDetailAnalysisProvider =
    FutureProvider.family<DealDetailViewModel?, String>((ref, dealId) async {
      // Re-run the analysis whenever any Deal-lineage source changes.
      ref.watch(dealsProvider);
      ref.watch(inventoryItemsProvider);
      ref.watch(saleTransactionsProvider);
      ref.watch(repairTransactionsProvider);
      ref.watch(disposalTransactionsProvider);
      ref.watch(tradeTransactionsProvider);
      ref.watch(warrantyReplacementDealsProvider);

      final dealRepository = ref.watch(dealRepositoryProvider);
      final transactionRepository = ref.watch(transactionRepositoryProvider);
      final inventoryRepository = ref.watch(inventoryRepositoryProvider);
      final warrantyRepository = ref.watch(
        warrantyReplacementDealRepositoryProvider,
      );

      final deal = await dealRepository.getDeal(dealId);
      if (deal == null) return null;

      final deals = await dealRepository.getDeals();
      final inventoryItems = await inventoryRepository.getInventory();
      final sales = await transactionRepository.getSales();
      final repairs = await transactionRepository.getRepairs();
      final disposals = await transactionRepository.getDisposals();
      final trades = await transactionRepository.getTrades();
      final warranties = await warrantyRepository.getDeals();

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
      final disposalByInventoryId = <String, DisposalTransaction>{
        for (final disposal in disposals) disposal.inventoryItemId: disposal,
      };
      final repairsByInventoryId = <String, List<RepairTransaction>>{};
      for (final repair in repairs) {
        repairsByInventoryId
            .putIfAbsent(repair.inventoryItemId, () => [])
            .add(repair);
      }
      final warrantyByDisposedId = <String, WarrantyReplacementDeal>{
        for (final warranty in warranties)
          warranty.disposedInventoryItemId: warranty,
      };
      final dealByParentSaleId = <String, Deal>{
        for (final candidate in deals)
          candidate.parentSaleTransactionId: candidate,
      };

      final parentSale = saleById[deal.parentSaleTransactionId];
      if (parentSale == null) {
        throw StateError('The parent sale for this Deal is unavailable.');
      }
      final rootItem = itemById[parentSale.inventoryItemId];
      if (rootItem == null) {
        throw StateError(
          'The original inventory item for this Deal is unavailable.',
        );
      }

      final lineageTree = DealLineageService.build(
        deal: deal,
        trades: trades,
        warrantyReplacements: warranties,
      );

      final financialByChild = {
        for (final branch in financial.branches)
          branch.rootChildInventoryItemId: branch,
      };

      final branchViews = <DealBranchViewModel>[];
      for (var index = 0; index < deal.childInventoryItemIds.length; index++) {
        final childId = deal.childInventoryItemIds[index];
        final branchFinancial = financialByChild[childId];
        if (branchFinancial == null) continue;

        final nodes = lineageTree.branchFor(childId)
          ..sort((a, b) => a.depth.compareTo(b.depth));
        final itemViews = <DealTreeItemViewModel>[];

        for (final node in nodes) {
          final item = itemById[node.inventoryItemId];
          if (item == null) continue;
          final sale = saleByInventoryId[item.id!];
          final nestedDeal = sale?.id == null
              ? null
              : dealByParentSaleId[sale!.id!];
          final itemRepairs =
              repairsByInventoryId[item.id!] ?? const <RepairTransaction>[];
          final repairCost = itemRepairs.fold<int>(
            0,
            (sum, repair) => sum + repair.costCents,
          );
          final disposal = disposalByInventoryId[item.id!];
          final warranty = warrantyByDisposedId[item.id!];

          itemViews.add(
            DealTreeItemViewModel(
              item: item,
              sale: sale,
              repairCostCents: repairCost,
              disposal: disposal,
              warrantyReplacement: warranty,
              nestedDeal: nestedDeal,
              nestedDealDisplayNumber: nestedDeal == null
                  ? null
                  : _displayNumber(nestedDeal, deals),
            ),
          );
        }

        branchViews.add(
          DealBranchViewModel(
            index: index + 1,
            financial: branchFinancial,
            items: List.unmodifiable(itemViews),
          ),
        );
      }

      final activities = _buildActivities(
        deal: deal,
        parentSale: parentSale,
        itemById: itemById,
        saleByInventoryId: saleByInventoryId,
        repairsByInventoryId: repairsByInventoryId,
        disposalByInventoryId: disposalByInventoryId,
        warrantyByDisposedId: warrantyByDisposedId,
        dealByParentSaleId: dealByParentSaleId,
        allDeals: deals,
      );

      return DealDetailViewModel(
        deal: deal,
        displayNumber: _displayNumber(deal, deals),
        financial: financial,
        parentSale: parentSale,
        rootItem: rootItem,
        branches: List.unmodifiable(branchViews),
        activities: List.unmodifiable(activities),
      );
    });

class DealDetailViewModel {
  const DealDetailViewModel({
    required this.deal,
    required this.displayNumber,
    required this.financial,
    required this.parentSale,
    required this.rootItem,
    required this.branches,
    required this.activities,
  });

  final Deal deal;
  final String? displayNumber;
  final DealRecursiveFinancialAnalysis financial;
  final SaleTransaction parentSale;
  final InventoryItem rootItem;
  final List<DealBranchViewModel> branches;
  final List<DealActivityViewModel> activities;
}

class DealBranchViewModel {
  const DealBranchViewModel({
    required this.index,
    required this.financial,
    required this.items,
  });

  final int index;
  final DealBranchFinancialAnalysis financial;
  final List<DealTreeItemViewModel> items;

  InventoryItem get rootItem => items.first.item;
}

class DealTreeItemViewModel {
  const DealTreeItemViewModel({
    required this.item,
    required this.sale,
    required this.repairCostCents,
    required this.disposal,
    required this.warrantyReplacement,
    required this.nestedDeal,
    required this.nestedDealDisplayNumber,
  });

  final InventoryItem item;
  final SaleTransaction? sale;
  final int repairCostCents;
  final DisposalTransaction? disposal;
  final WarrantyReplacementDeal? warrantyReplacement;
  final Deal? nestedDeal;
  final String? nestedDealDisplayNumber;
}

enum DealActivityTarget { none, inventory, sale, repair, disposal, deal }

class DealActivityViewModel {
  const DealActivityViewModel({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.iconKind,
    this.target = DealActivityTarget.none,
    this.targetId,
    this.order = 0,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final DealActivityIconKind iconKind;
  final DealActivityTarget target;
  final String? targetId;
  final int order;
}

enum DealActivityIconKind {
  sale,
  inventory,
  cash,
  repair,
  disposal,
  warranty,
  nestedDeal,
}

List<DealActivityViewModel> _buildActivities({
  required Deal deal,
  required SaleTransaction parentSale,
  required Map<String, InventoryItem> itemById,
  required Map<String, SaleTransaction> saleByInventoryId,
  required Map<String, List<RepairTransaction>> repairsByInventoryId,
  required Map<String, DisposalTransaction> disposalByInventoryId,
  required Map<String, WarrantyReplacementDeal> warrantyByDisposedId,
  required Map<String, Deal> dealByParentSaleId,
  required List<Deal> allDeals,
}) {
  final activities = <DealActivityViewModel>[
    DealActivityViewModel(
      date: parentSale.saleDate,
      title: '${_itemName(itemById[parentSale.inventoryItemId])} Sold',
      subtitle: 'Cash Received: ${_money(parentSale.cashReceivedCents)}',
      iconKind: DealActivityIconKind.sale,
      target: DealActivityTarget.sale,
      targetId: parentSale.id,
      order: 0,
    ),
  ];

  for (final childId in deal.childInventoryItemIds) {
    final child = itemById[childId];
    if (child == null) continue;
    activities.add(
      DealActivityViewModel(
        date: parentSale.saleDate,
        title: '${_itemName(child)} Received in Trade',
        subtitle: 'Acquisition Value: ${_money(child.acquisitionValueCents)}',
        iconKind: DealActivityIconKind.inventory,
        target: DealActivityTarget.inventory,
        targetId: child.id,
        order: 1,
      ),
    );
  }

  for (final inventoryId in deal.effectiveLineageInventoryItemIds) {
    final item = itemById[inventoryId];
    if (item == null) continue;

    for (final repair
        in repairsByInventoryId[inventoryId] ?? const <RepairTransaction>[]) {
      activities.add(
        DealActivityViewModel(
          date: repair.repairDate,
          title: '${_itemName(item)} Repaired',
          subtitle: '${_money(repair.costCents)} • ${repair.description}',
          iconKind: DealActivityIconKind.repair,
          target: DealActivityTarget.repair,
          targetId: repair.id,
          order: 2,
        ),
      );
    }

    final sale = saleByInventoryId[inventoryId];
    if (sale != null) {
      activities.add(
        DealActivityViewModel(
          date: sale.saleDate,
          title: '${_itemName(item)} Sold',
          subtitle: 'Cash Received: ${_money(sale.cashReceivedCents)}',
          iconKind: DealActivityIconKind.sale,
          target: DealActivityTarget.sale,
          targetId: sale.id,
          order: 3,
        ),
      );

      final nestedDeal = sale.id == null ? null : dealByParentSaleId[sale.id!];
      if (nestedDeal != null && nestedDeal.id != deal.id) {
        activities.add(
          DealActivityViewModel(
            date: sale.saleDate,
            title:
                'Deal #${_displayNumber(nestedDeal, allDeals) ?? '—'} Created',
            subtitle: 'Created from sale of ${_itemName(item)}',
            iconKind: DealActivityIconKind.nestedDeal,
            target: DealActivityTarget.deal,
            targetId: nestedDeal.id,
            order: 4,
          ),
        );
      }
    }

    final disposal = disposalByInventoryId[inventoryId];
    if (disposal != null) {
      activities.add(
        DealActivityViewModel(
          date: disposal.disposalDate,
          title: '${_itemName(item)} Disposed',
          subtitle: disposal.reason.name,
          iconKind: DealActivityIconKind.disposal,
          target: DealActivityTarget.disposal,
          targetId: disposal.id,
          order: 3,
        ),
      );
    }

    final warranty = warrantyByDisposedId[inventoryId];
    if (warranty != null) {
      activities.add(
        DealActivityViewModel(
          date: warranty.replacementDate,
          title: 'Warranty Replacement Received',
          subtitle: 'Replacement continues in this Deal branch',
          iconKind: DealActivityIconKind.warranty,
          target: DealActivityTarget.inventory,
          targetId: warranty.replacementInventoryItemId,
          order: 4,
        ),
      );
    }
  }

  activities.sort((a, b) {
    final dateCompare = a.date.compareTo(b.date);
    if (dateCompare != 0) return dateCompare;
    return a.order.compareTo(b.order);
  });
  return activities;
}

String? _displayNumber(Deal target, List<Deal> allDeals) {
  final createdAt = target.createdAt;
  if (createdAt == null) return null;
  final sameYear =
      allDeals.where((deal) => deal.createdAt?.year == createdAt.year).toList()
        ..sort((a, b) {
          final date = a.createdAt!.compareTo(b.createdAt!);
          if (date != 0) return date;
          return (a.id ?? '').compareTo(b.id ?? '');
        });
  final index = sameYear.indexWhere((deal) => deal.id == target.id);
  if (index < 0) return null;
  return '${createdAt.year}-${(index + 1).toString().padLeft(3, '0')}';
}

String _itemName(InventoryItem? item) {
  if (item == null) return 'Inventory Item';
  final model = item.model?.trim() ?? '';
  return model.isEmpty ? item.brand : '${item.brand} $model';
}

String _money(int cents) {
  final absolute = cents.abs();
  final dollars = absolute ~/ 100;
  final remainder = absolute % 100;
  final prefix = cents < 0 ? '-\$' : '\$';
  return '$prefix$dollars.${remainder.toString().padLeft(2, '0')}';
}
