import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_screen.dart';
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

    expect(find.text('Inventory'), findsNothing);
    expect(find.text('No inventory items yet.'), findsOneWidget);
    expect(
      find.text('Use Add Inventory to add your first item.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventoryScanQrButton')), findsOneWidget);
    expect(find.byKey(const Key('inventoryAddButton')), findsOneWidget);
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

  testWidgets('InventoryScreen displays photo-forward inventory cards', (
    WidgetTester tester,
  ) async {
    final item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2607-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 32500,
      condition: InventoryCondition.likeNew,
      purchaseDate: DateTime.now().subtract(const Duration(days: 25)),
      lengthInches: 32,
      weightOunces: 29,
      drop: -3,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventorySearchField')), findsOneWidget);
    expect(find.byKey(const Key('inventoryFilterButton')), findsOneWidget);
    expect(find.byKey(const Key('inventoryQuickFilters')), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('1 inventory item'), findsNothing);
    expect(
      find.byKey(const ValueKey('inventoryQuickFilterCount-All')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inventoryQuickFilterCount-Available')),
      findsOneWidget,
    );
    expect(find.text('Combat Spec H1'), findsOneWidget);
    expect(find.text('BAT-2607-0001'), findsOneWidget);
    final inventoryNumber = tester.widget<Text>(
      find.byKey(const ValueKey('inventoryItemNumber-item-1')),
    );
    expect(inventoryNumber.style?.color, const Color(0xFF1768C5));

    final titleWidget = tester.widget<Text>(
      find.byKey(const ValueKey('inventoryItemTitle-item-1')),
    );
    expect(titleWidget.maxLines, 2);
    expect(find.text('Bat • 32 in • 29 oz • -3'), findsOneWidget);
    final itemCard = find.byKey(const ValueKey('inventoryItemTile-item-1'));
    expect(
      find.descendant(of: itemCard, matching: find.text('Available')),
      findsOneWidget,
    );
    expect(find.text(r'$325.00'), findsOneWidget);
    expect(find.text('Like New'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inventoryItemAge-item-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inventoryItemPhoto-item-1')),
      findsOneWidget,
    );
    expect(find.text(r'Cost: $200.00'), findsNothing);
    expect(find.text('No inventory items yet.'), findsNothing);
  });

  testWidgets('Inventory card allows long specialty names to use two lines', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'long-title',
      inventoryNumber: 'BAT-2608-0099',
      category: InventoryCategory.bat,
      brand: 'Louisville Slugger',
      model: 'Meta Limited Edition College World Series Paint Scheme',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 34900,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('inventoryItemTitle-long-title')),
    );

    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.text(r'$349.00'), findsOneWidget);
  });

  testWidgets('InventoryScreen displays helmet size on its card', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'helmet-1',
      inventoryNumber: 'HLM-2608-0001',
      category: InventoryCategory.helmet,
      brand: 'Easton',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 8000,
      helmetSize: 'L/XL',
    );
    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('L/XL'), findsOneWidget);
  });

  testWidgets('Inventory cards never display acquisition cost', (
    WidgetTester tester,
  ) async {
    final item = InventoryItem(
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

    expect(find.text(r'$325.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsNothing);
    expect(find.textContaining('Cost:'), findsNothing);
  });

  testWidgets('Inventory search filters displayed items', (
    WidgetTester tester,
  ) async {
    const combat = InventoryItem(
      id: 'item-combat',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      certification: 'BBCOR',
    );

    const easton = InventoryItem(
      id: 'item-easton',
      inventoryNumber: 'BAT-2608-0002',
      category: InventoryCategory.bat,
      brand: 'Easton',
      model: 'Hype Fire',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 25000,
      certification: 'USSSA',
    );

    final repository = InMemoryInventoryRepository(
      initialItems: [combat, easton],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 inventory items'), findsNothing);
    expect(find.text('Combat Spec H1'), findsOneWidget);
    expect(find.text('Easton Hype Fire'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('inventorySearchField')),
      'USSSA',
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 items'), findsOneWidget);
    expect(find.text('Combat Spec H1'), findsNothing);
    expect(find.text('Easton Hype Fire'), findsOneWidget);
    expect(find.byKey(const Key('inventorySearchClearButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('inventorySearchClearButton')));
    await tester.pumpAndSettle();

    expect(find.text('2 inventory items'), findsNothing);
    expect(find.text('Combat Spec H1'), findsOneWidget);
    expect(find.text('Easton Hype Fire'), findsOneWidget);
  });

  testWidgets('Inventory search displays a no-results state', (
    WidgetTester tester,
  ) async {
    final item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inventorySearchField')),
      'Louisville Atlas',
    );
    await tester.pumpAndSettle();

    expect(find.text('0 of 1 items'), findsOneWidget);
    expect(find.text('Combat Spec H1'), findsNothing);
    expect(find.text('No inventory items match your search.'), findsOneWidget);
    expect(
      find.text('Try a different inventory number, brand, or model.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping an inventory item opens its detail screen', (
    WidgetTester tester,
  ) async {
    final item = InventoryItem(
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

    expect(find.text('Combat Spec H1'), findsAtLeastNWidgets(1));
    expect(find.text('BAT-2608-0001'), findsAtLeastNWidgets(1));
    expect(find.text('32 in'), findsOneWidget);
    expect(find.text('29 oz'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
  });
}
