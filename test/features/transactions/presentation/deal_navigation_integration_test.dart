import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';

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
    status: InventoryStatus.available,
  );

  const deal = Deal(
    id: 'deal-a',
    parentSaleTransactionId: 'sale-a',
    childInventoryItemIds: ['bat-b'],
  );

  testWidgets('parent sale displays View Deal and opens Deal route', (
    tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [parentItem, childItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale],
    );
    final dealRepository = InMemoryDealRepository(initialDeals: const [deal]);

    final router = GoRouter(
      initialLocation: '/transactions/sale-a',
      routes: [
        GoRoute(
          path: AppRoutes.transactionDetail,
          name: AppRouteNames.transactionDetail,
          builder: (context, state) => Scaffold(
            body: TransactionDetailScreen(
              transactionId: state.pathParameters['transactionId']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.dealDetail,
          name: AppRouteNames.dealDetail,
          builder: (context, state) => Scaffold(
            body: Text('Deal route: ${state.pathParameters['dealId']}'),
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

    final button = find.byKey(const Key('saleViewDealButton'));
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Deal route: deal-a'), findsOneWidget);
  });

  testWidgets('child inventory displays View Deal and opens Deal route', (
    tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [parentItem, childItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale],
    );
    final dealRepository = InMemoryDealRepository(initialDeals: const [deal]);

    final router = GoRouter(
      initialLocation: '/inventory/bat-b',
      routes: [
        GoRoute(
          path: AppRoutes.inventoryDetail,
          name: AppRouteNames.inventoryDetail,
          builder: (context, state) => Scaffold(
            body: InventoryItemDetailScreen(
              itemId: state.pathParameters['itemId']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.dealDetail,
          name: AppRouteNames.dealDetail,
          builder: (context, state) => Scaffold(
            body: Text('Deal route: ${state.pathParameters['dealId']}'),
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

    final button = find.byKey(const Key('inventoryViewDealButton'));
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Deal route: deal-a'), findsOneWidget);
  });

  testWidgets('ordinary sale does not display View Deal', (tester) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [parentItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale],
    );
    final dealRepository = InMemoryDealRepository();

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
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-a'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saleViewDealButton')), findsNothing);
  });
}
