import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/edit_inventory_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  Widget createTestApp({
    required InMemoryInventoryRepository repository,
    required String itemId,
  }) {
    return ProviderScope(
      overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(body: InventoryItemDetailScreen(itemId: itemId)),
      ),
    );
  }

  testWidgets('displays all saved bat inventory details', (
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
      condition: InventoryCondition.likeNew,
      status: InventoryStatus.available,
      purchaseDate: DateTime(2026, 8, 2),
      newValueCents: 49999,
      askingPriceCents: 32500,
      minimumPriceCents: 27500,
      lengthInches: 32,
      weightOunces: 29,
      drop: -3,
      certification: 'BBCOR',
      notes: 'Limited-edition bat.',
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      createTestApp(repository: repository, itemId: 'item-1'),
    );

    await tester.pumpAndSettle();

    expect(find.text('Combat Spec H1'), findsOneWidget);
    expect(find.text('BAT-2608-0001'), findsAtLeastNWidgets(1));

    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Bat'), findsOneWidget);
    expect(find.text('Purchased'), findsOneWidget);
    expect(find.text('Like New'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('08/02/2026'), findsOneWidget);

    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text(r'$200.00'), findsOneWidget);
    expect(find.text(r'$499.99'), findsOneWidget);
    expect(find.text(r'$325.00'), findsOneWidget);
    expect(find.text(r'$275.00'), findsOneWidget);

    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('32 in'), findsOneWidget);
    expect(find.text('29 oz'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
    expect(find.text('BBCOR'), findsOneWidget);
    expect(find.text('Limited-edition bat.'), findsOneWidget);
  });

  testWidgets('displays glove-specific inventory details', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-2',
      inventoryNumber: 'GLV-2608-0001',
      category: InventoryCategory.glove,
      brand: 'Rawlings',
      model: 'Heart of the Hide',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 12500,
      gloveSizeInches: 11.5,
      handOrientation: 'Right Hand Throw',
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      createTestApp(repository: repository, itemId: 'item-2'),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rawlings Heart of the Hide'), findsOneWidget);
    expect(find.text('Glove'), findsOneWidget);
    expect(find.text('Traded'), findsOneWidget);
    expect(find.text('11.5 in'), findsOneWidget);
    expect(find.text('Right Hand Throw'), findsOneWidget);

    expect(find.text('Bat Length'), findsNothing);
    expect(find.text('Bat Weight'), findsNothing);
    expect(find.text('Drop'), findsNothing);
  });

  testWidgets('displays not-found state for unknown item ID', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryInventoryRepository();

    await tester.pumpWidget(
      createTestApp(repository: repository, itemId: 'missing-item'),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory item not found.'), findsOneWidget);

    expect(
      find.text('The item may have been removed or is no longer available.'),
      findsOneWidget,
    );
  });
  testWidgets('Edit button opens a prefilled edit form', (
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
      condition: InventoryCondition.likeNew,
      askingPriceCents: 32500,
      lengthInches: 32,
      weightOunces: 29,
      drop: -3,
      certification: 'BBCOR',
      notes: 'Original notes.',
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    addTearDown(repository.dispose);

    final router = GoRouter(
      initialLocation: '/inventory/item-1',
      routes: [
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
        GoRoute(
          path: AppRoutes.inventoryEdit,
          name: AppRouteNames.inventoryEdit,
          builder: (context, state) {
            return Scaffold(
              body: EditInventoryScreen(
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

    final editButton = find.byKey(const Key('inventoryItemEditButton'));

    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Inventory'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    final brandField = tester.widget<TextFormField>(
      find.byKey(const Key('buyInventoryBrandField')),
    );

    final modelField = tester.widget<TextFormField>(
      find.byKey(const Key('buyInventoryModelField')),
    );

    final acquisitionValueField = tester.widget<TextFormField>(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
    );

    expect(brandField.initialValue, 'Combat');
    expect(modelField.initialValue, 'Spec H1');
    expect(acquisitionValueField.initialValue, '200.00');

    expect(find.byKey(const Key('buyInventoryLengthField')), findsOneWidget);

    expect(find.byKey(const Key('buyInventoryWeightField')), findsOneWidget);

    expect(find.byKey(const Key('buyInventoryDropField')), findsOneWidget);
  });
  testWidgets('changes and persists inventory status', (
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
      status: InventoryStatus.available,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final statusButton = find.byKey(const Key('inventoryItemStatusButton'));

    expect(statusButton, findsOneWidget);
    expect(find.text('Available'), findsOneWidget);

    await tester.tap(statusButton);
    await tester.pumpAndSettle();

    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Broken'), findsOneWidget);
    expect(find.text('Sold'), findsNothing);
    expect(find.text('Disposed'), findsNothing);

    await tester.tap(find.text('Inactive'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory status changed to Inactive.'), findsOneWidget);

    final storedItem = await repository.getInventoryItem('item-1');

    expect(storedItem, isNotNull);
    expect(storedItem?.status, InventoryStatus.inactive);
    expect(storedItem?.id, item.id);
    expect(storedItem?.inventoryNumber, item.inventoryNumber);
    expect(storedItem?.brand, item.brand);
    expect(storedItem?.model, item.model);
  });
}
