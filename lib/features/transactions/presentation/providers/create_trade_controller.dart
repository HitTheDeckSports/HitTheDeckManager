import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/incoming_trade_item_draft.dart';
import '../../domain/models/trade_transaction.dart';
import '../../domain/models/transaction_enums.dart';
import 'transaction_providers.dart';

class CreateTradeRequest {
  const CreateTradeRequest({
    required this.outgoingInventoryItemIds,
    required this.incomingItems,
    required this.tradeDate,
    this.contactId,
    this.cashPaidCents = 0,
    this.cashReceivedCents = 0,
    this.paymentMethod,
    this.notes,
  });

  final List<String> outgoingInventoryItemIds;
  final List<IncomingTradeItemDraft> incomingItems;
  final DateTime tradeDate;
  final String? contactId;
  final int cashPaidCents;
  final int cashReceivedCents;
  final PaymentMethod? paymentMethod;
  final String? notes;
}

final createTradeControllerProvider =
    AsyncNotifierProvider<CreateTradeController, void>(
      CreateTradeController.new,
    );

class CreateTradeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<TradeTransaction> createTrade(CreateTradeRequest request) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      if (request.outgoingInventoryItemIds.isEmpty &&
          request.incomingItems.isEmpty) {
        throw StateError(
          'A trade must include at least one outgoing or incoming item.',
        );
      }

      if (request.incomingItems.any((draft) => !draft.isValid)) {
        throw StateError(
          'Every incoming item must include a brand and valid value.',
        );
      }

      final inventoryRepository = ref.read(inventoryRepositoryProvider);
      final transactionRepository = ref.read(transactionRepositoryProvider);

      final outgoingItems = <InventoryItem>[];
      for (final itemId in request.outgoingInventoryItemIds) {
        final item = await inventoryRepository.getInventoryItem(itemId);

        if (item == null) {
          throw StateError('Outgoing inventory item $itemId was not found.');
        }

        if (item.status != InventoryStatus.available) {
          throw StateError(
            'Only available inventory items can be traded away.',
          );
        }

        outgoingItems.add(item);
      }

      final createdIncomingItems = <InventoryItem>[];
      final updatedOutgoingItems = <InventoryItem>[];

      try {
        for (final draft in request.incomingItems) {
          final createdItem = await inventoryRepository.createInventoryItem(
            InventoryItem(
              category: draft.category,
              brand: draft.brand.trim(),
              model: _optionalText(draft.model),
              acquisitionType: AcquisitionType.traded,
              condition: draft.condition,
              status: InventoryStatus.available,
              acquisitionValueCents: draft.acquisitionValueCents,
              purchaseDate: request.tradeDate,
              sellerContactId: _optionalText(request.contactId),
            ),
          );

          createdIncomingItems.add(createdItem);
        }

        for (final item in outgoingItems) {
          final updatedItem = await inventoryRepository.updateInventoryItem(
            item.copyWith(status: InventoryStatus.inactive),
          );
          updatedOutgoingItems.add(updatedItem);
        }

        final trade = TradeTransaction(
          outgoingInventoryItemIds: [
            for (final item in updatedOutgoingItems) item.id!,
          ],
          incomingInventoryItemIds: [
            for (final item in createdIncomingItems) item.id!,
          ],
          tradeDate: request.tradeDate,
          contactId: _optionalText(request.contactId),
          cashPaidCents: request.cashPaidCents,
          cashReceivedCents: request.cashReceivedCents,
          paymentMethod: request.paymentMethod,
          notes: _optionalText(request.notes),
        );

        final savedTrade = await transactionRepository.createTrade(trade);

        ref.invalidate(inventoryItemsProvider);
        ref.invalidate(tradeTransactionsProvider);
        ref.invalidate(tradeTransactionProvider(savedTrade.id!));

        for (final itemId in [
          ...savedTrade.outgoingInventoryItemIds,
          ...savedTrade.incomingInventoryItemIds,
        ]) {
          ref.invalidate(inventoryItemProvider(itemId));
          ref.invalidate(tradesForInventoryItemProvider(itemId));
        }

        return savedTrade;
      } catch (_) {
        for (final item in outgoingItems) {
          if (updatedOutgoingItems.any((updated) => updated.id == item.id)) {
            await inventoryRepository.updateInventoryItem(item);
          }
        }

        for (final item in createdIncomingItems.reversed) {
          await inventoryRepository.deleteInventoryItem(item.id!);
        }

        rethrow;
      }
    });

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
}

String? _optionalText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
