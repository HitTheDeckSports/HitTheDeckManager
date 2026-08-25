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
    final now = DateTime.now();
    return InMemoryTransactionRepository(
      initialSales: [
        SaleTransaction(
          id: 'sale-a',
          inventoryItemId: 'item-a',
          salePriceCents: 30000,
          saleDate: now.subtract(const Duration(days: 40)),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 20000,
        ),
      ],
      initialRepairs: [
        RepairTransaction(
          id: 'repair-a',
          inventoryItemId: 'item-a',
          repairDate: now.subtract(const Duration(days: 1)),
          costCents: 2500,
          description: 'Grip replacement',
        ),
      ],
      initialTrades: [
        TradeTransaction(
          id: 'trade-a',
          outgoingInventoryItemIds: const [],
          incomingInventoryItemIds: const ['item-a'],
          tradeDate: now.subtract(const Duration(days: 10)),
        ),
      ],
      initialDisposals: [
        DisposalTransaction(
          id: 'disposal-a',
          inventoryItemId: 'item-a',
          disposalDate: now.subtract(const Duration(days: 3)),
          reason: DisposalReason.other,
        ),
      ],
    );
  }

  testWidgets('combines transaction types in newest-first order', (
    tester,
  ) async {
    final repository = createRepository();
    addTearDown(repository.dispose);
    await pumpLedger(tester, transactionRepository: repository);

    expect(find.text('4 transactions'), findsOneWidget);
    expect(find.byKey(const Key('transactionsSalesSection')), findsNothing);

    final repair = find.byKey(const ValueKey('repairTransactionCard-repair-a'));
    final disposal = find.byKey(
      const ValueKey('disposalTransactionCard-disposal-a'),
    );
    final trade = find.byKey(const ValueKey('tradeTransactionCard-trade-a'));
    final sale = find.byKey(const ValueKey('sale-a'));

    expect(
      tester.getTopLeft(repair).dy,
      lessThan(tester.getTopLeft(disposal).dy),
    );
    expect(
      tester.getTopLeft(disposal).dy,
      lessThan(tester.getTopLeft(trade).dy),
    );
    expect(tester.getTopLeft(trade).dy, lessThan(tester.getTopLeft(sale).dy));
  });

  testWidgets('search filters the business-event ledger', (tester) async {
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
      find.descendant(
        of: find.byKey(const ValueKey('repairTransactionCard-repair-a')),
        matching: find.text('Grip replacement'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sale-a')), findsNothing);
  });

  testWidgets('type and date filters narrow the ledger', (tester) async {
    final repository = createRepository();
    addTearDown(repository.dispose);
    await pumpLedger(tester, transactionRepository: repository);

    await tester.tap(find.byKey(const Key('transactionsTypeFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sale').last);
    await tester.pumpAndSettle();

    expect(find.text('1 of 4 transactions'), findsOneWidget);
    expect(find.byKey(const ValueKey('sale-a')), findsOneWidget);

    await tester.tap(find.byKey(const Key('transactionsClearFiltersButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('transactionsDateFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days').last);
    await tester.pumpAndSettle();

    expect(find.text('2 of 4 transactions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('repairTransactionCard-repair-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('disposalTransactionCard-disposal-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tradeTransactionCard-trade-a')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('sale-a')), findsNothing);
  });
}
