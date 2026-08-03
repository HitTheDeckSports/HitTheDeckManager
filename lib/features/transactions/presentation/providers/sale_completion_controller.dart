import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/services/sale_completion_result.dart';
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
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => _completeSale(item: item, sale: sale),
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

    final inventoryRepository = ref.read(inventoryRepositoryProvider);

    final transactionRepository = ref.read(transactionRepositoryProvider);

    final soldItem = item.copyWith(status: InventoryStatus.sold);

    final updatedItem = await inventoryRepository.updateInventoryItem(soldItem);

    try {
      final savedSale = await transactionRepository.createSale(sale);

      return SaleCompletionResult(sale: savedSale, soldItem: updatedItem);
    } catch (error, stackTrace) {
      try {
        await inventoryRepository.updateInventoryItem(item);
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
