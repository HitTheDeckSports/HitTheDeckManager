import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  test('valid item-only trade is accepted', () {
    final trade = TradeTransaction(
      outgoingInventoryItemIds: const ['out-1'],
      incomingInventoryItemIds: const ['in-1'],
      tradeDate: DateTime(2026, 8, 6),
    );

    expect(trade.isValid, isTrue);
    expect(trade.includesCash, isFalse);
    expect(trade.netCashCents, 0);
  });

  test('cash received requires a payment method', () {
    final trade = TradeTransaction(
      outgoingInventoryItemIds: const ['out-1'],
      incomingInventoryItemIds: const [],
      tradeDate: DateTime(2026, 8, 6),
      cashReceivedCents: 5000,
    );

    expect(trade.isValid, isFalse);
    expect(
      trade.copyWith(paymentMethod: PaymentMethod.cash).isValid,
      isTrue,
    );
  });

  test('cash paid and received cannot both be positive', () {
    final trade = TradeTransaction(
      outgoingInventoryItemIds: const ['out-1'],
      incomingInventoryItemIds: const ['in-1'],
      tradeDate: DateTime(2026, 8, 6),
      cashPaidCents: 1000,
      cashReceivedCents: 2000,
      paymentMethod: PaymentMethod.cash,
    );

    expect(trade.isValid, isFalse);
  });

  test('duplicate item IDs across trade directions are invalid', () {
    final trade = TradeTransaction(
      outgoingInventoryItemIds: const ['item-1'],
      incomingInventoryItemIds: const ['item-1'],
      tradeDate: DateTime(2026, 8, 6),
    );

    expect(trade.isValid, isFalse);
  });

  test('copyWith can assign and clear optional values', () {
    final original = TradeTransaction(
      outgoingInventoryItemIds: const ['out-1'],
      incomingInventoryItemIds: const ['in-1'],
      tradeDate: DateTime(2026, 8, 6),
    );

    final changed = original.copyWith(
      id: 'trade-1',
      contactId: 'contact-1',
      paymentMethod: PaymentMethod.venmo,
      notes: 'Tournament trade.',
    );

    final cleared = changed.copyWith(
      contactId: null,
      paymentMethod: null,
      notes: null,
    );

    expect(changed.id, 'trade-1');
    expect(changed.contactId, 'contact-1');
    expect(changed.notes, 'Tournament trade.');
    expect(cleared.contactId, isNull);
    expect(cleared.paymentMethod, isNull);
    expect(cleared.notes, isNull);
  });
}
