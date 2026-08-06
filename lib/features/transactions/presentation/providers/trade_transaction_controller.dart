import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/trade_transaction.dart';
import 'transaction_providers.dart';

final tradeTransactionControllerProvider =
    AsyncNotifierProvider<TradeTransactionController, void>(
      TradeTransactionController.new,
    );

class TradeTransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<TradeTransaction> createTrade(TradeTransaction trade) async {
    return _runOperation(() async {
      final repository = ref.read(transactionRepositoryProvider);
      final savedTrade = await repository.createTrade(trade);

      ref.invalidate(tradeTransactionProvider(savedTrade.id!));
      for (final itemId in [
        ...savedTrade.outgoingInventoryItemIds,
        ...savedTrade.incomingInventoryItemIds,
      ]) {
        ref.invalidate(tradesForInventoryItemProvider(itemId));
      }

      return savedTrade;
    });
  }

  Future<TradeTransaction> updateTrade(TradeTransaction trade) async {
    final tradeId = trade.id;

    if (tradeId == null || tradeId.trim().isEmpty) {
      throw StateError(
        'A trade transaction must be saved before it can be updated.',
      );
    }

    return _runOperation(() async {
      final repository = ref.read(transactionRepositoryProvider);
      final existingTrade = await repository.getTrade(tradeId);
      final savedTrade = await repository.updateTrade(trade);

      ref.invalidate(tradeTransactionProvider(tradeId));

      final affectedItemIds = <String>{
        ...?existingTrade?.outgoingInventoryItemIds,
        ...?existingTrade?.incomingInventoryItemIds,
        ...savedTrade.outgoingInventoryItemIds,
        ...savedTrade.incomingInventoryItemIds,
      };

      for (final itemId in affectedItemIds) {
        ref.invalidate(tradesForInventoryItemProvider(itemId));
      }

      return savedTrade;
    });
  }

  Future<void> deleteTrade(TradeTransaction trade) async {
    final tradeId = trade.id;

    if (tradeId == null || tradeId.trim().isEmpty) {
      throw StateError(
        'A trade transaction must be saved before it can be deleted.',
      );
    }

    await _runOperation(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTrade(tradeId);

      ref.invalidate(tradeTransactionProvider(tradeId));
      for (final itemId in [
        ...trade.outgoingInventoryItemIds,
        ...trade.incomingInventoryItemIds,
      ]) {
        ref.invalidate(tradesForInventoryItemProvider(itemId));
      }
    });
  }

  Future<T> _runOperation<T>(Future<T> Function() operation) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(operation);

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
