import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transactions_screen.dart';

void main() {
  testWidgets('Transactions keeps type choices off page until selector opens', (
    tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-filter-test',
      inventoryItemId: 'item-filter-test',
      salePriceCents: 25000,
      saleDate: DateTime(2026, 9, 9),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 10000,
    );
    const item = InventoryItem(
      id: 'item-filter-test',
      inventoryNumber: 'BAT-2609-0099',
      category: InventoryCategory.bat,
      brand: 'Rawlings',
      model: 'Icon',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 10000,
      status: InventoryStatus.sold,
    );

    final repository = InMemoryTransactionRepository(initialSales: [sale]);
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
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

    expect(find.byKey(const Key('transactionsFilterButton')), findsOneWidget);
    expect(
      find.byKey(const Key('transactionsMinimumAmountField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('transactionsMaximumAmountField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transactionsTypeFilter-sale')),
      findsNothing,
    );
  });

  testWidgets('displays the empty transactions state', (tester) async {
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

    expect(find.text('Transactions'), findsNothing);
    expect(find.text('No transactions yet.'), findsOneWidget);
  });

  testWidgets('Deals do not appear as Transactions', (tester) async {
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
    expect(find.textContaining('Deals ('), findsNothing);
  });

  testWidgets('displays compact sales with visible values newest first', (
    tester,
  ) async {
    final olderSale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 20000,
    );
    final newerSale = SaleTransaction(
      id: 'sale-2',
      inventoryItemId: 'item-2',
      salePriceCents: 35000,
      saleDate: DateTime(2026, 8, 4),
      paymentMethod: PaymentMethod.paypal,
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

    expect(find.text('2 transactions'), findsOneWidget);
    expect(find.byKey(const Key('transactionsSearchField')), findsOneWidget);
    expect(find.byKey(const Key('transactionsFilterButton')), findsOneWidget);
    expect(find.text(r'+$350.00'), findsOneWidget);
    expect(find.text(r'+$325.00'), findsOneWidget);
    expect(find.text('GLV-2608-0001'), findsOneWidget);
    expect(find.text('Wilson A2000 • PayPal sale'), findsOneWidget);
    expect(find.text('BAT-2608-0001'), findsOneWidget);
    expect(find.text('Combat Spec H1 • Cash sale'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transactionTypePill-sale')),
      findsNWidgets(2),
    );

    final newerCard = find.byKey(const ValueKey('sale-2'));
    final olderCard = find.byKey(const ValueKey('sale-1'));
    expect(
      tester.getTopLeft(newerCard).dy,
      lessThan(tester.getTopLeft(olderCard).dy),
    );
  });

  testWidgets('purchased inventory appears as a purchase ledger event', (
    tester,
  ) async {
    final repository = InMemoryTransactionRepository();
    final purchasedItem = InventoryItem(
      id: 'purchase-item',
      inventoryNumber: 'BAT-2609-0042',
      category: InventoryCategory.bat,
      brand: 'Rawlings',
      model: 'Icon',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 17500,
      purchaseDate: DateTime(2026, 9, 8),
    );
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: [purchasedItem],
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
    expect(
      find.byKey(const ValueKey('purchaseInventoryCard-purchase-item')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transactionTypePill-purchase')),
      findsOneWidget,
    );
    expect(find.text(r'-$175.00'), findsOneWidget);
  });

  testWidgets('tapping a sale opens its detail screen', (tester) async {
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
          builder: (context, state) =>
              const Scaffold(body: TransactionsScreen()),
        ),
        GoRoute(
          path: AppRoutes.transactionDetail,
          name: AppRouteNames.transactionDetail,
          builder: (context, state) => Scaffold(
            body: TransactionDetailScreen(
              transactionId: state.pathParameters['transactionId']!,
            ),
          ),
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

    await tester.tap(find.byKey(const ValueKey('transactionCard-sale-1')));
    await tester.pumpAndSettle();

    expect(find.text('Sale Transaction'), findsNothing);
    expect(
      find.byKey(const Key('saleTransactionDetailsSection')),
      findsOneWidget,
    );
    expect(find.text(r'$325.00'), findsAtLeastNWidgets(1));
  });
}
