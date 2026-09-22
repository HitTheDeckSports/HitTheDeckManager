import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/mappers/firestore_inventory_mapper.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';

void main() {
  group('FirestoreInventoryMapper', () {
    test('serializes inventory item fields', () {
      final purchaseDate = DateTime.utc(2026, 8, 11);

      final item = InventoryItem(
        id: 'item-1',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.purchased,
        condition: InventoryCondition.likeNew,
        status: InventoryStatus.available,
        acquisitionValueCents: 20000,
        purchaseDate: purchaseDate,
        newValueCents: 39999,
        askingPriceCents: 29999,
        minimumPriceCents: 26000,
        sellerContactId: 'contact-1',
        notes: 'Test item',
        lengthInches: 32,
        weightOunces: 29,
        drop: -3,
        certification: 'BBCOR',
        photoUrls: const ['https://example.com/photo.jpg'],
      );

      final data = FirestoreInventoryMapper.toFirestore(item);

      expect(data['inventoryNumber'], 'BAT-2608-0001');
      expect(data['category'], 'bat');
      expect(data['brand'], 'Combat');
      expect(data['model'], 'Spec H1');
      expect(data['acquisitionType'], 'purchased');
      expect(data['condition'], 'likeNew');
      expect(data['status'], 'available');
      expect(data['acquisitionValueCents'], 20000);
      expect(data['purchaseDate'], isA<Timestamp>());
      expect(data['newValueCents'], 39999);
      expect(data['askingPriceCents'], 29999);
      expect(data['minimumPriceCents'], 26000);
      expect(data['sellerContactId'], 'contact-1');
      expect(data['notes'], 'Test item');
      expect(data['lengthInches'], 32);
      expect(data['weightOunces'], 29);
      expect(data['drop'], -3);
      expect(data['certification'], 'BBCOR');
      expect(data['photoUrls'], const ['https://example.com/photo.jpg']);
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('serializes helmet size', () {
      const item = InventoryItem(
        category: InventoryCategory.helmet,
        brand: 'Easton',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 8000,
        helmetSize: 'L/XL',
      );

      final data = FirestoreInventoryMapper.toFirestore(item);

      expect(data['helmetSize'], 'L/XL');
    });

    test('trims brand before writing', () {
      const item = InventoryItem(
        category: InventoryCategory.glove,
        brand: '  Rawlings  ',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 15000,
      );

      final data = FirestoreInventoryMapper.toFirestore(item);

      expect(data['brand'], 'Rawlings');
    });
  });
}
