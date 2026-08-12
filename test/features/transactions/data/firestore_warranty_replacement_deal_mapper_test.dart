import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/data/mappers/firestore_warranty_replacement_deal_mapper.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/warranty_replacement_deal.dart';

void main() {
  group('FirestoreWarrantyReplacementDealMapper', () {
    test('normalizes relationship IDs and notes', () {
      final deal = WarrantyReplacementDeal(
        disposalTransactionId: '  disposal-1  ',
        disposedInventoryItemId: '  inventory-old  ',
        replacementInventoryItemId: '  inventory-new  ',
        replacementDate: DateTime.utc(2026, 8, 12),
        notes: '  Warranty replacement test  ',
      );

      final normalized = FirestoreWarrantyReplacementDealMapper.normalize(deal);

      expect(normalized.disposalTransactionId, 'disposal-1');
      expect(normalized.disposedInventoryItemId, 'inventory-old');
      expect(normalized.replacementInventoryItemId, 'inventory-new');
      expect(normalized.notes, 'Warranty replacement test');
    });

    test('converts blank notes to null', () {
      final deal = WarrantyReplacementDeal(
        disposalTransactionId: 'disposal-1',
        disposedInventoryItemId: 'inventory-old',
        replacementInventoryItemId: 'inventory-new',
        replacementDate: DateTime.utc(2026, 8, 12),
        notes: '   ',
      );

      final normalized = FirestoreWarrantyReplacementDealMapper.normalize(deal);

      expect(normalized.notes, isNull);
    });

    test('serializes warranty replacement relationship fields', () {
      final deal = WarrantyReplacementDeal(
        disposalTransactionId: 'disposal-1',
        disposedInventoryItemId: 'inventory-old',
        replacementInventoryItemId: 'inventory-new',
        replacementDate: DateTime.utc(2026, 8, 12),
        notes: 'Warranty replacement test',
      );

      final data = FirestoreWarrantyReplacementDealMapper.toFirestore(deal);

      expect(data['disposalTransactionId'], 'disposal-1');
      expect(data['disposedInventoryItemId'], 'inventory-old');
      expect(data['replacementInventoryItemId'], 'inventory-new');
      expect(data['replacementDate'], isA<Timestamp>());
      expect(data['notes'], 'Warranty replacement test');
    });

    test('does not store nested relationship structures', () {
      final deal = WarrantyReplacementDeal(
        disposalTransactionId: 'disposal-1',
        disposedInventoryItemId: 'inventory-old',
        replacementInventoryItemId: 'inventory-new',
        replacementDate: DateTime.utc(2026, 8, 12),
      );

      final data = FirestoreWarrantyReplacementDealMapper.toFirestore(deal);

      expect(data.containsKey('replacementItem'), isFalse);
      expect(data.containsKey('disposal'), isFalse);
    });
  });
}
