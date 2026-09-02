import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/warranty_replacement_deal.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_providers.dart';

void main() {
  testWidgets(
    'warranty replacement descendant shows Warranty and recursive Deal sections',
    (tester) async {
      const originalTradeItem = InventoryItem(
        id: 'trade-item',
        inventoryNumber: 'BAT-2609-0001',
        category: InventoryCategory.bat,
        brand: 'Easton',
        model: 'Hype Fire',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 20000,
        status: InventoryStatus.disposed,
      );

      const replacementItem = InventoryItem(
        id: 'replacement-item',
        inventoryNumber: 'BAT-2609-0002',
        category: InventoryCategory.bat,
        brand: 'Marucci',
        model: 'CatX2',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 20000,
        condition: InventoryCondition.newItem,
        status: InventoryStatus.available,
      );

      const recursiveDeal = Deal(
        id: 'deal-root',
        parentSaleTransactionId: 'sale-root',
        childInventoryItemIds: ['trade-item'],
        lineageInventoryItemIds: ['trade-item', 'replacement-item'],
      );

      final warrantyDeal = WarrantyReplacementDeal(
        id: 'warranty-a',
        disposalTransactionId: 'disposal-a',
        disposedInventoryItemId: 'trade-item',
        replacementInventoryItemId: 'replacement-item',
        replacementDate: DateTime(2026, 9, 1),
        notes: 'Manufacturer replacement.',
      );

      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: const [originalTradeItem, replacementItem],
      );
      final transactionRepository = InMemoryTransactionRepository();
      final dealRepository = InMemoryDealRepository(
        initialDeals: const [recursiveDeal],
      );
      final warrantyRepository = InMemoryWarrantyReplacementDealRepository(
        initialDeals: [warrantyDeal],
      );

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(dealRepository.dispose);
      addTearDown(warrantyRepository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
            dealRepositoryProvider.overrideWithValue(dealRepository),
            warrantyReplacementDealRepositoryProvider.overrideWithValue(
              warrantyRepository,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InventoryItemDetailScreen(itemId: 'replacement-item'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inventoryWarrantySection')), findsOneWidget);
      expect(
        find.text('This item was received as a warranty replacement.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventoryDealSection')), findsOneWidget);
      expect(
        find.text('This inventory item is part of a continuing Deal lineage.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventoryTradeHistoryEmpty')),
        findsOneWidget,
      );
    },
  );

  testWidgets('ordinary item hides Warranty and Deal sections', (tester) async {
    const item = InventoryItem(
      id: 'ordinary-item',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.available,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository();
    final dealRepository = InMemoryDealRepository();
    final warrantyRepository = InMemoryWarrantyReplacementDealRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);
    addTearDown(warrantyRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          dealRepositoryProvider.overrideWithValue(dealRepository),
          warrantyReplacementDealRepositoryProvider.overrideWithValue(
            warrantyRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: InventoryItemDetailScreen(itemId: 'ordinary-item'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventoryWarrantySection')), findsNothing);
    expect(find.byKey(const Key('inventoryDealSection')), findsNothing);
  });
}
