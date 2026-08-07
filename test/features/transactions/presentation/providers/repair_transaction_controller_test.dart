import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/repair_transaction_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test('createRepair saves a repair and returns to data state', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container.read(repairTransactionControllerProvider.future);

    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Completed in-house.',
    );

    final savedRepair = await container
        .read(repairTransactionControllerProvider.notifier)
        .createRepair(repair);

    expect(savedRepair.id, isNotNull);
    expect(savedRepair.inventoryItemId, 'item-1');
    expect(savedRepair.costCents, 4500);
    expect(savedRepair.description, 'Replaced damaged grip.');

    expect(await repository.getRepair(savedRepair.id!), savedRepair);

    final controllerState = container.read(repairTransactionControllerProvider);

    expect(controllerState.hasValue, isTrue);
    expect(controllerState.isLoading, isFalse);
    expect(controllerState.hasError, isFalse);
  });

  test('createRepair exposes loading state while saving', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container.read(repairTransactionControllerProvider.future);

    final observedStates = <AsyncValue<void>>[];

    final subscription = container.listen(repairTransactionControllerProvider, (
      previous,
      next,
    ) {
      observedStates.add(next);
    });

    addTearDown(subscription.close);

    final createFuture = container
        .read(repairTransactionControllerProvider.notifier)
        .createRepair(
          RepairTransaction(
            inventoryItemId: 'item-1',
            repairDate: DateTime(2026, 8, 5),
            costCents: 4500,
            description: 'Replaced damaged grip.',
          ),
        );

    await createFuture;

    expect(observedStates.any((state) => state.isLoading), isTrue);

    expect(observedStates.last.hasValue, isTrue);
  });

  test('createRepair preserves repository error state', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container.read(repairTransactionControllerProvider.future);

    final invalidRepair = RepairTransaction(
      inventoryItemId: '',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    await expectLater(
      container
          .read(repairTransactionControllerProvider.notifier)
          .createRepair(invalidRepair),
      throwsA(isA<ValidationException>()),
    );

    final controllerState = container.read(repairTransactionControllerProvider);

    expect(controllerState.hasError, isTrue);
    expect(controllerState.error, isA<ValidationException>());
  });

  test('updateRepair persists changed repair values', () async {
    final originalRepair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Original notes.',
    );

    final repository = InMemoryTransactionRepository(
      initialRepairs: [originalRepair],
    );

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container.read(repairTransactionControllerProvider.future);

    final updatedRepair = originalRepair.copyWith(
      costCents: 5500,
      description: 'Replaced grip and cleaned barrel.',
      notes: null,
    );

    final savedRepair = await container
        .read(repairTransactionControllerProvider.notifier)
        .updateRepair(updatedRepair);

    expect(savedRepair, updatedRepair);

    expect(await repository.getRepair('repair-1'), updatedRepair);

    final controllerState = container.read(repairTransactionControllerProvider);

    expect(controllerState.hasValue, isTrue);
    expect(controllerState.hasError, isFalse);
  });

  test('updateRepair rejects a repair without an ID', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container.read(repairTransactionControllerProvider.future);

    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    await expectLater(
      container
          .read(repairTransactionControllerProvider.notifier)
          .updateRepair(repair),
      throwsA(isA<StateError>()),
    );

    expect(
      container.read(repairTransactionControllerProvider).hasError,
      isTrue,
    );
  });

  test('deleteRepair removes the selected repair', () async {
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

    await container.read(repairTransactionControllerProvider.future);

    await container
        .read(repairTransactionControllerProvider.notifier)
        .deleteRepair(repair);

    expect(await repository.getRepair('repair-1'), isNull);

    expect(await repository.getRepairs(), isEmpty);

    final controllerState = container.read(repairTransactionControllerProvider);

    expect(controllerState.hasValue, isTrue);
    expect(controllerState.hasError, isFalse);
  });

  test('deleteRepair rejects a repair without an ID', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container.read(repairTransactionControllerProvider.future);

    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    await expectLater(
      container
          .read(repairTransactionControllerProvider.notifier)
          .deleteRepair(repair),
      throwsA(isA<StateError>()),
    );

    expect(
      container.read(repairTransactionControllerProvider).hasError,
      isTrue,
    );
  });
}
