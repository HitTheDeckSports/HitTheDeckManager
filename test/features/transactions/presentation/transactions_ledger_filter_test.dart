import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transactions_screen.dart';

void main() {
  const item = InventoryItem(
    id: 'item-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    model: 'Spec H1',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 20000,
    status: InventoryStatus.sold,
  );

  Future<void> pumpLedger(
    WidgetTester tester, {
    required InMemoryTransactionRepository transactionRepository,
  }) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  InMemoryTransactionRepository createRepository() {
    return InMemoryTransactionRepository(
      initialSales: [
        SaleTransaction(
          id: 'sale-a',
          inventoryItemId: 'item-a',
          salePriceCents: 30000,
          saleDate: DateTime(2026, 8, 1),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 20000,
        ),
      ],
      initialRepairs: [
        RepairTransaction(
          id: 'repair-a',
          inventoryItemId: 'item-a',
          repairDate: DateTime(2026, 8, 4),
          costCents: 2500,
          description: 'Grip replacement',
        ),
      ],
      initialTrades: [
        TradeTransaction(
          id: 'trade-a',
          outgoingInventoryItemIds: const [],
          incomingInventoryItemIds: const ['item-a'],
          tradeDate: DateTime(2026, 8, 3),
          cashReceivedCents: 8000,
          paymentMethod: PaymentMethod.cash,
        ),
      ],
      initialDisposals: [
        DisposalTransaction(
          id: 'disposal-a',
          inventoryItemId: 'item-a',
          disposalDate: DateTime(2026, 8, 2),
          reason: DisposalReason.other,
        ),
      ],
    );
  }

  testWidgets('search filters the compact business-event ledger', (
    tester,
  ) async {
    final repository = createRepository();
    addTearDown(repository.dispose);
    await pumpLedger(tester, transactionRepository: repository);

    await tester.enterText(
      find.byKey(const Key('transactionsSearchField')),
      'Grip replacement',
    );
    await tester.pump();

    expect(find.text('1 of 4 transactions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('repairTransactionCard-repair-a')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sale-a')), findsNothing);
  });

  testWidgets('transaction type filter supports multiple types', (
    tester,
  ) async {
    final repository = createRepository();
    addTearDown(repository.dispose);
    await pumpLedger(tester, transactionRepository: repository);

    await tester.tap(find.byKey(const Key('transactionsFilterButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transactionsFilterDialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transactionsTypeFilter-sale')));
    await tester.tap(
      find.byKey(const ValueKey('transactionsTypeFilter-trade')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('transactionsFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(find.text('2 of 4 transactions'), findsOneWidget);
    expect(find.byKey(const ValueKey('sale-a')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tradeTransactionCard-trade-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('repairTransactionCard-repair-a')),
      findsNothing,
    );
  });

  testWidgets('minimum and maximum transaction amount filter the ledger', (
    tester,
  ) async {
    final repository = createRepository();
    addTearDown(repository.dispose);
    await pumpLedger(tester, transactionRepository: repository);

    await tester.tap(find.byKey(const Key('transactionsFilterButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transactionsMinimumAmountField')),
      '50',
    );
    await tester.enterText(
      find.byKey(const Key('transactionsMaximumAmountField')),
      '100',
    );
    await tester.tap(find.byKey(const Key('transactionsFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 4 transactions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tradeTransactionCard-trade-a')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sale-a')), findsNothing);
    expect(
      find.byKey(const ValueKey('repairTransactionCard-repair-a')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('disposalTransactionCard-disposal-a')),
      findsNothing,
    );
  });

  testWidgets('clear restores all transactions', (tester) async {
    final repository = createRepository();
    addTearDown(repository.dispose);
    await pumpLedger(tester, transactionRepository: repository);

    await tester.enterText(
      find.byKey(const Key('transactionsSearchField')),
      'repair',
    );
    await tester.pump();
    expect(find.text('1 of 4 transactions'), findsOneWidget);

    await tester.tap(find.byKey(const Key('transactionsClearFiltersButton')));
    await tester.pumpAndSettle();
    expect(find.text('4 transactions'), findsOneWidget);
  });
}
