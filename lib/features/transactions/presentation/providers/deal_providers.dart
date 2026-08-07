import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_deal_repository.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/deal.dart';
import '../../domain/models/deal_summary.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/deal_repository.dart';
import '../../domain/services/deal_profit_service.dart';
import 'transaction_providers.dart';

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  final repository = InMemoryDealRepository();

  ref.onDispose(repository.dispose);

  return repository;
});

final dealsProvider = StreamProvider<List<Deal>>((ref) {
  return ref.watch(dealRepositoryProvider).watchDeals();
});

final dealProvider = FutureProvider.family<Deal?, String>((ref, dealId) {
  return ref.watch(dealRepositoryProvider).getDeal(dealId);
});

final dealForParentSaleProvider = FutureProvider.family<Deal?, String>((
  ref,
  saleTransactionId,
) {
  return ref
      .watch(dealRepositoryProvider)
      .getDealForParentSale(saleTransactionId);
});

final dealForChildInventoryItemProvider = FutureProvider.family<Deal?, String>((
  ref,
  inventoryItemId,
) {
  return ref
      .watch(dealRepositoryProvider)
      .getDealForChildInventoryItem(inventoryItemId);
});

final dealSummaryProvider = FutureProvider.family<DealSummary?, String>((
  ref,
  dealId,
) async {
  final deal = await ref.watch(dealRepositoryProvider).getDeal(dealId);

  if (deal == null) {
    return null;
  }

  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final inventoryRepository = ref.watch(inventoryRepositoryProvider);

  final parentSale = await transactionRepository.getSale(
    deal.parentSaleTransactionId,
  );

  if (parentSale == null) {
    throw StateError(
      'The parent sale for Deal ${deal.id ?? dealId} is unavailable.',
    );
  }

  final childItems = <InventoryItem>[];
  final childSales = <SaleTransaction>[];

  for (final childId in deal.childInventoryItemIds) {
    final childItem = await inventoryRepository.getInventoryItem(childId);

    if (childItem == null) {
      throw StateError('Deal child inventory item $childId is unavailable.');
    }

    childItems.add(childItem);

    final childSale = await transactionRepository.getSaleForInventoryItem(
      childId,
    );

    if (childSale != null) {
      childSales.add(childSale);
    }
  }

  return DealProfitService.calculate(
    deal: deal,
    parentSale: parentSale,
    childInventoryItems: childItems,
    childSales: childSales,
  );
});
