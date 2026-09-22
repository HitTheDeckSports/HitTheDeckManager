import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_lineage_edge_type.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/warranty_replacement_deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/services/deal_lineage_service.dart';

void main() {
  test('builds two independent direct-child branches', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b', 'item-c'],
      lineageInventoryItemIds: ['item-b', 'item-c'],
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: const [],
      warrantyReplacements: const [],
    );

    expect(tree.directChildren, hasLength(2));
    expect(tree.nodeFor('item-b')?.depth, 0);
    expect(tree.nodeFor('item-b')?.rootChildInventoryItemId, 'item-b');
    expect(tree.nodeFor('item-c')?.rootChildInventoryItemId, 'item-c');
  });

  test('tracks descendant trades within the correct original branch', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b', 'item-c'],
      lineageInventoryItemIds: ['item-b', 'item-c', 'item-d', 'item-e'],
    );

    final trade = TradeTransaction(
      id: 'trade-b',
      saleTransactionId: 'sale-b',
      outgoingInventoryItemIds: const ['item-b'],
      incomingInventoryItemIds: const ['item-d', 'item-e'],
      tradeDate: DateTime(2026, 9, 1),
      paymentMethod: PaymentMethod.cash,
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: [trade],
      warrantyReplacements: const [],
    );

    expect(tree.nodeFor('item-d')?.parentInventoryItemId, 'item-b');
    expect(tree.nodeFor('item-d')?.rootChildInventoryItemId, 'item-b');
    expect(
      tree.nodeFor('item-d')?.edgeTypeFromParent,
      DealLineageEdgeType.trade,
    );
    expect(tree.nodeFor('item-d')?.depth, 1);
    expect(tree.branchFor('item-b'), hasLength(3));
    expect(tree.branchFor('item-c'), hasLength(1));
  });

  test('warranty replacement remains in the same branch', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b'],
      lineageInventoryItemIds: ['item-b', 'item-warranty'],
    );

    final warranty = WarrantyReplacementDeal(
      id: 'warranty-a',
      disposalTransactionId: 'disposal-a',
      disposedInventoryItemId: 'item-b',
      replacementInventoryItemId: 'item-warranty',
      replacementDate: DateTime(2026, 9, 2),
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: const [],
      warrantyReplacements: [warranty],
    );

    final replacement = tree.nodeFor('item-warranty');
    expect(replacement?.parentInventoryItemId, 'item-b');
    expect(replacement?.rootChildInventoryItemId, 'item-b');
    expect(
      replacement?.edgeTypeFromParent,
      DealLineageEdgeType.warrantyReplacement,
    );
    expect(replacement?.depth, 1);
  });

  test('supports trade then warranty then another trade in one branch', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b', 'item-c'],
      lineageInventoryItemIds: [
        'item-b',
        'item-c',
        'item-d',
        'item-warranty',
        'item-f',
      ],
    );

    final firstTrade = TradeTransaction(
      id: 'trade-b',
      saleTransactionId: 'sale-b',
      outgoingInventoryItemIds: const ['item-b'],
      incomingInventoryItemIds: const ['item-d'],
      tradeDate: DateTime(2026, 9, 1),
      paymentMethod: PaymentMethod.cash,
    );

    final warranty = WarrantyReplacementDeal(
      id: 'warranty-d',
      disposalTransactionId: 'disposal-d',
      disposedInventoryItemId: 'item-d',
      replacementInventoryItemId: 'item-warranty',
      replacementDate: DateTime(2026, 9, 2),
    );

    final secondTrade = TradeTransaction(
      id: 'trade-warranty',
      saleTransactionId: 'sale-warranty',
      outgoingInventoryItemIds: const ['item-warranty'],
      incomingInventoryItemIds: const ['item-f'],
      tradeDate: DateTime(2026, 9, 3),
      paymentMethod: PaymentMethod.cash,
    );

    final tree = DealLineageService.build(
      deal: deal,
      trades: [firstTrade, secondTrade],
      warrantyReplacements: [warranty],
    );

    expect(tree.nodeFor('item-f')?.rootChildInventoryItemId, 'item-b');
    expect(tree.nodeFor('item-f')?.parentInventoryItemId, 'item-warranty');
    expect(tree.nodeFor('item-f')?.depth, 3);
    expect(tree.branchFor('item-b'), hasLength(4));
    expect(tree.branchFor('item-c'), hasLength(1));
  });

  test('rejects an unreachable flat-lineage descendant', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b'],
      lineageInventoryItemIds: ['item-b', 'orphan-item'],
    );

    expect(
      () => DealLineageService.build(
        deal: deal,
        trades: const [],
        warrantyReplacements: const [],
      ),
      throwsStateError,
    );
  });

  test('rejects ambiguous trade branch attribution', () {
    const deal = Deal(
      id: 'deal-a',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['item-b', 'item-c'],
      lineageInventoryItemIds: ['item-b', 'item-c', 'item-d'],
    );

    final ambiguousTrade = TradeTransaction(
      id: 'trade-ambiguous',
      outgoingInventoryItemIds: const ['item-b', 'item-c'],
      incomingInventoryItemIds: const ['item-d'],
      tradeDate: DateTime(2026, 9, 3),
    );

    expect(
      () => DealLineageService.build(
        deal: deal,
        trades: [ambiguousTrade],
        warrantyReplacements: const [],
      ),
      throwsStateError,
    );
  });
}
