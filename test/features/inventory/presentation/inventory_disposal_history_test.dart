import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  const disposedItem = InventoryItem(
    id: 'item-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    model: 'Spec H1',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 15000,
    status: InventoryStatus.disposed,
  );

  testWidgets('inventory detail displays Disposal History', (tester) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [disposedItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialDisposals: [
        DisposalTransaction(
          id: 'disposal-a',
          inventoryItemId: 'item-a',
          disposalDate: DateTime(2026, 8, 7),
          reason: DisposalReason.warrantyReplacement,
          notes: 'Manufacturer approved replacement.',
        ),
      ],
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
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'item-a')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Disposal History'), findsOneWidget);
    expect(find.text('Warranty Replacement'), findsOneWidget);
    expect(find.text('Manufacturer approved replacement.'), findsOneWidget);
    expect(
      find.text('Warranty replacement: replacement Deal follow-up required.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventoryItemDisposeButton')), findsNothing);
  });
}
