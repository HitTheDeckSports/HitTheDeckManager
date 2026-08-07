import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/disposal_reason.dart';
import '../../domain/models/disposal_transaction.dart';
import 'transaction_providers.dart';

final disposalTransactionControllerProvider =
    AsyncNotifierProvider<DisposalTransactionController, void>(
      DisposalTransactionController.new,
    );

class DisposalTransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<DisposalTransaction> disposeInventoryItem({
    required InventoryItem item,
    required DateTime disposalDate,
    required DisposalReason reason,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _disposeInventoryItem(
        item: item,
        disposalDate: disposalDate,
        reason: reason,
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

  Future<DisposalTransaction> _disposeInventoryItem({
    required InventoryItem item,
    required DateTime disposalDate,
    required DisposalReason reason,
    required String? notes,
  }) async {
    final itemId = item.id;
    if (itemId == null || itemId.trim().isEmpty) {
      throw StateError(
        'An inventory item must be saved before it can be disposed.',
      );
    }
    if (item.status == InventoryStatus.sold) {
      throw StateError('Sold inventory cannot be disposed.');
    }
    if (item.status == InventoryStatus.disposed) {
      throw StateError('This inventory item is already disposed.');
    }

    final inventoryRepository = ref.read(inventoryRepositoryProvider);
    final transactionRepository = ref.read(transactionRepositoryProvider);

    await inventoryRepository.updateInventoryItem(
      item.copyWith(status: InventoryStatus.disposed),
    );
    DisposalTransaction? saved;

    try {
      saved = await transactionRepository.createDisposal(
        DisposalTransaction(
          inventoryItemId: itemId,
          disposalDate: disposalDate,
          reason: reason,
          notes: _optionalText(notes),
        ),
      );
      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(inventoryItemProvider(itemId));
      ref.invalidate(disposalTransactionsProvider);
      ref.invalidate(disposalsForInventoryItemProvider(itemId));
      return saved;
    } catch (error, stackTrace) {
      if (saved?.id != null) {
        try {
          await transactionRepository.deleteDisposal(saved!.id!);
        } catch (_) {}
      }
      try {
        await inventoryRepository.updateInventoryItem(item);
      } catch (_) {
        Error.throwWithStackTrace(
          StateError(
            'The disposal failed and the inventory status could not be restored.',
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
