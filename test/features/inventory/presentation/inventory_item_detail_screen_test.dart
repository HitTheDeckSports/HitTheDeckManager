import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/edit_inventory_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/add_repair_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';

void main() {
  Widget createTestApp({
    required InMemoryInventoryRepository repository,
    required String itemId,
  }) {
    final transactionRepository = InMemoryTransactionRepository();

    return ProviderScope(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(repository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
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

    expect(find.text('Combat Spec H1'), findsAtLeastNWidgets(1));
    expect(find.text('BAT-2608-0001'), findsAtLeastNWidgets(1));

    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Bat'), findsOneWidget);
    expect(find.text('Purchased'), findsOneWidget);
    expect(find.text('Like New'), findsOneWidget);
    expect(find.text('Available'), findsAtLeastNWidgets(1));
    expect(find.text('08/02/2026'), findsOneWidget);

    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text(r'$200.00'), findsAtLeastNWidgets(2));
    expect(find.text(r'$499.99'), findsOneWidget);
    expect(find.text(r'$325.00'), findsAtLeastNWidgets(2));
    expect(find.text(r'$275.00'), findsOneWidget);
    expect(find.byKey(const Key('inventoryItemSummaryCard')), findsOneWidget);
    expect(
      find.byKey(const Key('inventoryItemTotalCostMetric')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryItemEstimatedProfitMetric')),
      findsOneWidget,
    );
    expect(find.text('Est. Profit'), findsOneWidget);
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(
      find.byKey(const Key('inventoryPrimaryPhotoPlaceholder')),
      findsOneWidget,
    );

    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('32 in'), findsOneWidget);
    expect(find.text('29 oz'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
    expect(find.text('BBCOR'), findsOneWidget);
    expect(find.text('Limited-edition bat.'), findsOneWidget);
  });

  testWidgets('ordinary User does not see inventory cost or profit', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'ordinary-user-item',
      inventoryNumber: 'BAT-2608-0200',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 32500,
    );
    final repository = InMemoryInventoryRepository(initialItems: const [item]);
    final transactionRepository = InMemoryTransactionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAppPermissionsProvider.overrideWithValue(
            const AppPermissions.none(),
          ),
          inventoryRepositoryProvider.overrideWithValue(repository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: InventoryItemDetailScreen(itemId: 'ordinary-user-item'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asking Price'), findsAtLeastNWidgets(1));
    expect(find.text(r'$325.00'), findsAtLeastNWidgets(1));
    expect(find.text('Acquisition Value'), findsNothing);
    expect(find.text('Total Cost'), findsNothing);
    expect(find.text('Est. Profit'), findsNothing);
    expect(find.text('True Cost'), findsNothing);
    expect(find.byKey(const Key('inventoryItemTotalCostMetric')), findsNothing);
    expect(
      find.byKey(const Key('inventoryItemEstimatedProfitMetric')),
      findsNothing,
    );
  });

  testWidgets('displays saved inventory photos on the detail screen', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-with-photos',
      inventoryNumber: 'BAT-2608-0099',
      category: InventoryCategory.bat,
      brand: 'Easton',
      model: 'Hype Fire',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 10000,
      photoUrls: [
        'https://example.invalid/primary.jpg',
        'https://example.invalid/secondary.jpg',
      ],
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      createTestApp(repository: repository, itemId: 'item-with-photos'),
    );

    await tester.pump();

    expect(find.text('Photos'), findsOneWidget);
    expect(find.byKey(const Key('inventoryPrimaryPhoto')), findsOneWidget);
    expect(find.byKey(const Key('inventoryPhotoThumbnail-1')), findsOneWidget);
    expect(find.byKey(const Key('inventoryPhotoCountLabel')), findsOneWidget);
    expect(find.text('2'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('inventoryItemStatusBadge')), findsOneWidget);
  });

  testWidgets('Sell Item opens a sale for the selected inventory item', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-sell-action',
      inventoryNumber: 'BAT-2608-0101',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 32500,
      status: InventoryStatus.available,
    );
    final repository = InMemoryInventoryRepository(initialItems: const [item]);
    final transactionRepository = InMemoryTransactionRepository();

    final router = GoRouter(
      initialLocation: '/inventory/item-sell-action',
      routes: [
        GoRoute(
          path: AppRoutes.sellInventory,
          name: AppRouteNames.sellInventory,
          builder: (context, state) {
            final selectedItem = state.extra as InventoryItem?;
            return Scaffold(
              body: Text('Selling ${selectedItem?.inventoryNumber}'),
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
          inventoryRepositoryProvider.overrideWithValue(repository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventoryItemPrimaryActions')),
      findsOneWidget,
    );
    final sellButton = find.byKey(const Key('inventoryItemSellButton'));
    expect(sellButton, findsOneWidget);

    await tester.ensureVisible(sellButton);
    await tester.pumpAndSettle();
    await tester.tap(sellButton);
    await tester.pumpAndSettle();

    expect(find.text('Selling BAT-2608-0101'), findsOneWidget);
  });

  testWidgets('sold inventory does not display the Sell Item action', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'sold-item-actions',
      inventoryNumber: 'BAT-2608-0102',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );
    final repository = InMemoryInventoryRepository(initialItems: const [item]);

    await tester.pumpWidget(
      createTestApp(repository: repository, itemId: 'sold-item-actions'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventoryItemSellButton')), findsNothing);
  });

  testWidgets('opens inventory QR code from the QR action', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-qr-123',
      inventoryNumber: 'BAT-2608-0100',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 10000,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      createTestApp(repository: repository, itemId: 'item-qr-123'),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventoryItemQrButton')), findsOneWidget);

    expect(find.byKey(const Key('inventoryQrCode')), findsNothing);

    final qrButton = find.byKey(const Key('inventoryItemQrButton'));
    await tester.ensureVisible(qrButton);
    await tester.pumpAndSettle();
    await tester.tap(qrButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventoryQrDialog')), findsOneWidget);
    expect(find.byKey(const Key('inventoryQrCode')), findsOneWidget);

    expect(find.text('Inventory QR Code'), findsOneWidget);
    expect(find.text('BAT-2608-0100'), findsAtLeastNWidgets(1));
    expect(find.text('Combat Spec H1'), findsAtLeastNWidgets(1));

    expect(
      find.text('Scan this code to open this inventory item.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventoryPrintLabelButton')), findsOneWidget);
    expect(find.text('Print Label'), findsOneWidget);
  });
  testWidgets('Print Label opens Avery starting position selection', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-label-123',
      inventoryNumber: 'BAT-2608-0101',
      category: InventoryCategory.bat,
      brand: 'Easton',
      model: 'Hype Fire',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 10000,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      createTestApp(repository: repository, itemId: 'item-label-123'),
    );

    await tester.pumpAndSettle();

    final qrButton = find.byKey(const Key('inventoryItemQrButton'));
    await tester.ensureVisible(qrButton);
    await tester.pumpAndSettle();
    await tester.tap(qrButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventoryPrintLabelButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('inventoryPrintLabelButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventoryLabelPositionDialog')),
      findsOneWidget,
    );

    expect(find.text('Choose Label Position'), findsOneWidget);

    expect(
      find.text(
        'Select the first unused label position on the Avery 5366 sheet.',
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('inventoryLabelPositionField')),
      findsOneWidget,
    );

    expect(find.text('Position 1'), findsOneWidget);

    expect(find.text('Avery 5366 has 30 labels per sheet.'), findsOneWidget);

    expect(
      find.byKey(const Key('inventoryLabelPositionCancelButton')),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('inventoryLabelPositionContinueButton')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('inventoryLabelPositionCancelButton')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventoryLabelPositionDialog')), findsNothing);

    expect(find.byKey(const Key('inventoryQrDialog')), findsOneWidget);
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

    expect(find.text('Rawlings Heart of the Hide'), findsAtLeastNWidgets(1));
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
    expect(find.text('Available'), findsAtLeastNWidgets(1));

    await tester.ensureVisible(statusButton);
    await tester.pumpAndSettle();
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
  testWidgets('sold item displays matching sale information', (
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
      status: InventoryStatus.sold,
    );

    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.venmo,
      notes: 'Sold during tournament.',
      acquisitionValueCents: 20000,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
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
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Information'), findsOneWidget);
    expect(find.text('08/03/2026'), findsOneWidget);
    expect(find.text('Venmo'), findsOneWidget);
    expect(find.text(r'$325.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsAtLeastNWidgets(1));
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(find.text('38.5%'), findsOneWidget);
    expect(find.text('Sold during tournament.'), findsOneWidget);

    expect(
      find.byKey(const Key('inventoryItemViewTransactionButton')),
      findsOneWidget,
    );
  });
  testWidgets('available item does not display sale information', (
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

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

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
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Information'), findsNothing);

    expect(
      find.byKey(const Key('inventoryItemViewTransactionButton')),
      findsNothing,
    );
  });
  testWidgets('sold item without a sale displays warning', (
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
      status: InventoryStatus.sold,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

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
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Information'), findsOneWidget);

    expect(
      find.text(
        'This item is marked Sold, but no matching sale transaction was found.',
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('inventoryItemViewTransactionButton')),
      findsNothing,
    );
  });
  testWidgets('View Transaction opens matching transaction details', (
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
      status: InventoryStatus.sold,
    );

    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      notes: 'Navigation test sale.',
      acquisitionValueCents: 20000,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

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
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final viewTransactionButton = find.byKey(
      const Key('inventoryItemViewTransactionButton'),
    );

    expect(viewTransactionButton, findsOneWidget);

    await tester.ensureVisible(viewTransactionButton);
    await tester.pumpAndSettle();

    await tester.tap(viewTransactionButton);
    await tester.pumpAndSettle();

    expect(find.text('Sale Transaction'), findsOneWidget);
    expect(find.text('Transaction Summary'), findsOneWidget);

    expect(find.text('BAT-2608-0001 — Combat Spec H1'), findsOneWidget);

    expect(find.text('Navigation test sale.'), findsOneWidget);
  });
  testWidgets('item without a seller displays no seller linked', (
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

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Seller Information'), findsOneWidget);
    expect(find.text('No seller linked'), findsOneWidget);

    expect(
      find.byKey(const Key('inventoryItemViewSellerButton')),
      findsNothing,
    );
  });
  testWidgets('linked seller information is displayed', (
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
      sellerContactId: 'contact-1',
    );

    const seller = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
      email: 'taylor@example.com',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [seller],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Seller Information'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsOneWidget);
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);

    expect(
      find.byKey(const Key('inventoryItemViewSellerButton')),
      findsOneWidget,
    );
  });
  testWidgets('missing linked seller displays warning', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      sellerContactId: 'missing-contact',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Seller Information'), findsOneWidget);

    expect(
      find.text(
        'A seller is linked to this item, but the Contact record is unavailable.',
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('inventoryItemViewSellerButton')),
      findsNothing,
    );
  });
  testWidgets('View Seller opens the linked contact detail screen', (
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
      sellerContactId: 'contact-1',
    );

    const seller = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
      email: 'taylor@example.com',
      address: '100 Main Street',
      notes: 'Inventory seller.',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [seller],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

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
          path: AppRoutes.contactDetail,
          name: AppRouteNames.contactDetail,
          builder: (context, state) {
            return Scaffold(
              body: ContactDetailScreen(
                contactId: state.pathParameters['contactId']!,
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
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final viewSellerButton = find.byKey(
      const Key('inventoryItemViewSellerButton'),
    );

    expect(viewSellerButton, findsOneWidget);

    await tester.ensureVisible(viewSellerButton);
    await tester.pumpAndSettle();

    await tester.tap(viewSellerButton);
    await tester.pumpAndSettle();

    expect(find.text('Contact Details'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);
    expect(find.text('100 Main Street'), findsOneWidget);
    expect(find.text('Inventory seller.'), findsOneWidget);
  });
  testWidgets('sold item without a buyer displays no buyer linked', (
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
      status: InventoryStatus.sold,
    );

    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 20000,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final contactRepository = InMemoryContactRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Information'), findsOneWidget);
    expect(find.text('No buyer linked'), findsOneWidget);

    expect(find.byKey(const Key('inventoryItemViewBuyerButton')), findsNothing);
  });
  testWidgets('sold item displays linked buyer information', (
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
      status: InventoryStatus.sold,
    );

    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      buyerContactId: 'contact-1',
      acquisitionValueCents: 20000,
    );

    const buyer = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
      email: 'taylor@example.com',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [buyer],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Information'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsOneWidget);
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);

    expect(
      find.byKey(const Key('inventoryItemViewBuyerButton')),
      findsOneWidget,
    );
  });
  testWidgets('sold item displays warning for missing linked buyer', (
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
      status: InventoryStatus.sold,
    );

    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      buyerContactId: 'missing-contact',
      acquisitionValueCents: 20000,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final contactRepository = InMemoryContactRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Information'), findsOneWidget);

    expect(
      find.text(
        'A buyer is linked to this sale, but the Contact record is unavailable.',
      ),
      findsOneWidget,
    );

    expect(find.byKey(const Key('inventoryItemViewBuyerButton')), findsNothing);
  });
  testWidgets('View Buyer opens buyer contact details from sold item', (
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
      status: InventoryStatus.sold,
    );

    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      buyerContactId: 'contact-1',
      acquisitionValueCents: 20000,
    );

    const buyer = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
      email: 'taylor@example.com',
      address: '100 Main Street',
      notes: 'Repeat buyer.',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [buyer],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(contactRepository.dispose);

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
          path: AppRoutes.contactDetail,
          name: AppRouteNames.contactDetail,
          builder: (context, state) {
            return Scaffold(
              body: ContactDetailScreen(
                contactId: state.pathParameters['contactId']!,
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
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final viewBuyerButton = find.byKey(
      const Key('inventoryItemViewBuyerButton'),
    );

    expect(viewBuyerButton, findsOneWidget);

    await tester.ensureVisible(viewBuyerButton);
    await tester.pumpAndSettle();

    await tester.tap(viewBuyerButton);
    await tester.pumpAndSettle();

    expect(find.text('Contact Details'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);
    expect(find.text('100 Main Street'), findsOneWidget);
    expect(find.text('Repeat buyer.'), findsOneWidget);
  });
  testWidgets('Add Repair opens repair form for the selected item', (
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

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

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
          path: AppRoutes.addRepair,
          name: AppRouteNames.addRepair,
          builder: (context, state) {
            return Scaffold(
              body: AddRepairScreen(
                inventoryItemId: state.pathParameters['itemId']!,
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

    final addRepairButton = find.byKey(
      const Key('inventoryItemAddRepairButton'),
    );

    expect(addRepairButton, findsOneWidget);

    await tester.ensureVisible(addRepairButton);
    await tester.pumpAndSettle();

    await tester.tap(addRepairButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('addRepairInventoryItemField')),
      findsOneWidget,
    );

    expect(
      find.text('BAT-2608-0001 — Combat Spec H1'),
      findsAtLeastNWidgets(1),
    );

    expect(find.byKey(const Key('addRepairCostField')), findsOneWidget);

    expect(find.byKey(const Key('addRepairDescriptionField')), findsOneWidget);

    expect(find.byKey(const Key('addRepairSubmitButton')), findsOneWidget);
  });
  testWidgets('displays empty repair history and current true cost', (
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

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

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
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Repair History'), findsOneWidget);
    expect(find.text('Number of Repairs'), findsOneWidget);
    expect(find.text('Total Repair Cost'), findsOneWidget);
    expect(find.text('True Cost'), findsOneWidget);

    expect(
      find.text('No repairs have been recorded for this item.'),
      findsOneWidget,
    );

    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsAtLeastNWidgets(2));
  });
  testWidgets('displays repair history newest first with total and true cost', (
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

    final olderRepair = RepairTransaction(
      id: 'repair-1',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 3),
      costCents: 2500,
      description: 'Cleaned and conditioned.',
    );

    final newerRepair = RepairTransaction(
      id: 'repair-2',
      inventoryItemId: 'item-1',
      repairDate: DateTime(2026, 8, 5),
      costCents: 4500,
      description: 'Replaced damaged grip.',
      notes: 'Completed in-house.',
    );

    final unrelatedRepair = RepairTransaction(
      id: 'repair-3',
      inventoryItemId: 'item-2',
      repairDate: DateTime(2026, 8, 6),
      costCents: 3000,
      description: 'Re-laced glove.',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialRepairs: [olderRepair, unrelatedRepair, newerRepair],
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
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Repair History'), findsOneWidget);
    expect(find.text('2'), findsAtLeastNWidgets(1));
    expect(find.text(r'$70.00'), findsOneWidget);
    expect(find.text(r'$270.00'), findsAtLeastNWidgets(1));

    expect(
      find.byKey(const ValueKey('repairHistoryEntry-repair-1')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey('repairHistoryEntry-repair-2')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey('repairHistoryEntry-repair-3')),
      findsNothing,
    );

    expect(find.text('Replaced damaged grip.'), findsOneWidget);

    expect(find.text('Cleaned and conditioned.'), findsOneWidget);

    expect(find.text('Completed in-house.'), findsOneWidget);

    expect(find.text('Re-laced glove.'), findsNothing);

    final newerEntry = find.byKey(
      const ValueKey('repairHistoryEntry-repair-2'),
    );

    final olderEntry = find.byKey(
      const ValueKey('repairHistoryEntry-repair-1'),
    );

    expect(
      tester.getTopLeft(newerEntry).dy,
      lessThan(tester.getTopLeft(olderEntry).dy),
    );
  });
}
