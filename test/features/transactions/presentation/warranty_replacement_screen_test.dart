import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/warranty_replacement_screen.dart';

void main() {
  testWidgets('shows carried-forward cost basis for warranty replacement', (
    tester,
  ) async {
    const disposedItem = InventoryItem(
      id: 'old-item',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.disposed,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [disposedItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialDisposals: [
        DisposalTransaction(
          id: 'disposal-a',
          inventoryItemId: 'old-item',
          disposalDate: DateTime(2026, 8, 7),
          reason: DisposalReason.warrantyReplacement,
        ),
      ],
    );
    final dealRepository = InMemoryWarrantyReplacementDealRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          warrantyReplacementDealRepositoryProvider.overrideWithValue(
            dealRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WarrantyReplacementScreen(disposalId: 'disposal-a'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Warranty Replacement'), findsOneWidget);
    expect(find.textContaining(r'$150.00'), findsOneWidget);
    expect(
      find.byKey(const Key('createWarrantyReplacementDealButton')),
      findsOneWidget,
    );
  });
}
