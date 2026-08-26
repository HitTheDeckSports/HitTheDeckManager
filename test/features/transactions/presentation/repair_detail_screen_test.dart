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
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/repair_detail_screen.dart';

void main() {
  testWidgets('displays repair and linked inventory item details', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Completed in-house.',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialRepairs: [repair],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RepairDetailScreen(repairId: 'repair-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Repair Details'), findsOneWidget);
    expect(find.text('Repair Information'), findsOneWidget);
    expect(find.text('08/05/2026'), findsAtLeastNWidgets(1));
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.text('Replaced damaged grip.'), findsOneWidget);
    expect(find.text('Completed in-house.'), findsOneWidget);

    expect(find.text('Inventory Item'), findsOneWidget);
    expect(find.text('BAT-2608-0001'), findsOneWidget);
    expect(find.text('Combat Spec H1'), findsOneWidget);

    expect(find.byKey(const Key('repairEditButton')), findsOneWidget);

    expect(find.byKey(const Key('repairDeleteButton')), findsOneWidget);

    expect(
      find.byKey(const Key('repairViewInventoryItemButton')),
      findsOneWidget,
    );
  });

  testWidgets('displays not-found state for unknown repair', (
    WidgetTester tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository();

    final transactionRepository = InMemoryTransactionRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RepairDetailScreen(repairId: 'missing-repair')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Repair not found.'), findsOneWidget);

    expect(
      find.text('The repair may have been removed or is no longer available.'),
      findsOneWidget,
    );

    expect(find.byKey(const Key('repairDeleteButton')), findsNothing);
  });

  testWidgets('handles missing linked inventory item', (
    WidgetTester tester,
  ) async {
    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'missing-item',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final inventoryRepository = InMemoryInventoryRepository();

    final transactionRepository = InMemoryTransactionRepository(
      initialRepairs: [repair],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RepairDetailScreen(repairId: 'repair-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('The inventory item linked to this repair is unavailable.'),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('repairViewInventoryItemButton')),
      findsNothing,
    );

    expect(find.text(r'$45.00'), findsOneWidget);
  });

  testWidgets('View Inventory Item opens linked item details', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialRepairs: [repair],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    final router = GoRouter(
      initialLocation: '/repairs/repair-1',
      routes: [
        GoRoute(
          path: AppRoutes.repairDetail,
          name: AppRouteNames.repairDetail,
          builder: (context, state) {
            return Scaffold(
              body: RepairDetailScreen(
                repairId: state.pathParameters['repairId']!,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.inventoryDetail,
          name: AppRouteNames.inventoryDetail,
          builder: (context, state) {
            return Scaffold(
              body: InventoryItemDetailScreen(
                itemId: state.pathParameters['itemId']!,
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
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final viewItemButton = find.byKey(
      const Key('repairViewInventoryItemButton'),
    );

    await tester.ensureVisible(viewItemButton);
    await tester.tap(viewItemButton);
    await tester.pumpAndSettle();

    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('BAT-2608-0001'), findsAtLeastNWidgets(1));
    expect(find.text('Combat'), findsAtLeastNWidgets(1));
    expect(find.text('Spec H1'), findsAtLeastNWidgets(1));
  });

  testWidgets('canceling deletion keeps the repair', (
    WidgetTester tester,
  ) async {
    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final inventoryRepository = InMemoryInventoryRepository();

    final transactionRepository = InMemoryTransactionRepository(
      initialRepairs: [repair],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RepairDetailScreen(repairId: 'repair-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final deleteButton = find.byKey(const Key('repairDeleteButton'));

    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete Repair?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('repairDeleteCancelButton')));

    await tester.pumpAndSettle();

    expect(await transactionRepository.getRepair('repair-1'), repair);

    expect(find.text('Repair Details'), findsOneWidget);
  });

  testWidgets('confirmed deletion removes repair and returns to item', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    final repair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialRepairs: [repair],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    final router = GoRouter(
      initialLocation: '/repairs/repair-1',
      routes: [
        GoRoute(
          path: AppRoutes.repairDetail,
          name: AppRouteNames.repairDetail,
          builder: (context, state) {
            return Scaffold(
              body: RepairDetailScreen(
                repairId: state.pathParameters['repairId']!,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.inventoryDetail,
          name: AppRouteNames.inventoryDetail,
          builder: (context, state) {
            return Scaffold(
              body: InventoryItemDetailScreen(
                itemId: state.pathParameters['itemId']!,
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
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final deleteButton = find.byKey(const Key('repairDeleteButton'));

    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('repairDeleteConfirmButton')));

    await tester.pumpAndSettle();

    expect(await transactionRepository.getRepair('repair-1'), isNull);

    expect(find.text('Basic Information'), findsOneWidget);
    expect(
      find.text('No repairs have been recorded for this item.'),
      findsOneWidget,
    );
    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsAtLeastNWidgets(2));
  });
}
