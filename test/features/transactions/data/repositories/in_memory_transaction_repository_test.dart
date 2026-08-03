import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

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
}
