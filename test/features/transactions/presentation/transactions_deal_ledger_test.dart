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
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_status.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_ledger_provider.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transactions_screen.dart';

void main() {
  const rootItem = InventoryItem(
    id: 'root-item',
    inventoryNumber: 'BAT-2609-0100',
    category: InventoryCategory.bat,
    brand: 'Root',
    model: 'Origin',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 10000,
    status: InventoryStatus.sold,
  );

  const relatedItem = InventoryItem(
    id: 'related-item',
    inventoryNumber: 'BAT-2609-0101',
    category: InventoryCategory.bat,
    brand: 'Trade',
    model: 'Branch',
    acquisitionType: AcquisitionType.traded,
    acquisitionValueCents: 7000,
    status: InventoryStatus.available,
  );

  final deal = Deal(
    id: 'deal-ledger',
    parentSaleTransactionId: 'sale-root',
    childInventoryItemIds: const ['related-item'],
    notes: 'Customer trade progression',
    createdAt: DateTime(2026, 9, 12),
  );

  DealLedgerSummary summary() => DealLedgerSummary(
    deal: deal,
    displayNumber: '2026-014',
    status: DealStatus.partiallyRealized,
    currentProfitCents: 4200,
    date: DateTime(2026, 9, 12),
    rootItem: rootItem,
    relatedInventoryItems: const [relatedItem],
  );

  Future<void> pumpLedger(
    WidgetTester tester, {
    bool withDealRoute = false,
  }) async {
    final transactionRepository = InMemoryTransactionRepository();
    final inventoryRepository = InMemoryInventoryRepository();
    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    if (!withDealRoute) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
            inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
            dealLedgerSummariesProvider.overrideWith(
              (ref) async => [summary()],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
        ),
      );
      await tester.pumpAndSettle();
      return;
    }

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
          path: AppRoutes.dealDetail,
          name: AppRouteNames.dealDetail,
          builder: (context, state) => Scaffold(
            body: Text('Deal route: ${state.pathParameters['dealId']}'),
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
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          dealLedgerSummariesProvider.overrideWith((ref) async => [summary()]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Deal search matches number, status, and linked inventory', (
    tester,
  ) async {
    await pumpLedger(tester);

    final search = find.byKey(const Key('transactionsSearchField'));

    await tester.enterText(search, '2026-014');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dealLedgerCard-deal-ledger')),
      findsOneWidget,
    );

    await tester.enterText(search, 'Partially Realized');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dealLedgerCard-deal-ledger')),
      findsOneWidget,
    );

    await tester.enterText(search, 'BAT-2609-0101');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dealLedgerCard-deal-ledger')),
      findsOneWidget,
    );

    await tester.enterText(search, 'not-a-match');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dealLedgerCard-deal-ledger')),
      findsNothing,
    );
  });

  testWidgets('Deal is available in transaction type filter', (tester) async {
    await pumpLedger(tester);

    await tester.tap(find.byKey(const Key('transactionsFilterButton')));
    await tester.pumpAndSettle();

    final dealFilter = find.byKey(
      const ValueKey('transactionsTypeFilter-deal'),
    );
    expect(dealFilter, findsOneWidget);

    await tester.tap(dealFilter);
    await tester.tap(find.byKey(const Key('transactionsTypeSheetDoneButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dealLedgerCard-deal-ledger')),
      findsOneWidget,
    );
    expect(find.text('1 of 1 transactions'), findsOneWidget);
  });

  testWidgets('Deal ledger card opens Deal Detail route', (tester) async {
    await pumpLedger(tester, withDealRoute: true);

    final dealTap = find.byKey(const ValueKey('dealLedgerTap-deal-ledger'));
    expect(dealTap, findsOneWidget);

    await tester.tap(dealTap);
    await tester.pumpAndSettle();

    expect(find.text('Deal route: deal-ledger'), findsOneWidget);
  });
}
