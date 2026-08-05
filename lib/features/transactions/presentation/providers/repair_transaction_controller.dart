import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/repair_transaction.dart';
import 'transaction_providers.dart';

final repairTransactionControllerProvider =
    AsyncNotifierProvider<RepairTransactionController, void>(
      RepairTransactionController.new,
    );

class RepairTransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<RepairTransaction> createRepair(RepairTransaction repair) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);

      final savedRepair = await repository.createRepair(repair);

      ref.invalidate(repairTransactionProvider(savedRepair.id!));

      ref.invalidate(
        repairsForInventoryItemProvider(savedRepair.inventoryItemId),
      );

      return savedRepair;
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

  Future<RepairTransaction> updateRepair(RepairTransaction repair) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final repairId = repair.id;

      if (repairId == null || repairId.trim().isEmpty) {
        throw StateError(
          'A repair transaction must be saved before it can be updated.',
        );
      }

      final repository = ref.read(transactionRepositoryProvider);

      final existingRepair = await repository.getRepair(repairId);

      final savedRepair = await repository.updateRepair(repair);

      ref.invalidate(repairTransactionProvider(repairId));

      if (existingRepair != null &&
          existingRepair.inventoryItemId != savedRepair.inventoryItemId) {
        ref.invalidate(
          repairsForInventoryItemProvider(existingRepair.inventoryItemId),
        );
      }

      ref.invalidate(
        repairsForInventoryItemProvider(savedRepair.inventoryItemId),
      );

      return savedRepair;
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

  Future<void> deleteRepair(RepairTransaction repair) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final repairId = repair.id;

      if (repairId == null || repairId.trim().isEmpty) {
        throw StateError(
          'A repair transaction must be saved before it can be deleted.',
        );
      }

      final repository = ref.read(transactionRepositoryProvider);

      await repository.deleteRepair(repairId);

      ref.invalidate(repairTransactionProvider(repairId));

      ref.invalidate(repairsForInventoryItemProvider(repair.inventoryItemId));
    });

    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
