import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sale_transaction.dart';
import 'transaction_providers.dart';

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(
      TransactionController.new,
    );

class TransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SaleTransaction> createSale(SaleTransaction transaction) async {
    state = const AsyncLoading();

    final repository = ref.read(transactionRepositoryProvider);

    final savedTransaction = await AsyncValue.guard(
      () => repository.createSale(transaction),
    );

    state = savedTransaction.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );

    if (savedTransaction.hasError) {
      Error.throwWithStackTrace(
        savedTransaction.error!,
        savedTransaction.stackTrace!,
      );
    }

    return savedTransaction.requireValue;
  }

  Future<SaleTransaction> updateSale(SaleTransaction transaction) async {
    state = const AsyncLoading();

    final repository = ref.read(transactionRepositoryProvider);

    final updatedTransaction = await AsyncValue.guard(
      () => repository.updateSale(transaction),
    );

    state = updatedTransaction.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );

    if (updatedTransaction.hasError) {
      Error.throwWithStackTrace(
        updatedTransaction.error!,
        updatedTransaction.stackTrace!,
      );
    }

    return updatedTransaction.requireValue;
  }

  Future<void> deleteSale(String id) async {
    state = const AsyncLoading();

    final repository = ref.read(transactionRepositoryProvider);

    final result = await AsyncValue.guard(() => repository.deleteSale(id));

    state = result;

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
