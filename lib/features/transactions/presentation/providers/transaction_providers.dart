import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_transaction_repository.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return InMemoryTransactionRepository();
});

final saleTransactionsProvider = StreamProvider<List<SaleTransaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.watchSales();
});

final saleTransactionProvider = FutureProvider.family<SaleTransaction?, String>(
  (ref, saleId) {
    final repository = ref.watch(transactionRepositoryProvider);

    return repository.getSale(saleId);
  },
);

final saleForInventoryItemProvider =
    FutureProvider.family<SaleTransaction?, String>((ref, inventoryItemId) {
      final repository = ref.watch(transactionRepositoryProvider);

      return repository.getSaleForInventoryItem(inventoryItemId);
    });
