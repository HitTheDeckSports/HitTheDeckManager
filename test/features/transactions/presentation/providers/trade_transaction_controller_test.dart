import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/trade_transaction_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test('controller creates, updates, and deletes a trade', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(tradeTransactionControllerProvider.future);
    final controller = container.read(
      tradeTransactionControllerProvider.notifier,
    );

    final created = await controller.createTrade(
      TradeTransaction(
        outgoingInventoryItemIds: const ['out-1'],
        incomingInventoryItemIds: const ['in-1'],
        tradeDate: DateTime(2026, 8, 6),
      ),
    );

    expect(created.id, isNotNull);

    final updated = await controller.updateTrade(
      created.copyWith(notes: 'Updated trade.'),
    );

    expect(updated.notes, 'Updated trade.');

    await controller.deleteTrade(updated);
    expect(await repository.getTrade(created.id!), isNull);

    final state = container.read(tradeTransactionControllerProvider);
    expect(state.hasValue, isTrue);
    expect(state.hasError, isFalse);
  });

  test('update and delete reject an unsaved trade', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(tradeTransactionControllerProvider.future);

    final trade = TradeTransaction(
      outgoingInventoryItemIds: const ['out-1'],
      incomingInventoryItemIds: const [],
      tradeDate: DateTime(2026, 8, 6),
    );

    final controller = container.read(
      tradeTransactionControllerProvider.notifier,
    );

    await expectLater(
      controller.updateTrade(trade),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      controller.deleteTrade(trade),
      throwsA(isA<StateError>()),
    );
  });
}
