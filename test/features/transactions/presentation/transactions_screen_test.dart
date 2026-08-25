import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transactions_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  testWidgets('displays the empty transactions state', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryTransactionRepository();
    final inventoryRepository = InMemoryInventoryRepository();

    addTearDown(repository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
          dealsProvider.overrideWith((ref) => Stream.value(const [])),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('No transactions yet.'), findsOneWidget);

    expect(
      find.text(
        'Completed sales and other business transactions will appear here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Deals do not appear as Transactions', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryTransactionRepository();
    final inventoryRepository = InMemoryInventoryRepository();
    addTearDown(repository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
          dealsProvider.overrideWith(
            (ref) => Stream.value(const [
              Deal(
                id: 'deal-1',
                parentSaleTransactionId: 'sale-1',
                childInventoryItemIds: ['item-1'],
              ),
            ]),
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No transactions yet.'), findsOneWidget);
    expect(find.byKey(const Key('transactionsDealsSection')), findsNothing);
    expect(find.textContaining('Deals ('), findsNothing);
  });
  testWidgets('displays recorded sales with newest transaction first', (
    WidgetTester tester,
  ) async {
    final olderSale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      notes: 'Older sale.',
      acquisitionValueCents: 20000,
    );

    final newerSale = SaleTransaction(
      id: 'sale-2',
      inventoryItemId: 'item-2',
      salePriceCents: 35000,
      saleDate: DateTime(2026, 8, 4),
      paymentMethod: PaymentMethod.paypal,
      notes: 'Newest sale.',
      acquisitionValueCents: 20000,
    );

    const olderItem = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    const newerItem = InventoryItem(
      id: 'item-2',
      inventoryNumber: 'GLV-2608-0001',
      category: InventoryCategory.glove,
      brand: 'Wilson',
      model: 'A2000',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    final repository = InMemoryTransactionRepository(
      initialSales: [olderSale, newerSale],
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [olderItem, newerItem],
    );

    addTearDown(repository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
          dealsProvider.overrideWith((ref) => Stream.value(const [])),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 transactions', skipOffstage: false), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Card),
        matching: find.text('Sale', skipOffstage: false),
        skipOffstage: false,
      ),
      findsNWidgets(2),
    );

    expect(find.text('08/03/2026', skipOffstage: false), findsOneWidget);
    expect(find.text('08/04/2026', skipOffstage: false), findsOneWidget);

    expect(
      find.text('BAT-2608-0001 — Combat Spec H1', skipOffstage: false),
      findsOneWidget,
    );

    expect(
      find.text('GLV-2608-0001 — Wilson A2000', skipOffstage: false),
      findsOneWidget,
    );

    expect(find.text('item-1', skipOffstage: false), findsNothing);
    expect(find.text('item-2', skipOffstage: false), findsNothing);

    expect(find.text('Cash', skipOffstage: false), findsOneWidget);
    expect(find.text('PayPal', skipOffstage: false), findsOneWidget);

    expect(find.text(r'$325.00', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text(r'$350.00', skipOffstage: false), findsAtLeastNWidgets(1));
    expect(find.text(r'$125.00', skipOffstage: false), findsOneWidget);
    expect(find.text(r'$150.00', skipOffstage: false), findsOneWidget);

    expect(find.text('38.5%', skipOffstage: false), findsOneWidget);
    expect(find.text('42.9%', skipOffstage: false), findsOneWidget);

    expect(find.text('Older sale.', skipOffstage: false), findsOneWidget);
    expect(find.text('Newest sale.', skipOffstage: false), findsOneWidget);

    final newerCard = find.byKey(const ValueKey('sale-2'));

    final olderCard = find.byKey(const ValueKey('sale-1'));

    expect(newerCard, findsOneWidget);
    expect(olderCard, findsOneWidget);

    expect(
      tester.getTopLeft(newerCard).dy,
      lessThan(tester.getTopLeft(olderCard).dy),
    );
  });
  testWidgets('handles a missing related inventory record', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'missing-item',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
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
          dealsProvider.overrideWith((ref) => Stream.value(const [])),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory record unavailable'), findsOneWidget);

    expect(find.text('missing-item'), findsNothing);
  });
  testWidgets('tapping a transaction opens its detail screen', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
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

    final router = GoRouter(
      initialLocation: AppRoutes.transactions,
      routes: [
        GoRoute(
          path: AppRoutes.transactions,
          name: AppRouteNames.transactions,
          builder: (context, state) {
            return const Scaffold(body: TransactionsScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.transactionDetail,
          name: AppRouteNames.transactionDetail,
          builder: (context, state) {
            return Scaffold(
              body: TransactionDetailScreen(
                transactionId: state.pathParameters['transactionId']!,
              ),
            );
          },
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          dealsProvider.overrideWith((ref) => Stream.value(const [])),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final transactionCard = find.byKey(
      const ValueKey('transactionCard-sale-1'),
    );

    expect(transactionCard, findsOneWidget);

    await tester.tap(transactionCard);
    await tester.pumpAndSettle();

    expect(find.text('Sale Transaction'), findsOneWidget);

    expect(find.text('BAT-2608-0001 — Combat Spec H1'), findsOneWidget);

    expect(find.text(r'$325.00'), findsAtLeastNWidgets(1));
  });
}
