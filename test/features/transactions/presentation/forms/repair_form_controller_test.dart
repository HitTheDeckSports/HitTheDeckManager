import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/forms/repair_form_controller.dart';

void main() {
  test('initial state uses the family inventory item ID', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final state = container.read(repairFormControllerProvider('item-1'));

    expect(state.inventoryItemId, 'item-1');
    expect(state.repairId, isNull);
    expect(state.costInput, isEmpty);
    expect(state.description, isEmpty);
    expect(state.notes, isEmpty);
  });

  test('field setters update the repair form state', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final provider = repairFormControllerProvider('item-1');
    final controller = container.read(provider.notifier);
    final repairDate = DateTime(2026, 8, 5);

    controller.setRepairDate(repairDate);
    controller.setCostInput('45.00');
    controller.setDescription('Replaced damaged grip.');
    controller.setNotes('Completed in-house.');

    final state = container.read(provider);

    expect(state.inventoryItemId, 'item-1');
    expect(state.repairDate, repairDate);
    expect(state.costInput, '45.00');
    expect(state.description, 'Replaced damaged grip.');
    expect(state.notes, 'Completed in-house.');
    expect(state.isValid, isTrue);
  });

  test('loadRepair prefills an existing repair', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final provider = repairFormControllerProvider('item-1');
    final controller = container.read(provider.notifier);

    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4575,
      description: 'Replaced damaged grip.',
      notes: 'Completed in-house.',
    );

    controller.loadRepair(repair);

    final state = container.read(provider);

    expect(state.repairId, 'repair-1');
    expect(state.inventoryItemId, 'item-1');
    expect(state.repairDate, DateTime(2026, 8, 5));
    expect(state.costInput, '45.75');
    expect(state.description, 'Replaced damaged grip.');
    expect(state.notes, 'Completed in-house.');
  });

  test('loadRepair converts null notes to blank input', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final provider = repairFormControllerProvider('item-1');
    final controller = container.read(provider.notifier);

    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 0,
      description: 'Warranty repair.',
    );

    controller.loadRepair(repair);

    final state = container.read(provider);

    expect(state.costInput, '0.00');
    expect(state.notes, isEmpty);
  });

  test('reset restores a new form for the family inventory item', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final provider = repairFormControllerProvider('item-1');
    final controller = container.read(provider.notifier);

    controller.loadRepair(
      RepairTransaction(
        id: 'repair-1',
        inventoryItemId: 'different-item',
        repairDate: DateTime(2026, 8, 5),
        costCents: 4500,
        description: 'Replaced damaged grip.',
        notes: 'Completed in-house.',
      ),
    );

    final resetDate = DateTime(2026, 8, 6);

    controller.reset(repairDate: resetDate);

    final state = container.read(provider);

    expect(state.repairId, isNull);
    expect(state.inventoryItemId, 'item-1');
    expect(state.repairDate, resetDate);
    expect(state.costInput, isEmpty);
    expect(state.description, isEmpty);
    expect(state.notes, isEmpty);
  });

  test('buildRepairTransaction returns validated transaction', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final provider = repairFormControllerProvider('item-1');
    final controller = container.read(provider.notifier);

    controller.setRepairDate(DateTime(2026, 8, 5));
    controller.setCostInput('45.00');
    controller.setDescription(' Replaced damaged grip. ');
    controller.setNotes(' Completed in-house. ');

    final repair = controller.buildRepairTransaction();

    expect(repair.id, isNull);
    expect(repair.inventoryItemId, 'item-1');
    expect(repair.repairDate, DateTime(2026, 8, 5));
    expect(repair.costCents, 4500);
    expect(repair.description, 'Replaced damaged grip.');
    expect(repair.notes, 'Completed in-house.');
  });

  test('buildRepairTransaction preserves loaded repair ID', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final provider = repairFormControllerProvider('item-1');
    final controller = container.read(provider.notifier);

    controller.loadRepair(
      RepairTransaction(
        id: 'repair-1',
        inventoryItemId: 'item-1',
        repairDate: DateTime(2026, 8, 5),
        costCents: 4500,
        description: 'Replaced damaged grip.',
      ),
    );

    controller.setCostInput('55.00');

    final repair = controller.buildRepairTransaction();

    expect(repair.id, 'repair-1');
    expect(repair.costCents, 5500);
  });

  test('buildRepairTransaction rejects invalid form state', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(
      repairFormControllerProvider('item-1').notifier,
    );

    expect(controller.buildRepairTransaction, throwsA(isA<StateError>()));
  });

  test('separate family IDs maintain independent form state', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final firstProvider = repairFormControllerProvider('item-1');
    final secondProvider = repairFormControllerProvider('item-2');

    container.read(firstProvider.notifier).setDescription('First item repair.');

    container
        .read(secondProvider.notifier)
        .setDescription('Second item repair.');

    expect(container.read(firstProvider).description, 'First item repair.');

    expect(container.read(secondProvider).description, 'Second item repair.');

    expect(container.read(firstProvider).inventoryItemId, 'item-1');

    expect(container.read(secondProvider).inventoryItemId, 'item-2');
  });
}
