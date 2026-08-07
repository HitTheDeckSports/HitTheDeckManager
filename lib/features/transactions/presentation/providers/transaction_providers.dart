import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_transaction_repository.dart';
import '../../domain/models/consignment_transaction.dart';
import '../../domain/models/disposal_transaction.dart';
import '../../domain/models/repair_transaction.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/models/trade_transaction.dart';
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
final repairTransactionsProvider = StreamProvider<List<RepairTransaction>>((
  ref,
) {
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.watchRepairs();
});

final repairTransactionProvider =
    FutureProvider.family<RepairTransaction?, String>((ref, repairId) {
      final repository = ref.watch(transactionRepositoryProvider);

      return repository.getRepair(repairId);
    });

final repairsForInventoryItemProvider =
    FutureProvider.family<List<RepairTransaction>, String>((
      ref,
      inventoryItemId,
    ) {
      final repository = ref.watch(transactionRepositoryProvider);

      return repository.getRepairsForInventoryItem(inventoryItemId);
    });

final consignmentTransactionsProvider =
    StreamProvider<List<ConsignmentTransaction>>((ref) {
      return ref.watch(transactionRepositoryProvider).watchConsignments();
    });

final consignmentTransactionProvider =
    FutureProvider.family<ConsignmentTransaction?, String>((
      ref,
      consignmentId,
    ) {
      return ref
          .watch(transactionRepositoryProvider)
          .getConsignment(consignmentId);
    });

final consignmentForInventoryItemProvider =
    FutureProvider.family<ConsignmentTransaction?, String>((
      ref,
      inventoryItemId,
    ) {
      return ref
          .watch(transactionRepositoryProvider)
          .getConsignmentForInventoryItem(inventoryItemId);
    });
final disposalTransactionsProvider = StreamProvider<List<DisposalTransaction>>((
  ref,
) {
  return ref.watch(transactionRepositoryProvider).watchDisposals();
});

final disposalTransactionProvider =
    FutureProvider.family<DisposalTransaction?, String>((ref, id) {
      return ref.watch(transactionRepositoryProvider).getDisposal(id);
    });

final disposalsForInventoryItemProvider =
    FutureProvider.family<List<DisposalTransaction>, String>((
      ref,
      inventoryItemId,
    ) {
      return ref
          .watch(transactionRepositoryProvider)
          .getDisposalsForInventoryItem(inventoryItemId);
    });

final tradeTransactionsProvider = StreamProvider<List<TradeTransaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.watchTrades();
});

final tradeTransactionProvider =
    FutureProvider.family<TradeTransaction?, String>((ref, tradeId) {
      final repository = ref.watch(transactionRepositoryProvider);

      return repository.getTrade(tradeId);
    });

final tradesForInventoryItemProvider =
    FutureProvider.family<List<TradeTransaction>, String>((
      ref,
      inventoryItemId,
    ) {
      final repository = ref.watch(transactionRepositoryProvider);

      return repository.getTradesForInventoryItem(inventoryItemId);
    });
