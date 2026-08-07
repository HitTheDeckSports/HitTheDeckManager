import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';

void main() {
  test('valid repair transaction passes validation', () {
    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Completed in-house.',
    );

    expect(repair.isValid, isTrue);
  });

  test('zero-cost repair is valid', () {
    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 0,
      description: 'Warranty replacement.',
    );

    expect(repair.isValid, isTrue);
  });

  test('blank inventory item ID is invalid', () {
    final repair = RepairTransaction(
      inventoryItemId: '   ',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    expect(repair.isValid, isFalse);
  });

  test('negative repair cost is invalid', () {
    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: -1,
      description: 'Replaced damaged grip.',
    );

    expect(repair.isValid, isFalse);
  });

  test('blank description is invalid', () {
    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: '   ',
    );

    expect(repair.isValid, isFalse);
  });

  test('copyWith updates selected values and preserves others', () {
    final original = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Original notes.',
    );

    final updated = original.copyWith(
      costCents: 5500,
      description: 'Replaced grip and cleaned barrel.',
      notes: null,
    );

    expect(updated.id, 'repair-1');
    expect(updated.inventoryItemId, 'item-1');
    expect(updated.repairDate, DateTime(2026, 8, 5));
    expect(updated.costCents, 5500);
    expect(updated.description, 'Replaced grip and cleaned barrel.');
    expect(updated.notes, isNull);
  });

  test('equal repair transactions have matching hash codes', () {
    final first = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Completed in-house.',
    );

    final second = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Completed in-house.',
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}
