import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  testWidgets('inventory detail displays consignment commission', (
    tester,
  ) async {
    const item = InventoryItem(
      id: 'item-a',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.consignment,
      acquisitionValueCents: 0,
      status: InventoryStatus.available,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialConsignments: [
        ConsignmentTransaction(
          id: 'consignment-a',
          inventoryItemId: 'item-a',
          consignmentDate: DateTime(2026, 8, 7),
          commissionCents: 5000,
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

    expect(find.text('Hit the Deck Commission'), findsOneWidget);
    expect(find.text(r'$50.00'), findsOneWidget);
    expect(find.text('Awaiting Sale'), findsOneWidget);
  });
}
