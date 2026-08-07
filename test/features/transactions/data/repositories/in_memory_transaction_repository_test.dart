import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';

void main() {
  group('InMemoryTransactionRepository', () {
    test('creates and returns a sale transaction', () async {
      final repository = InMemoryTransactionRepository();
      addTearDown(repository.dispose);

      final transaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      final savedTransaction = await repository.createSale(transaction);

      expect(savedTransaction.id, isNotNull);
      expect(await repository.getSale(savedTransaction.id!), savedTransaction);
      expect(
        await repository.getSaleForInventoryItem('item-1'),
        savedTransaction,
      );
      expect(await repository.getSales(), contains(savedTransaction));
    });

    test('watchSales emits the initial and updated lists', () async {
      final repository = InMemoryTransactionRepository();
      addTearDown(repository.dispose);

      final emissions = <List<SaleTransaction>>[];

      final subscription = repository.watchSales().listen(emissions.add);

      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);

      final transaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.card,
        acquisitionValueCents: 20000,
      );

      final savedTransaction = await repository.createSale(transaction);

      await Future<void>.delayed(Duration.zero);

      expect(emissions.first, isEmpty);
      expect(emissions.last, contains(savedTransaction));
    });

    test('prevents duplicate sales for the same inventory item', () async {
      final repository = InMemoryTransactionRepository();
      addTearDown(repository.dispose);

      final firstSale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.venmo,
        acquisitionValueCents: 20000,
      );

      final secondSale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 35000,
        saleDate: DateTime(2026, 8, 4),
        paymentMethod: PaymentMethod.zelle,
        acquisitionValueCents: 20000,
      );

      await repository.createSale(firstSale);

      await expectLater(
        () => repository.createSale(secondSale),
        throwsA(isA<DuplicateException>()),
      );
    });

    test('updates an existing sale transaction', () async {
      final original = SaleTransaction(
        id: 'sale-1',
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        notes: 'Original notes.',
        acquisitionValueCents: 20000,
      );

      final repository = InMemoryTransactionRepository(
        initialSales: [original],
      );

      addTearDown(repository.dispose);

      final updated = original.copyWith(
        salePriceCents: 35000,
        paymentMethod: PaymentMethod.paypal,
        notes: 'Updated notes.',
      );

      final result = await repository.updateSale(updated);

      expect(result, updated);
      expect(await repository.getSale('sale-1'), updated);
    });

    test('deletes an existing sale transaction', () async {
      final transaction = SaleTransaction(
        id: 'sale-1',
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      final repository = InMemoryTransactionRepository(
        initialSales: [transaction],
      );

      addTearDown(repository.dispose);

      await repository.deleteSale('sale-1');

      expect(await repository.getSale('sale-1'), isNull);
      expect(await repository.getSales(), isEmpty);
    });

    test('throws for invalid sale data', () async {
      final repository = InMemoryTransactionRepository();
      addTearDown(repository.dispose);

      final invalidTransaction = SaleTransaction(
        inventoryItemId: '',
        salePriceCents: -1,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
      );

      await expectLater(
        () => repository.createSale(invalidTransaction),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when updating a sale without an ID', () async {
      final repository = InMemoryTransactionRepository();
      addTearDown(repository.dispose);

      final transaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      await expectLater(
        () => repository.updateSale(transaction),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when updating or deleting a missing sale', () async {
      final repository = InMemoryTransactionRepository();
      addTearDown(repository.dispose);

      final missingTransaction = SaleTransaction(
        id: 'missing-sale',
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      await expectLater(
        () => repository.updateSale(missingTransaction),
        throwsA(isA<NotFoundException>()),
      );

      await expectLater(
        () => repository.deleteSale('missing-sale'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
  test('getRepairs returns initial repair records', () async {
    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final repository = InMemoryTransactionRepository(initialRepairs: [repair]);

    addTearDown(repository.dispose);

    final repairs = await repository.getRepairs();

    expect(repairs, [repair]);
  });
  test('createRepair assigns an ID and stores the repair', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final savedRepair = await repository.createRepair(repair);

    expect(savedRepair.id, isNotNull);
    expect(savedRepair.inventoryItemId, 'item-1');
    expect(savedRepair.costCents, 4500);

    expect(await repository.getRepair(savedRepair.id!), savedRepair);
  });
  test('createRepair rejects invalid repair information', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final repair = RepairTransaction(
      inventoryItemId: '',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    expect(
      () => repository.createRepair(repair),
      throwsA(isA<ValidationException>()),
    );
  });
  test('createRepair rejects duplicate repair IDs', () async {
    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final repository = InMemoryTransactionRepository(initialRepairs: [repair]);

    addTearDown(repository.dispose);

    expect(
      () => repository.createRepair(repair),
      throwsA(isA<DuplicateException>()),
    );
  });
  test('multiple repairs can be stored for the same item', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    await repository.createRepair(
      RepairTransaction(
        id: 'repair-1',
        inventoryItemId: 'item-1',
        repairDate: DateTime(2026, 8, 4),
        costCents: 2500,
        description: 'Cleaned and conditioned.',
      ),
    );

    await repository.createRepair(
      RepairTransaction(
        id: 'repair-2',
        inventoryItemId: 'item-1',
        repairDate: DateTime(2026, 8, 6),
        costCents: 4500,
        description: 'Replaced damaged grip.',
      ),
    );

    final repairs = await repository.getRepairsForInventoryItem('item-1');

    expect(repairs, hasLength(2));
    expect(repairs.first.id, 'repair-2');
    expect(repairs.last.id, 'repair-1');
  });
  test('getRepairsForInventoryItem excludes other items', () async {
    final repository = InMemoryTransactionRepository(
      initialRepairs: [
        RepairTransaction(
          id: 'repair-1',
          inventoryItemId: 'item-1',
          repairDate: DateTime(2026, 8, 5),
          costCents: 4500,
          description: 'Replaced damaged grip.',
        ),
        RepairTransaction(
          id: 'repair-2',
          inventoryItemId: 'item-2',
          repairDate: DateTime(2026, 8, 6),
          costCents: 3000,
          description: 'Re-laced glove.',
        ),
      ],
    );

    addTearDown(repository.dispose);

    final repairs = await repository.getRepairsForInventoryItem('item-1');

    expect(repairs, hasLength(1));
    expect(repairs.single.id, 'repair-1');
  });
  test('updateRepair persists changes', () async {
    final original = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final repository = InMemoryTransactionRepository(
      initialRepairs: [original],
    );

    addTearDown(repository.dispose);

    final updated = original.copyWith(
      costCents: 5500,
      description: 'Replaced grip and cleaned barrel.',
    );

    final savedRepair = await repository.updateRepair(updated);

    expect(savedRepair, updated);
    expect(await repository.getRepair('repair-1'), updated);
  });
  test('updateRepair requires an ID', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final repair = RepairTransaction(
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    expect(
      () => repository.updateRepair(repair),
      throwsA(isA<ValidationException>()),
    );
  });
  test('updateRepair rejects an unknown ID', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final repair = RepairTransaction(
      id: 'missing-repair',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    expect(
      () => repository.updateRepair(repair),
      throwsA(isA<NotFoundException>()),
    );
  });
  test('deleteRepair removes an existing repair', () async {
    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final repository = InMemoryTransactionRepository(initialRepairs: [repair]);

    addTearDown(repository.dispose);

    await repository.deleteRepair('repair-1');

    expect(await repository.getRepair('repair-1'), isNull);
    expect(await repository.getRepairs(), isEmpty);
  });
  test('deleteRepair rejects an unknown ID', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    expect(
      () => repository.deleteRepair('missing-repair'),
      throwsA(isA<NotFoundException>()),
    );
  });
  test('watchRepairs emits initial and updated repair lists', () async {
    final repository = InMemoryTransactionRepository();

    addTearDown(repository.dispose);

    final emittedLists = <List<RepairTransaction>>[];

    final subscription = repository.watchRepairs().listen(emittedLists.add);

    addTearDown(subscription.cancel);

    await Future<void>.delayed(Duration.zero);

    await repository.createRepair(
      RepairTransaction(
        id: 'repair-1',
        inventoryItemId: 'item-1',
        repairDate: DateTime(2026, 8, 5),
        costCents: 4500,
        description: 'Replaced damaged grip.',
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(emittedLists, hasLength(2));
    expect(emittedLists.first, isEmpty);
    expect(emittedLists.last, hasLength(1));
    expect(emittedLists.last.single.id, 'repair-1');
  });
}
