import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';

void main() {
  testWidgets('displays a sale transaction and related inventory item', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      notes: 'Sold during tournament.',
      acquisitionValueCents: 20000,
    );

    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Transaction'), findsOneWidget);
    expect(find.text('Transaction Summary'), findsOneWidget);
    expect(find.text('Financial Summary'), findsOneWidget);

    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('08/03/2026'), findsAtLeastNWidgets(1));
    expect(find.text('Cash'), findsOneWidget);

    expect(find.text('BAT-2608-0001 — Combat Spec H1'), findsOneWidget);

    expect(find.text(r'$325.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsOneWidget);
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(find.text('38.5%'), findsOneWidget);

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Sold during tournament.'), findsOneWidget);
  });

  testWidgets('displays not-found state for an unknown transaction', (
    WidgetTester tester,
  ) async {
    final transactionRepository = InMemoryTransactionRepository();

    final inventoryRepository = InMemoryInventoryRepository();

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'missing-sale'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Transaction Details'), findsOneWidget);
    expect(find.text('Transaction not found.'), findsOneWidget);

    expect(
      find.text(
        'The transaction may have been removed or is no longer available.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('handles a missing related inventory item', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'missing-item',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.card,
      acquisitionValueCents: 20000,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository();

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory record unavailable'), findsOneWidget);

    expect(find.text('missing-item'), findsNothing);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text(r'$325.00'), findsOneWidget);
  });
}
