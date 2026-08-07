import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/add_repair_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  testWidgets('displays the selected inventory item', (
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
          home: Scaffold(body: AddRepairScreen(inventoryItemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add Repair'), findsAtLeastNWidgets(1));
    expect(
      find.text('BAT-2608-0001 — Combat Spec H1'),
      findsAtLeastNWidgets(1),
    );

    expect(
      find.byKey(const Key('addRepairInventoryItemField')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('addRepairDateField')), findsOneWidget);

    expect(find.byKey(const Key('addRepairCostField')), findsOneWidget);

    expect(find.byKey(const Key('addRepairDescriptionField')), findsOneWidget);

    expect(find.byKey(const Key('addRepairNotesField')), findsOneWidget);

    expect(find.byKey(const Key('addRepairSubmitButton')), findsOneWidget);
  });

  testWidgets('validates required repair fields', (WidgetTester tester) async {
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
          home: Scaffold(body: AddRepairScreen(inventoryItemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('addRepairSubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Repair cost is required.'), findsOneWidget);

    expect(find.text('Repair description is required.'), findsOneWidget);

    expect(await transactionRepository.getRepairs(), isEmpty);
  });

  testWidgets('saves a valid repair transaction', (WidgetTester tester) async {
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

    final transactionRepository = InMemoryTransactionRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    var onSavedCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddRepairScreen(
              inventoryItemId: 'item-1',
              onSaved: () {
                onSavedCalled = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('addRepairCostField')),
      '45.00',
    );

    await tester.enterText(
      find.byKey(const Key('addRepairDescriptionField')),
      'Replaced damaged grip.',
    );

    await tester.enterText(
      find.byKey(const Key('addRepairNotesField')),
      'Completed in-house.',
    );

    final submitButton = find.byKey(const Key('addRepairSubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repairs = await transactionRepository.getRepairs();

    expect(repairs, hasLength(1));

    final repair = repairs.single;

    expect(repair.id, isNotNull);
    expect(repair.inventoryItemId, 'item-1');
    expect(repair.costCents, 4500);
    expect(repair.description, 'Replaced damaged grip.');
    expect(repair.notes, 'Completed in-house.');

    expect(find.text('Repair was added successfully.'), findsOneWidget);

    expect(onSavedCalled, isTrue);
  });

  testWidgets('allows a zero-cost repair', (WidgetTester tester) async {
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
          home: Scaffold(body: AddRepairScreen(inventoryItemId: 'item-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('addRepairCostField')), '0');

    await tester.enterText(
      find.byKey(const Key('addRepairDescriptionField')),
      'Warranty repair.',
    );
    await tester.pumpAndSettle();
    final submitButton = find.byKey(const Key('addRepairSubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repairs = await transactionRepository.getRepairs();

    expect(repairs, hasLength(1));
    expect(repairs.single.costCents, 0);
    expect(repairs.single.description, 'Warranty repair.');
  });

  testWidgets('displays not-found state for unknown item', (
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
          home: Scaffold(
            body: AddRepairScreen(inventoryItemId: 'missing-item'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory item not found.'), findsOneWidget);

    expect(
      find.text(
        'A repair cannot be added because the inventory item is unavailable.',
      ),
      findsOneWidget,
    );

    expect(find.byKey(const Key('addRepairSubmitButton')), findsNothing);
  });
}
