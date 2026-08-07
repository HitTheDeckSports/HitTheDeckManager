import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import '../../domain/models/warranty_replacement_deal.dart';
import '../../domain/repositories/warranty_replacement_deal_repository.dart';

final warrantyReplacementDealRepositoryProvider =
    Provider<WarrantyReplacementDealRepository>((ref) {
      final repository = InMemoryWarrantyReplacementDealRepository();
      ref.onDispose(repository.dispose);
      return repository;
    });

final warrantyReplacementDealsProvider =
    StreamProvider<List<WarrantyReplacementDeal>>((ref) {
      return ref.watch(warrantyReplacementDealRepositoryProvider).watchDeals();
    });

final warrantyReplacementDealForDisposalProvider =
    FutureProvider.family<WarrantyReplacementDeal?, String>((ref, disposalId) {
      return ref
          .watch(warrantyReplacementDealRepositoryProvider)
          .getDealForDisposal(disposalId);
    });

final warrantyReplacementDealForInventoryProvider =
    FutureProvider.family<WarrantyReplacementDeal?, String>((
      ref,
      inventoryItemId,
    ) {
      return ref
          .watch(warrantyReplacementDealRepositoryProvider)
          .getDealForInventoryItem(inventoryItemId);
    });
