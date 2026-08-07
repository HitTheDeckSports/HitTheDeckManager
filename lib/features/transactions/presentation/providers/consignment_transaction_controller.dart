import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../domain/models/consignment_transaction.dart';
import 'transaction_providers.dart';

final consignmentTransactionControllerProvider =
    AsyncNotifierProvider<ConsignmentTransactionController, void>(
      ConsignmentTransactionController.new,
    );

class ConsignmentTransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ConsignmentTransaction> createConsignment({
    required InventoryItem item,
    required DateTime consignmentDate,
    required int commissionCents,
    String? notes,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => _createConsignment(
        item: item,
        consignmentDate: consignmentDate,
        commissionCents: commissionCents,
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

  Future<ConsignmentTransaction> _createConsignment({
    required InventoryItem item,
    required DateTime consignmentDate,
    required int commissionCents,
    required String? notes,
  }) async {
    final itemId = item.id;

    if (itemId == null || itemId.trim().isEmpty) {
      throw StateError(
        'An inventory item must be saved before consignment can be recorded.',
      );
    }

    if (item.acquisitionType != AcquisitionType.consignment) {
      throw StateError(
        'Only inventory acquired as Consignment can create a consignment transaction.',
      );
    }

    if (item.status == InventoryStatus.sold ||
        item.status == InventoryStatus.disposed) {
      throw StateError(
        'Sold or disposed inventory cannot start a consignment agreement.',
      );
    }

    final repository = ref.read(transactionRepositoryProvider);

    final saved = await repository.createConsignment(
      ConsignmentTransaction(
        inventoryItemId: itemId,
        consignmentDate: consignmentDate,
        commissionCents: commissionCents,
        consignorContactId: _optionalText(item.sellerContactId),
        notes: _optionalText(notes),
      ),
    );

    ref.invalidate(consignmentTransactionsProvider);
    ref.invalidate(consignmentForInventoryItemProvider(itemId));

    return saved;
  }
}

String? _optionalText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
