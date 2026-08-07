import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_deal_repository.dart';
import '../../domain/models/deal.dart';
import '../../domain/repositories/deal_repository.dart';

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
