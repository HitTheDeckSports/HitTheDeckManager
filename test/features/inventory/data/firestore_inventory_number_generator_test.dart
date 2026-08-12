import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/services/firestore_inventory_number_generator.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';

void main() {
  const generator = FirestoreInventoryNumberGenerator();

  group('FirestoreInventoryNumberGenerator', () {
    test('builds monthly counter document ID', () {
      final id = generator.counterDocumentId(
        category: InventoryCategory.bat,
        date: DateTime(2026, 8, 11),
      );

      expect(id, 'BAT-2608');
    });

    test('builds zero-padded inventory number', () {
      final number = generator.inventoryNumber(
        category: InventoryCategory.bat,
        date: DateTime(2026, 8, 11),
        sequence: 1,
      );

      expect(number, 'BAT-2608-0001');
    });

    test('uses correct category prefix', () {
      final number = generator.inventoryNumber(
        category: InventoryCategory.glove,
        date: DateTime(2026, 8, 11),
        sequence: 42,
      );

      expect(number, 'GLV-2608-0042');
    });

    test('supports sequence values larger than four digits', () {
      final number = generator.inventoryNumber(
        category: InventoryCategory.other,
        date: DateTime(2026, 8, 11),
        sequence: 12345,
      );

      expect(number, 'OTH-2608-12345');
    });
  });
}
