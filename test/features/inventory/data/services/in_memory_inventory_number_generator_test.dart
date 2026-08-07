import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/services/in_memory_inventory_number_generator.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';

void main() {
  group('InMemoryInventoryNumberGenerator', () {
    test('generates the expected inventory number format', () async {
      final generator = InMemoryInventoryNumberGenerator();

      final number = await generator.generate(
        category: InventoryCategory.bat,
        date: DateTime(2026, 7, 31),
      );

      expect(number, 'BAT-2607-0001');
    });

    test('increments the sequence for the same category and month', () async {
      final generator = InMemoryInventoryNumberGenerator();
      final date = DateTime(2026, 7, 31);

      final first = await generator.generate(
        category: InventoryCategory.bat,
        date: date,
      );

      final second = await generator.generate(
        category: InventoryCategory.bat,
        date: date,
      );

      expect(first, 'BAT-2607-0001');
      expect(second, 'BAT-2607-0002');
    });

    test('uses separate sequences for different categories', () async {
      final generator = InMemoryInventoryNumberGenerator();
      final date = DateTime(2026, 7, 31);

      final batNumber = await generator.generate(
        category: InventoryCategory.bat,
        date: date,
      );

      final gloveNumber = await generator.generate(
        category: InventoryCategory.glove,
        date: date,
      );

      expect(batNumber, 'BAT-2607-0001');
      expect(gloveNumber, 'GLV-2607-0001');
    });

    test('resets the sequence for a different month', () async {
      final generator = InMemoryInventoryNumberGenerator();

      final julyNumber = await generator.generate(
        category: InventoryCategory.bat,
        date: DateTime(2026, 7, 31),
      );

      final augustNumber = await generator.generate(
        category: InventoryCategory.bat,
        date: DateTime(2026, 8, 1),
      );

      expect(julyNumber, 'BAT-2607-0001');
      expect(augustNumber, 'BAT-2608-0001');
    });
  });
}
