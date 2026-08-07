import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  group('TransactionController', () {
    test('creates a sale transaction', () async {
      final repository = InMemoryTransactionRepository();

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final transaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      final savedTransaction = await container
          .read(transactionControllerProvider.notifier)
          .createSale(transaction);

      expect(savedTransaction.id, isNotNull);
      expect(savedTransaction.inventoryItemId, 'item-1');
      expect(savedTransaction.salePriceCents, 32500);

      expect(await repository.getSale(savedTransaction.id!), savedTransaction);

      expect(
        container.read(transactionControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('updates an existing sale transaction', () async {
      final original = SaleTransaction(
        id: 'sale-1',
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      final repository = InMemoryTransactionRepository(
        initialSales: [original],
      );

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final updated = original.copyWith(
        salePriceCents: 35000,
        paymentMethod: PaymentMethod.zelle,
      );

      final result = await container
          .read(transactionControllerProvider.notifier)
          .updateSale(updated);

      expect(result, updated);
      expect(await repository.getSale('sale-1'), updated);

      expect(
        container.read(transactionControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('deletes a sale transaction', () async {
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

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      await container
          .read(transactionControllerProvider.notifier)
          .deleteSale('sale-1');

      expect(await repository.getSale('sale-1'), isNull);

      expect(
        container.read(transactionControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('exposes repository errors through controller state', () async {
      final repository = InMemoryTransactionRepository();

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final invalidTransaction = SaleTransaction(
        inventoryItemId: '',
        salePriceCents: -1,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
      );

      await expectLater(
        () => container
            .read(transactionControllerProvider.notifier)
            .createSale(invalidTransaction),
        throwsA(isA<ValidationException>()),
      );

      expect(container.read(transactionControllerProvider).hasError, isTrue);
    });
  });
}
