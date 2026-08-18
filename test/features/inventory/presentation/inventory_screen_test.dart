import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  testWidgets('InventoryScreen displays an empty state', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryInventoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('No inventory items yet.'), findsOneWidget);
    expect(
      find.text('Use Buy Inventory to add your first item.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventoryScanQrButton')), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
  });
  testWidgets('Scan QR button opens the inventory scanner route', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryInventoryRepository();
    addTearDown(repository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.inventory,
      routes: [
        GoRoute(
          path: AppRoutes.inventory,
          name: AppRouteNames.inventory,
          builder: (context, state) {
            return const Scaffold(body: InventoryScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.inventoryScanner,
          name: AppRouteNames.inventoryScanner,
          builder: (context, state) {
            return const Scaffold(
              body: Center(child: Text('Inventory scanner destination')),
            );
          },
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final scanButton = find.byKey(const Key('inventoryScanQrButton'));

    expect(scanButton, findsOneWidget);

    await tester.tap(scanButton);
    await tester.pumpAndSettle();

    expect(find.text('Inventory scanner destination'), findsOneWidget);
  });

  testWidgets('InventoryScreen displays repository items', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2607-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 32500,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 inventory item'), findsOneWidget);
    expect(find.text('Combat Spec H1'), findsOneWidget);
    expect(find.text('Bat • BAT-2607-0001'), findsOneWidget);
    expect(find.text(r'$325.00'), findsOneWidget);
    expect(find.text(r'Cost: $200.00'), findsOneWidget);
    expect(find.text('No inventory items yet.'), findsNothing);
  });
  testWidgets('tapping an inventory item opens its detail screen', (
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
      lengthInches: 32,
      weightOunces: 29,
      drop: -3,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);
    addTearDown(repository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.inventory,
      routes: [
        GoRoute(
          path: AppRoutes.inventory,
          builder: (context, state) {
            return const Scaffold(body: InventoryScreen());
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
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final itemTile = find.byKey(const ValueKey('inventoryItemTile-item-1'));

    expect(itemTile, findsOneWidget);

    await tester.tap(itemTile);
    await tester.pumpAndSettle();

    expect(find.text('Combat Spec H1'), findsOneWidget);
    expect(find.text('BAT-2608-0001'), findsAtLeastNWidgets(1));
    expect(find.text('32 in'), findsOneWidget);
    expect(find.text('29 oz'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
  });
}
