import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/dispose_inventory_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  const item = InventoryItem(
    id: 'item-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    model: 'Spec H1',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 15000,
    status: InventoryStatus.available,
  );

  testWidgets('disposal form records reason and changes status', (
    tester,
  ) async {
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
          home: Scaffold(
            body: DisposeInventoryScreen(inventoryItemId: 'item-a'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('disposeInventoryReasonField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Damaged Beyond Repair').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('disposeInventoryNotesField')),
      'Cracked barrel.',
    );
    await tester.tap(find.byKey(const Key('disposeInventorySaveButton')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Disposal'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmDisposalButton')));
    await tester.pumpAndSettle();

    final updated = await inventoryRepository.getInventoryItem('item-a');
    final disposals = await transactionRepository.getDisposals();
    expect(updated?.status, InventoryStatus.disposed);
    expect(disposals, hasLength(1));
    expect(disposals.single.reason, DisposalReason.damagedBeyondRepair);
    expect(disposals.single.notes, 'Cracked barrel.');
  });

  testWidgets('warranty replacement displays Deal follow-up notice', (
    tester,
  ) async {
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
          home: Scaffold(
            body: DisposeInventoryScreen(inventoryItemId: 'item-a'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('disposeInventoryReasonField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warranty Replacement').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warrantyReplacementNotice')), findsOneWidget);
  });
}
