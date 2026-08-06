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
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/edit_repair_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/repair_detail_screen.dart';

void main() {
  testWidgets('prefills the existing repair values', (
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
      costCents: 4575,
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
          home: Scaffold(body: EditRepairScreen(repairId: 'repair-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Edit Repair'), findsAtLeastNWidgets(1));
    expect(
      find.text('BAT-2608-0001 — Combat Spec H1'),
      findsAtLeastNWidgets(1),
    );

    final dateField = tester.widget<TextFormField>(
      find.byKey(const Key('editRepairDateField')),
    );

    final costField = tester.widget<TextFormField>(
      find.byKey(const Key('editRepairCostField')),
    );

    final descriptionField = tester.widget<TextFormField>(
      find.byKey(const Key('editRepairDescriptionField')),
    );

    final notesField = tester.widget<TextFormField>(
      find.byKey(const Key('editRepairNotesField')),
    );

    expect(dateField.controller?.text, '08/05/2026');
    expect(costField.controller?.text, '45.75');
    expect(descriptionField.controller?.text, 'Replaced damaged grip.');
    expect(notesField.controller?.text, 'Completed in-house.');

    expect(find.byKey(const Key('editRepairSubmitButton')), findsOneWidget);
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
          home: Scaffold(body: EditRepairScreen(repairId: 'missing-repair')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Repair not found.'), findsOneWidget);
    expect(
      find.text('The repair may have been removed or is no longer available.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('editRepairSubmitButton')), findsNothing);
  });

  testWidgets('displays unavailable state for missing linked item', (
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
          home: Scaffold(body: EditRepairScreen(repairId: 'repair-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory item not found.'), findsOneWidget);
    expect(
      find.text(
        'The repair cannot be edited because its linked inventory item is unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('editRepairSubmitButton')), findsNothing);
  });

  testWidgets('validates required cost and description', (
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EditRepairScreen(repairId: 'repair-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editRepairCostField')), '');

    await tester.enterText(
      find.byKey(const Key('editRepairDescriptionField')),
      '',
    );

    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('editRepairSubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Repair cost is required.'), findsOneWidget);
    expect(find.text('Repair description is required.'), findsOneWidget);

    expect(await transactionRepository.getRepair('repair-1'), repair);
  });

  testWidgets('updates repair and returns to repair details', (
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
      notes: 'Original notes.',
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
      initialLocation: '/repairs/repair-1/edit',
      routes: [
        GoRoute(
          path: AppRoutes.editRepair,
          name: AppRouteNames.editRepair,
          builder: (context, state) {
            return Scaffold(
              body: EditRepairScreen(
                repairId: state.pathParameters['repairId']!,
              ),
            );
          },
        ),
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

    await tester.enterText(
      find.byKey(const Key('editRepairCostField')),
      '55.00',
    );

    await tester.enterText(
      find.byKey(const Key('editRepairDescriptionField')),
      'Replaced grip and cleaned barrel.',
    );

    await tester.enterText(
      find.byKey(const Key('editRepairNotesField')),
      'Updated notes.',
    );

    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('editRepairSubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final savedRepair = await transactionRepository.getRepair('repair-1');

    expect(savedRepair, isNotNull);
    expect(savedRepair?.inventoryItemId, 'item-1');
    expect(savedRepair?.costCents, 5500);
    expect(savedRepair?.description, 'Replaced grip and cleaned barrel.');
    expect(savedRepair?.notes, 'Updated notes.');
    expect(find.text('Repair Details'), findsOneWidget);
    expect(find.text(r'$55.00'), findsOneWidget);
    expect(find.text('Replaced grip and cleaned barrel.'), findsOneWidget);
    expect(find.text('Updated notes.'), findsOneWidget);
  });
}
