import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/data/mappers/firestore_deal_mapper.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';

void main() {
  group('FirestoreDealMapper', () {
    test('normalizes Deal relationship values', () {
      const deal = Deal(
        parentSaleTransactionId: '  sale-1  ',
        childInventoryItemIds: ['  inventory-1  ', 'inventory-2'],
        notes: '  Trade-in Deal  ',
      );

      final normalized = FirestoreDealMapper.normalize(deal);

      expect(normalized.parentSaleTransactionId, 'sale-1');
      expect(normalized.childInventoryItemIds, const [
        'inventory-1',
        'inventory-2',
      ]);
      expect(normalized.notes, 'Trade-in Deal');
    });

    test('removes blank child IDs during normalization', () {
      const deal = Deal(
        parentSaleTransactionId: 'sale-1',
        childInventoryItemIds: ['inventory-1', '   ', ''],
      );

      final normalized = FirestoreDealMapper.normalize(deal);

      expect(normalized.childInventoryItemIds, const ['inventory-1']);
    });

    test('converts blank notes to null', () {
      const deal = Deal(
        parentSaleTransactionId: 'sale-1',
        childInventoryItemIds: ['inventory-1'],
        notes: '   ',
      );

      final normalized = FirestoreDealMapper.normalize(deal);

      expect(normalized.notes, isNull);
    });

    test('serializes Deal relationship fields', () {
      const deal = Deal(
        parentSaleTransactionId: 'sale-1',
        childInventoryItemIds: ['inventory-1', 'inventory-2'],
        notes: 'Trade-in Deal',
      );

      final data = FirestoreDealMapper.toFirestore(deal);

      expect(data['parentSaleTransactionId'], 'sale-1');
      expect(data['childInventoryItemIds'], const [
        'inventory-1',
        'inventory-2',
      ]);
      expect(data['notes'], 'Trade-in Deal');
    });

    test('preserves one-level Deal relationship model', () {
      const deal = Deal(
        parentSaleTransactionId: 'sale-parent',
        childInventoryItemIds: ['child-1', 'child-2'],
      );

      final data = FirestoreDealMapper.toFirestore(deal);

      expect(data.containsKey('parentDealId'), isFalse);
      expect(data.containsKey('grandchildInventoryItemIds'), isFalse);
      expect(data['parentSaleTransactionId'], 'sale-parent');
      expect(data['childInventoryItemIds'], hasLength(2));
    });
  });
}
