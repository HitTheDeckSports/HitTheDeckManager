import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  test('creates, reads, updates, and deletes a trade', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final created = await repository.createTrade(
      TradeTransaction(
        outgoingInventoryItemIds: const ['out-1'],
        incomingInventoryItemIds: const ['in-1'],
        tradeDate: DateTime(2026, 8, 6),
        contactId: 'contact-1',
      ),
    );

    expect(created.id, isNotNull);
    expect(await repository.getTrade(created.id!), created);

    final updated = created.copyWith(
      cashReceivedCents: 2500,
      paymentMethod: PaymentMethod.cash,
    );

    expect(await repository.updateTrade(updated), updated);
    expect(await repository.getTrade(created.id!), updated);

    await repository.deleteTrade(created.id!);
    expect(await repository.getTrade(created.id!), isNull);
  });

  test('returns trades for an inventory item newest first', () async {
    final repository = InMemoryTransactionRepository(
      initialTrades: [
        TradeTransaction(
          id: 'older',
          outgoingInventoryItemIds: const ['item-1'],
          incomingInventoryItemIds: const [],
          tradeDate: DateTime(2026, 8, 1),
        ),
        TradeTransaction(
          id: 'newer',
          outgoingInventoryItemIds: const [],
          incomingInventoryItemIds: const ['item-1'],
          tradeDate: DateTime(2026, 8, 6),
        ),
        TradeTransaction(
          id: 'unrelated',
          outgoingInventoryItemIds: const ['item-2'],
          incomingInventoryItemIds: const [],
          tradeDate: DateTime(2026, 8, 7),
        ),
      ],
    );
    addTearDown(repository.dispose);

    final trades = await repository.getTradesForInventoryItem('item-1');

    expect(trades.map((trade) => trade.id), ['newer', 'older']);
  });

  test('rejects invalid and duplicate trades', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    await expectLater(
      repository.createTrade(
        TradeTransaction(
          outgoingInventoryItemIds: const [],
          incomingInventoryItemIds: const [],
          tradeDate: DateTime(2026, 8, 6),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );

    final trade = TradeTransaction(
      id: 'trade-1',
      outgoingInventoryItemIds: const ['out-1'],
      incomingInventoryItemIds: const [],
      tradeDate: DateTime(2026, 8, 6),
    );

    await repository.createTrade(trade);

    await expectLater(
      repository.createTrade(trade),
      throwsA(isA<DuplicateException>()),
    );
  });

  test('trade stream emits changes', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final states = <List<TradeTransaction>>[];
    final subscription = repository.watchTrades().listen(states.add);
    addTearDown(subscription.cancel);

    await Future<void>.delayed(Duration.zero);

    await repository.createTrade(
      TradeTransaction(
        outgoingInventoryItemIds: const ['out-1'],
        incomingInventoryItemIds: const [],
        tradeDate: DateTime(2026, 8, 6),
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(states.first, isEmpty);
    expect(states.last, hasLength(1));
  });
}
