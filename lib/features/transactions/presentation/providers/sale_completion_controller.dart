import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/consignment_transaction.dart';
import '../../domain/models/deal.dart';
import '../../domain/models/incoming_trade_item_draft.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/models/trade_transaction.dart';
import '../../domain/services/sale_completion_result.dart';
import 'deal_providers.dart';
import 'transaction_providers.dart';

final saleCompletionControllerProvider =
    AsyncNotifierProvider<SaleCompletionController, void>(
      SaleCompletionController.new,
    );

class SaleCompletionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SaleCompletionResult> completeSale({
    required InventoryItem item,
    required SaleTransaction sale,
    List<IncomingTradeItemDraft> tradeInItems = const [],
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => _completeSale(item: item, sale: sale, tradeInItems: tradeInItems),
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

  Future<SaleCompletionResult> _completeSale({
    required InventoryItem item,
    required SaleTransaction sale,
    required List<IncomingTradeItemDraft> tradeInItems,
  }) async {
    final itemId = item.id;

    if (itemId == null || itemId.trim().isEmpty) {
      throw StateError(
        'An inventory item must be saved before it can be sold.',
      );
    }

    if (item.status != InventoryStatus.available) {
      throw StateError('Only available inventory can be sold.');
    }

    if (sale.inventoryItemId != itemId) {
      throw StateError(
        'The sale transaction does not match the selected inventory item.',
      );
    }

    if (tradeInItems.any((draft) => !draft.isValid)) {
      throw StateError(
        'Every trade-in item must include a brand and valid acquisition value.',
      );
    }

    final inventoryRepository = ref.read(inventoryRepositoryProvider);
    final transactionRepository = ref.read(transactionRepositoryProvider);
    final dealRepository = ref.read(dealRepositoryProvider);

    final existingLineageDeal = await dealRepository
        .getDealForLineageInventoryItem(itemId);

    ConsignmentTransaction? originalConsignment;
    if (item.acquisitionType == AcquisitionType.consignment) {
      originalConsignment = await transactionRepository
          .getConsignmentForInventoryItem(itemId);

      if (originalConsignment == null) {
        throw StateError(
          'A consignment agreement must be recorded before this item can be sold.',
        );
      }

      if (originalConsignment.isCompleted) {
        throw StateError(
          'This consignment agreement is already linked to a completed sale.',
        );
      }

      if (originalConsignment.commissionCents > sale.salePriceCents) {
        throw StateError(
          'Consignment commission cannot exceed the total sale price.',
        );
      }
    }

    final repairs = await transactionRepository.getRepairsForInventoryItem(
      itemId,
    );
    final repairCostCents = repairs.fold<int>(
      0,
      (total, repair) => total + repair.costCents,
    );

    final soldItem = item.copyWith(status: InventoryStatus.sold);
    final updatedItem = await inventoryRepository.updateInventoryItem(soldItem);

    SaleTransaction? savedSale;
    TradeTransaction? savedTrade;
    Deal? savedDeal;
    Deal? originalDealBeforeLineageUpdate;
    var createdNewDeal = false;
    ConsignmentTransaction? updatedConsignment;
    final createdTradeInItems = <InventoryItem>[];

    try {
      final tradeInCreditCents = tradeInItems.fold<int>(
        0,
        (total, draft) => total + draft.acquisitionValueCents,
      );

      if (tradeInCreditCents > sale.salePriceCents) {
        throw StateError('Trade-in credit cannot exceed the total sale price.');
      }

      var saleToSave = sale.copyWith(
        repairCostCents: repairCostCents,
        tradeInCreditCents: tradeInCreditCents,
      );

      if (originalConsignment != null) {
        final consignorPayoutCents = originalConsignment
            .consignorPayoutCentsForSale(sale.salePriceCents);

        saleToSave = saleToSave.copyWith(
          acquisitionValueCents: consignorPayoutCents,
        );
      }

      savedSale = await transactionRepository.createSale(saleToSave);

      if (originalConsignment != null) {
        updatedConsignment = await transactionRepository.updateConsignment(
          originalConsignment.copyWith(saleTransactionId: savedSale.id),
        );
      }

      for (final draft in tradeInItems) {
        final createdItem = await inventoryRepository.createInventoryItem(
          InventoryItem(
            category: draft.category,
            brand: draft.brand.trim(),
            model: _optionalText(draft.model),
            acquisitionType: AcquisitionType.traded,
            condition: draft.condition,
            status: InventoryStatus.available,
            acquisitionValueCents: draft.acquisitionValueCents,
            purchaseDate: sale.saleDate,
            sellerContactId: _optionalText(sale.buyerContactId),
          ),
        );

        createdTradeInItems.add(createdItem);
      }

      if (createdTradeInItems.isNotEmpty) {
        final childInventoryItemIds = [
          for (final tradeInItem in createdTradeInItems) tradeInItem.id!,
        ];

        savedTrade = await transactionRepository.createTrade(
          TradeTransaction(
            saleTransactionId: savedSale.id,
            outgoingInventoryItemIds: [itemId],
            incomingInventoryItemIds: childInventoryItemIds,
            tradeDate: sale.saleDate,
            contactId: _optionalText(sale.buyerContactId),
            notes: 'Trade-in items recorded with this sale.',
          ),
        );

        if (existingLineageDeal != null) {
          originalDealBeforeLineageUpdate = existingLineageDeal;

          final extendedLineage = <String>{
            ...existingLineageDeal.effectiveLineageInventoryItemIds,
            ...childInventoryItemIds,
          }.toList(growable: false);

          savedDeal = await dealRepository.updateDeal(
            existingLineageDeal.copyWith(
              lineageInventoryItemIds: extendedLineage,
            ),
          );
        } else {
          savedDeal = await dealRepository.createDeal(
            Deal(
              parentSaleTransactionId: savedSale.id!,
              childInventoryItemIds: childInventoryItemIds,
              notes: 'Automatically created from trade-in sale.',
            ),
          );
          createdNewDeal = true;
        }
      }

      ref.invalidate(inventoryItemsProvider);

      ref.invalidate(inventoryItemProvider(itemId));
      ref.invalidate(saleTransactionsProvider);
      ref.invalidate(tradeTransactionsProvider);

      // Inventory Detail reads the family provider below rather than the
      // broad trade stream. Refresh every inventory item that directly
      // participated in the new trade so lifetime Trade History immediately
      // reflects both incoming and outgoing participation.
      if (savedTrade != null) {
        for (final inventoryId in {
          ...savedTrade.outgoingInventoryItemIds,
          ...savedTrade.incomingInventoryItemIds,
        }) {
          ref.invalidate(tradesForInventoryItemProvider(inventoryId));
        }
      }

      ref.invalidate(consignmentTransactionsProvider);
      ref.invalidate(consignmentForInventoryItemProvider(itemId));
      ref.invalidate(dealsProvider);

      if (savedDeal != null) {
        for (final inventoryId in savedDeal.effectiveLineageInventoryItemIds) {
          ref.invalidate(dealForLineageInventoryItemProvider(inventoryId));
        }
      }

      return SaleCompletionResult(sale: savedSale, soldItem: updatedItem);
    } catch (error, stackTrace) {
      if (originalDealBeforeLineageUpdate != null) {
        try {
          await dealRepository.updateDeal(originalDealBeforeLineageUpdate);
        } catch (_) {}
      } else if (createdNewDeal && savedDeal?.id != null) {
        try {
          await dealRepository.deleteDeal(savedDeal!.id!);
        } catch (_) {}
      }

      if (savedTrade?.id != null) {
        try {
          await transactionRepository.deleteTrade(savedTrade!.id!);
        } catch (_) {}
      }

      for (final tradeInItem in createdTradeInItems.reversed) {
        try {
          await inventoryRepository.deleteInventoryItem(tradeInItem.id!);
        } catch (_) {}
      }

      if (updatedConsignment != null && originalConsignment != null) {
        try {
          await transactionRepository.updateConsignment(originalConsignment);
        } catch (_) {}
      }

      if (savedSale?.id != null) {
        try {
          await transactionRepository.deleteSale(savedSale!.id!);
        } catch (_) {}
      }

      try {
        await inventoryRepository.updateInventoryItem(item);
        ref.invalidate(inventoryItemsProvider);
        ref.invalidate(inventoryItemProvider(itemId));
      } catch (_) {
        Error.throwWithStackTrace(
          StateError(
            'The sale failed and the inventory status could not be restored.',
          ),
          stackTrace,
        );
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

String? _optionalText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
