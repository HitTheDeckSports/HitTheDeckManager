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
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';

void main() {
  testWidgets('sale details display linked trade-in inventory', (tester) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'sold-item',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 6),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 20000,
    );

    final trade = TradeTransaction(
      id: 'trade-1',
      saleTransactionId: 'sale-1',
      outgoingInventoryItemIds: const ['sold-item'],
      incomingInventoryItemIds: const ['trade-in-1'],
      tradeDate: DateTime(2026, 8, 6),
    );

    const soldItem = InventoryItem(
      id: 'sold-item',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    const tradeInItem = InventoryItem(
      id: 'trade-in-1',
      inventoryNumber: 'GLV-2608-0001',
      category: InventoryCategory.glove,
      brand: 'Rawlings',
      model: 'Heart of the Hide',
      acquisitionType: AcquisitionType.traded,
      condition: InventoryCondition.good,
      acquisitionValueCents: 15000,
      status: InventoryStatus.available,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
      initialTrades: [trade],
    );
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem, tradeInItem],
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

    expect(find.text('Trade-In Information'), findsOneWidget);
    expect(
      find.text('GLV-2608-0001 â€” Rawlings Heart of the Hide'),
      findsOneWidget,
    );
    expect(find.text('Good'), findsOneWidget);
    expect(find.text(r'$150.00'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('transactionTradeInViewInventoryButton-trade-in-1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sale without trade-ins displays an empty trade-in message', (
    tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'sold-item',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 6),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 20000,
    );

    const soldItem = InventoryItem(
      id: 'sold-item',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem],
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

    expect(find.text('Trade-In Information'), findsOneWidget);
    expect(
      find.text('No trade-in items were included with this sale.'),
      findsOneWidget,
    );
  });

  testWidgets('View Inventory Item opens the linked inventory route', (
    tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'sold-item',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 6),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 20000,
    );

    final trade = TradeTransaction(
      id: 'trade-1',
      saleTransactionId: 'sale-1',
      outgoingInventoryItemIds: const ['sold-item'],
      incomingInventoryItemIds: const ['trade-in-1'],
      tradeDate: DateTime(2026, 8, 6),
    );

    const soldItem = InventoryItem(
      id: 'sold-item',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    const tradeInItem = InventoryItem(
      id: 'trade-in-1',
      inventoryNumber: 'GLV-2608-0001',
      category: InventoryCategory.glove,
      brand: 'Rawlings',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 15000,
      status: InventoryStatus.available,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
      initialTrades: [trade],
    );
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem, tradeInItem],
    );

    final router = GoRouter(
      initialLocation: '/transactions/sale-1',
      routes: [
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
        GoRoute(
          path: AppRoutes.inventoryDetail,
          name: AppRouteNames.inventoryDetail,
          builder: (context, state) {
            return Scaffold(
              body: Text('Inventory route: ${state.pathParameters['itemId']}'),
            );
          },
        ),
      ],
    );

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final button = find.byKey(
      const ValueKey('transactionTradeInViewInventoryButton-trade-in-1'),
    );

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Inventory route: trade-in-1'), findsOneWidget);
  });
}
