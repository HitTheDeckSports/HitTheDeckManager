import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_deal_repository.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/deal.dart';
import '../../domain/models/deal_summary.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/deal_repository.dart';
import '../../domain/services/deal_profit_service.dart';
import 'transaction_providers.dart';

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  return FirestoreDealRepository();
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

final dealForLineageInventoryItemProvider =
    FutureProvider.family<Deal?, String>((ref, inventoryItemId) {
      return ref
          .watch(dealRepositoryProvider)
          .getDealForLineageInventoryItem(inventoryItemId);
    });

/// Returns the business-facing Deal number in YYYY-NNN form.
///
/// Firestore document IDs remain internal routing/storage identifiers and are
/// never presented to the user. The sequence is based on immutable Deal
/// creation timestamps; permanent Deal deletion is disabled, so the ordinal
/// remains stable for normal Version 1.0 usage.
final dealDisplayNumberProvider = FutureProvider.family<String?, String>((
  ref,
  dealId,
) async {
  final normalizedId = dealId.trim();

  if (normalizedId.isEmpty) {
    return null;
  }

  final deals = await ref.watch(dealRepositoryProvider).getDeals();

  Deal? target;
  for (final deal in deals) {
    if (deal.id == normalizedId) {
      target = deal;
      break;
    }
  }

  final createdAt = target?.createdAt;
  if (target == null || createdAt == null) {
    return null;
  }

  final sameYear =
      deals
          .where((deal) => deal.createdAt?.year == createdAt.year)
          .toList(growable: false)
        ..sort((first, second) {
          final firstCreatedAt = first.createdAt!;
          final secondCreatedAt = second.createdAt!;
          final timeComparison = firstCreatedAt.compareTo(secondCreatedAt);

          if (timeComparison != 0) {
            return timeComparison;
          }

          return (first.id ?? '').compareTo(second.id ?? '');
        });

  final sequenceIndex = sameYear.indexWhere((deal) => deal.id == normalizedId);

  if (sequenceIndex < 0) {
    return null;
  }

  final sequence = (sequenceIndex + 1).toString().padLeft(3, '0');
  return '${createdAt.year}-$sequence';
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
