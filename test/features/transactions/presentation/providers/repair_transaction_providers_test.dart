import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test('repairTransactionsProvider emits repair updates', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final emittedValues = <AsyncValue<List<RepairTransaction>>>[];

    final repairUpdateCompleter = Completer<List<RepairTransaction>>();

    final subscription = container.listen(repairTransactionsProvider, (
      previous,
      next,
    ) {
      emittedValues.add(next);

      final repairs = next.value;

      final containsCreatedRepair =
          repairs?.any((repair) => repair.id == 'repair-1') ?? false;

      if (containsCreatedRepair && !repairUpdateCompleter.isCompleted) {
        repairUpdateCompleter.complete(repairs);
      }
    }, fireImmediately: true);

    addTearDown(subscription.close);

    final initialRepairs = await container.read(
      repairTransactionsProvider.future,
    );

    expect(initialRepairs, isEmpty);

    await repository.createRepair(
      RepairTransaction(
        id: 'repair-1',
        inventoryItemId: 'item-1',
        repairDate: DateTime(2026, 8, 5),
        costCents: 4500,
        description: 'Replaced damaged grip.',
      ),
    );

    final updatedRepairs = await repairUpdateCompleter.future.timeout(
      const Duration(seconds: 2),
    );

    expect(updatedRepairs, hasLength(1));
    expect(updatedRepairs.single.id, 'repair-1');

    expect(
      emittedValues.any(
        (value) =>
            value.hasValue &&
            value.value?.any((repair) => repair.id == 'repair-1') == true,
      ),
      isTrue,
    );
  });

  test('repairTransactionProvider returns matching repair', () async {
    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final repository = InMemoryTransactionRepository(initialRepairs: [repair]);

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final loadedRepair = await container.read(
      repairTransactionProvider('repair-1').future,
    );

    expect(loadedRepair, repair);
  });

  test('repairTransactionProvider returns null for unknown ID', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final loadedRepair = await container.read(
      repairTransactionProvider('missing-repair').future,
    );

    expect(loadedRepair, isNull);
  });

  test('repairsForInventoryItemProvider returns matching repairs', () async {
    final firstRepair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 4),
      costCents: 2500,
      description: 'Cleaned and conditioned.',
    );

    final secondRepair = RepairTransaction(
      id: 'repair-2',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 6),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final unrelatedRepair = RepairTransaction(
      id: 'repair-3',
      inventoryItemId: 'item-2',
      repairDate: DateTime(2026, 8, 7),
      costCents: 3000,
      description: 'Re-laced glove.',
    );

    final repository = InMemoryTransactionRepository(
      initialRepairs: [firstRepair, secondRepair, unrelatedRepair],
    );

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final repairs = await container.read(
      repairsForInventoryItemProvider('item-1').future,
    );

    expect(repairs, hasLength(2));
    expect(repairs.first.id, 'repair-2');
    expect(repairs.last.id, 'repair-1');

    expect(
      repairs.any((repair) => repair.inventoryItemId == 'item-2'),
      isFalse,
    );
  });
}
