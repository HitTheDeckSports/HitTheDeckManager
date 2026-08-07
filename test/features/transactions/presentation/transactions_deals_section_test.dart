import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transactions_screen.dart';

void main() {
  final parentSale = SaleTransaction(
    id: 'sale-a',
    inventoryItemId: 'bat-a',
    salePriceCents: 20000,
    tradeInCreditCents: 10000,
    saleDate: DateTime(2026, 8, 6),
    paymentMethod: PaymentMethod.cash,
    acquisitionValueCents: 15000,
  );

  const parentItem = InventoryItem(
    id: 'bat-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Bat A',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 15000,
    status: InventoryStatus.sold,
  );

  const childItem = InventoryItem(
    id: 'bat-b',
    inventoryNumber: 'BAT-2608-0002',
    category: InventoryCategory.bat,
    brand: 'Bat B',
    acquisitionType: AcquisitionType.traded,
    acquisitionValueCents: 10000,
    askingPriceCents: 20000,
    status: InventoryStatus.available,
  );

  const deal = Deal(
    id: 'deal-a',
    parentSaleTransactionId: 'sale-a',
    childInventoryItemIds: ['bat-b'],
  );

  testWidgets('Transactions displays Deal summary above sales', (tester) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [parentItem, childItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale],
    );
    final dealRepository = InMemoryDealRepository(initialDeals: const [deal]);

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          dealRepositoryProvider.overrideWithValue(dealRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Deals (1)'), findsOneWidget);
    expect(find.text('Sales (1)'), findsOneWidget);
    expect(find.text('Open'), findsAtLeastNWidgets(1));
    expect(find.text('Realized Deal Profit'), findsOneWidget);
    expect(find.text('Projected Deal Profit'), findsOneWidget);
    expect(find.text(r'$50.00'), findsAtLeastNWidgets(1));
    expect(find.text(r'$150.00'), findsNWidgets(2));
  });

  testWidgets('Deal card opens Deal Detail route', (tester) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [parentItem, childItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale],
    );
    final dealRepository = InMemoryDealRepository(initialDeals: const [deal]);

    final router = GoRouter(
      initialLocation: '/transactions',
      routes: [
        GoRoute(
          path: AppRoutes.transactions,
          name: AppRouteNames.transactions,
          builder: (context, state) =>
              const Scaffold(body: TransactionsScreen()),
        ),
        GoRoute(
          path: AppRoutes.dealDetail,
          name: AppRouteNames.dealDetail,
          builder: (context, state) => Scaffold(
            body: Text('Deal route: ${state.pathParameters['dealId']}'),
          ),
        ),
        GoRoute(
          path: AppRoutes.transactionDetail,
          name: AppRouteNames.transactionDetail,
          builder: (context, state) => Scaffold(
            body: Text(
              'Transaction route: ${state.pathParameters['transactionId']}',
            ),
          ),
        ),
      ],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          dealRepositoryProvider.overrideWithValue(dealRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('dealTransactionCardTap-deal-a'));

    expect(card, findsOneWidget);

    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Deal route: deal-a'), findsOneWidget);
  });
}
