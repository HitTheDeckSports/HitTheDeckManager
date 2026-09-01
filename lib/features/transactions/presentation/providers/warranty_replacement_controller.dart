import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/disposal_reason.dart';
import '../../domain/models/disposal_transaction.dart';
import '../../domain/models/warranty_replacement_deal.dart';
import 'deal_providers.dart';
import 'transaction_providers.dart';
import 'warranty_replacement_providers.dart';

final warrantyReplacementControllerProvider =
    AsyncNotifierProvider<WarrantyReplacementController, void>(
      WarrantyReplacementController.new,
    );

class WarrantyReplacementController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<WarrantyReplacementDeal> createReplacement({
    required DisposalTransaction disposal,
    required InventoryItem disposedItem,
    required DateTime replacementDate,
    String? notes,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => _createReplacement(
        disposal: disposal,
        disposedItem: disposedItem,
        replacementDate: replacementDate,
        notes: notes,
      ),
    );

    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }

    return result.requireValue;
  }

  Future<WarrantyReplacementDeal> _createReplacement({
    required DisposalTransaction disposal,
    required InventoryItem disposedItem,
    required DateTime replacementDate,
    required String? notes,
  }) async {
    final disposalId = disposal.id;
    final disposedItemId = disposedItem.id;

    if (disposalId == null || disposalId.trim().isEmpty) {
      throw StateError(
        'The disposal must be saved before a replacement can be created.',
      );
    }

    if (disposedItemId == null || disposedItemId.trim().isEmpty) {
      throw StateError(
        'The disposed inventory item must be saved before replacement.',
      );
    }

    if (disposal.reason != DisposalReason.warrantyReplacement) {
      throw StateError(
        'Only Warranty Replacement disposals can create replacement Deals.',
      );
    }

    if (disposal.replacementInventoryItemId != null) {
      throw StateError(
        'This disposal already has a replacement inventory item.',
      );
    }

    final inventoryRepository = ref.read(inventoryRepositoryProvider);
    final transactionRepository = ref.read(transactionRepositoryProvider);
    final warrantyDealRepository = ref.read(
      warrantyReplacementDealRepositoryProvider,
    );
    final lineageDealRepository = ref.read(dealRepositoryProvider);

    final existingLineageDeal = await lineageDealRepository
        .getDealForLineageInventoryItem(disposedItemId);

    InventoryItem? replacementItem;
    WarrantyReplacementDeal? savedWarrantyDeal;
    DisposalTransaction? updatedDisposal;
    var lineageDealUpdated = false;

    try {
      replacementItem = await inventoryRepository.createInventoryItem(
        InventoryItem(
          category: disposedItem.category,
          brand: disposedItem.brand,
          model: disposedItem.model,
          acquisitionType: disposedItem.acquisitionType,
          acquisitionValueCents: disposedItem.acquisitionValueCents,
          condition: InventoryCondition.newItem,
          status: InventoryStatus.available,
          purchaseDate: replacementDate,
          newValueCents: disposedItem.newValueCents,
          askingPriceCents: disposedItem.askingPriceCents,
          minimumPriceCents: disposedItem.minimumPriceCents,
          sellerContactId: disposedItem.sellerContactId,
          notes: _replacementNotes(disposedItem, notes),
          lengthInches: disposedItem.lengthInches,
          weightOunces: disposedItem.weightOunces,
          drop: disposedItem.drop,
          certification: disposedItem.certification,
          gloveSizeInches: disposedItem.gloveSizeInches,
          handOrientation: disposedItem.handOrientation,
          catchersGearSize: disposedItem.catchersGearSize,
          photoUrls: disposedItem.photoUrls,
        ),
      );

      updatedDisposal = await transactionRepository.updateDisposal(
        disposal.copyWith(replacementInventoryItemId: replacementItem.id),
      );

      savedWarrantyDeal = await warrantyDealRepository.createDeal(
        WarrantyReplacementDeal(
          disposalTransactionId: disposalId,
          disposedInventoryItemId: disposedItemId,
          replacementInventoryItemId: replacementItem.id!,
          replacementDate: replacementDate,
          notes: _optionalText(notes),
        ),
      );

      if (existingLineageDeal != null) {
        final replacementId = replacementItem.id!;
        final extendedLineage = <String>{
          ...existingLineageDeal.effectiveLineageInventoryItemIds,
          replacementId,
        }.toList(growable: false);

        await lineageDealRepository.updateDeal(
          existingLineageDeal.copyWith(
            lineageInventoryItemIds: extendedLineage,
          ),
        );
        lineageDealUpdated = true;
      }

      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(inventoryItemProvider(disposedItemId));
      ref.invalidate(inventoryItemProvider(replacementItem.id!));
      ref.invalidate(disposalTransactionProvider(disposalId));
      ref.invalidate(disposalsForInventoryItemProvider(disposedItemId));
      ref.invalidate(warrantyReplacementDealsProvider);
      ref.invalidate(warrantyReplacementDealForDisposalProvider(disposalId));
      ref.invalidate(
        warrantyReplacementDealForInventoryProvider(disposedItemId),
      );
      ref.invalidate(
        warrantyReplacementDealForInventoryProvider(replacementItem.id!),
      );

      if (existingLineageDeal != null) {
        ref.invalidate(dealsProvider);
        for (final inventoryId in {
          ...existingLineageDeal.effectiveLineageInventoryItemIds,
          replacementItem.id!,
        }) {
          ref.invalidate(dealForLineageInventoryItemProvider(inventoryId));
        }
      }

      return savedWarrantyDeal;
    } catch (error, stackTrace) {
      if (lineageDealUpdated && existingLineageDeal != null) {
        try {
          await lineageDealRepository.updateDeal(existingLineageDeal);
        } catch (_) {}
      }

      if (savedWarrantyDeal?.id != null) {
        try {
          await warrantyDealRepository.deleteDeal(savedWarrantyDeal!.id!);
        } catch (_) {}
      }

      if (updatedDisposal != null) {
        try {
          await transactionRepository.updateDisposal(disposal);
        } catch (_) {}
      }

      if (replacementItem?.id != null) {
        try {
          await inventoryRepository.deleteInventoryItem(replacementItem!.id!);
        } catch (_) {}
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

String _replacementNotes(InventoryItem disposedItem, String? notes) {
  final parts = <String>[
    'Warranty replacement for ${disposedItem.inventoryNumber ?? disposedItem.id}.',
  ];

  final existingNotes = disposedItem.notes?.trim() ?? '';
  if (existingNotes.isNotEmpty) {
    parts.add('Original item notes: $existingNotes');
  }

  final replacementNotes = notes?.trim() ?? '';
  if (replacementNotes.isNotEmpty) {
    parts.add(replacementNotes);
  }

  return parts.join(' ');
}

String? _optionalText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
