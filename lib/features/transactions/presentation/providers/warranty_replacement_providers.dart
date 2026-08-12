import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/presentation/providers/inventory_providers.dart';

import '../../data/repositories/firestore_warranty_replacement_deal_repository.dart';
import '../../domain/models/warranty_replacement_deal.dart';
import '../../domain/repositories/warranty_replacement_deal_repository.dart';
import 'transaction_providers.dart';

final warrantyReplacementDealRepositoryProvider =
    Provider<WarrantyReplacementDealRepository>((ref) {
      return FirestoreWarrantyReplacementDealRepository();
    });

final warrantyReplacementDealsProvider =
    StreamProvider<List<WarrantyReplacementDeal>>((ref) {
      return ref.watch(warrantyReplacementDealRepositoryProvider).watchDeals();
    });

final warrantyReplacementDealForDisposalProvider =
    FutureProvider.family<WarrantyReplacementDeal?, String>((
      ref,
      disposalId,
    ) async {
      final dealRepository = ref.watch(
        warrantyReplacementDealRepositoryProvider,
      );
      final transactionRepository = ref.watch(transactionRepositoryProvider);
      final inventoryRepository = ref.watch(inventoryRepositoryProvider);

      final existingDeal = await dealRepository.getDealForDisposal(disposalId);

      if (existingDeal != null) {
        return existingDeal;
      }

      // Phase 3 migration support:
      // Earlier warranty replacements persisted the replacement inventory item
      // and updated DisposalTransaction, but stored WarrantyReplacementDeal only
      // in memory. If that legacy state is found, rebuild only the missing
      // relationship record. Never create another inventory item here.
      final disposal = await transactionRepository.getDisposal(disposalId);

      if (disposal == null || !disposal.requiresReplacementDeal) {
        return null;
      }

      final replacementInventoryItemId = disposal.replacementInventoryItemId
          ?.trim();

      if (replacementInventoryItemId == null ||
          replacementInventoryItemId.isEmpty) {
        return null;
      }

      final replacementItem = await inventoryRepository.getInventoryItem(
        replacementInventoryItemId,
      );

      final recoveredDeal = WarrantyReplacementDeal(
        disposalTransactionId: disposalId,
        disposedInventoryItemId: disposal.inventoryItemId,
        replacementInventoryItemId: replacementInventoryItemId,
        replacementDate: replacementItem?.purchaseDate ?? disposal.disposalDate,
        notes: 'Recovered from existing warranty replacement relationship.',
      );

      return dealRepository.createDeal(recoveredDeal);
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
