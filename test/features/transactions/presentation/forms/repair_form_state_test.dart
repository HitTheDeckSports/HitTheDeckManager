import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/forms/repair_form_state.dart';

void main() {
  test('initial state uses the supplied inventory item ID', () {
    final repairDate = DateTime(2026, 8, 5);

    final state = RepairFormState.initial(
      inventoryItemId: 'item-1',
      repairDate: repairDate,
    );

    expect(state.inventoryItemId, 'item-1');
    expect(state.repairDate, repairDate);
    expect(state.repairId, isNull);
    expect(state.costInput, isEmpty);
    expect(state.description, isEmpty);
    expect(state.notes, isEmpty);
  });

  test('converts dollar input to cents', () {
    final state = RepairFormState.initial(
      inventoryItemId: 'item-1',
    ).copyWith(costInput: '45.75', description: 'Replaced damaged grip.');

    expect(state.costCents, 4575);
    expect(state.hasValidCost, isTrue);
    expect(state.isValid, isTrue);
  });

  test('accepts currency symbols and commas', () {
    final state = RepairFormState.initial(
      inventoryItemId: 'item-1',
    ).copyWith(costInput: r'$1,234.56', description: 'Major refurbishment.');

    expect(state.costCents, 123456);
    expect(state.isValid, isTrue);
  });

  test('zero-cost repair is valid', () {
    final state = RepairFormState.initial(
      inventoryItemId: 'item-1',
    ).copyWith(costInput: '0', description: 'Warranty repair.');

    expect(state.costCents, 0);
    expect(state.isValid, isTrue);
  });

  test('blank repair cost is invalid', () {
    final state = RepairFormState.initial(
      inventoryItemId: 'item-1',
    ).copyWith(description: 'Replaced damaged grip.');

    expect(state.costCents, isNull);
    expect(state.hasValidCost, isFalse);
    expect(state.costError, 'Repair cost is required.');
    expect(state.isValid, isFalse);
  });

  test('invalid repair cost displays validation error', () {
    final state = RepairFormState.initial(inventoryItemId: 'item-1').copyWith(
      costInput: 'not-a-number',
      description: 'Replaced damaged grip.',
    );

    expect(state.costCents, isNull);
    expect(state.costError, 'Enter a valid repair cost.');
    expect(state.isValid, isFalse);
  });

  test('negative repair cost is invalid', () {
    final state = RepairFormState.initial(
      inventoryItemId: 'item-1',
    ).copyWith(costInput: '-1.00', description: 'Replaced damaged grip.');

    expect(state.costCents, isNull);
    expect(state.costError, 'Enter a valid repair cost.');
    expect(state.isValid, isFalse);
  });

  test('blank description is invalid', () {
    final state = RepairFormState.initial(
      inventoryItemId: 'item-1',
    ).copyWith(costInput: '45.00', description: '   ');

    expect(state.hasValidDescription, isFalse);
    expect(state.descriptionError, 'Repair description is required.');
    expect(state.isValid, isFalse);
  });

  test('blank inventory item ID is invalid', () {
    final state = RepairFormState.initial(
      inventoryItemId: '   ',
    ).copyWith(costInput: '45.00', description: 'Replaced damaged grip.');

    expect(state.hasValidInventoryItem, isFalse);
    expect(state.isValid, isFalse);
  });

  test('toRepairTransaction trims values and converts blank notes to null', () {
    final repairDate = DateTime(2026, 8, 5);

    final state = RepairFormState(
      repairId: 'repair-1',
      inventoryItemId: ' item-1 ',
      repairDate: repairDate,
      costInput: r' $45.00 ',
      description: ' Replaced damaged grip. ',
      notes: '   ',
    );

    final repair = state.toRepairTransaction();

    expect(repair.id, 'repair-1');
    expect(repair.inventoryItemId, 'item-1');
    expect(repair.repairDate, repairDate);
    expect(repair.costCents, 4500);
    expect(repair.description, 'Replaced damaged grip.');
    expect(repair.notes, isNull);
  });

  test('toRepairTransaction preserves nonblank notes', () {
    final state =
        RepairFormState.initial(
          inventoryItemId: 'item-1',
          repairDate: DateTime(2026, 8, 5),
        ).copyWith(
          costInput: '45.00',
          description: 'Replaced damaged grip.',
          notes: ' Completed in-house. ',
        );

    final repair = state.toRepairTransaction();

    expect(repair.notes, 'Completed in-house.');
  });

  test('toRepairTransaction rejects invalid state', () {
    final state = RepairFormState.initial(inventoryItemId: 'item-1');

    expect(state.toRepairTransaction, throwsA(isA<StateError>()));
  });

  test('copyWith can assign and clear the repair ID', () {
    final original = RepairFormState.initial(inventoryItemId: 'item-1');

    final assigned = original.copyWith(repairId: 'repair-1');

    final cleared = assigned.copyWith(repairId: null);

    expect(assigned.repairId, 'repair-1');
    expect(cleared.repairId, isNull);
  });
}
