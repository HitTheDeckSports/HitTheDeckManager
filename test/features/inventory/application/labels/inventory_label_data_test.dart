import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/labels/inventory_label_data.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';

void main() {
  group('InventoryLabelData', () {
    test('creates label data for a saved inventory item', () {
      const item = InventoryItem(
        id: 'item-123',
        inventoryNumber: 'BAT-2608-0100',
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
      );

      final label = InventoryLabelData.fromInventoryItem(item);

      expect(label.qrValue, 'hitthedeck://inventory/item-123');
      expect(label.inventoryNumber, 'BAT-2608-0100');
      expect(label.displayName, 'Combat Spec H1');
    });

    test('uses brand only when model is blank', () {
      const item = InventoryItem(
        id: 'item-456',
        inventoryNumber: 'BAT-2608-0101',
        category: InventoryCategory.bat,
        brand: 'Easton',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
      );

      final label = InventoryLabelData.fromInventoryItem(item);

      expect(label.displayName, 'Easton');
    });

    test('uses fallback text when inventory number is missing', () {
      const item = InventoryItem(
        id: 'item-789',
        category: InventoryCategory.bat,
        brand: 'Rawlings',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
      );

      final label = InventoryLabelData.fromInventoryItem(item);

      expect(label.inventoryNumber, 'Not assigned');
    });

    test('rejects an unsaved inventory item', () {
      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
      );

      expect(
        () => InventoryLabelData.fromInventoryItem(item),
        throwsArgumentError,
      );
    });
  });
}
