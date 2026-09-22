import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/deal_detail_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_providers.dart';

void main() {
  testWidgets('Deal detail uses final three-tab Deal layout', (tester) async {
    final parentSale = SaleTransaction(
      id: 'sale-a',
      inventoryItemId: 'bat-a',
      salePriceCents: 20000,
      tradeInCreditCents: 10000,
      saleDate: DateTime(2026, 9, 1),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 15000,
    );

    const root = InventoryItem(
      id: 'bat-a',
      inventoryNumber: 'BAT-2609-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.sold,
    );

    const child = InventoryItem(
      id: 'bat-b',
      inventoryNumber: 'BAT-2609-0002',
      category: InventoryCategory.bat,
      brand: 'Louisville Slugger',
      model: 'Atlas',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 10000,
      askingPriceCents: 20000,
      status: InventoryStatus.available,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [root, child],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale],
    );
    final dealRepository = InMemoryDealRepository(
      initialDeals: [
        Deal(
          id: 'deal-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: const ['bat-b'],
          lineageInventoryItemIds: const ['bat-b'],
          createdAt: DateTime(2026, 9, 1),
        ),
      ],
    );
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
          home: Scaffold(body: DealDetailScreen(dealId: 'deal-a')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Deal #2026-001'), findsOneWidget);
    expect(find.text('Deal Tree'), findsNWidgets(2));
    expect(find.text('Financials'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('CURRENT PROFIT'), findsOneWidget);
    expect(find.text('PROJECTED PROFIT'), findsAtLeastNWidgets(1));
    expect(find.text('Branch 1'), findsOneWidget);
    expect(find.text('Louisville Slugger Atlas'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key('dealTab-1')));
    await tester.pumpAndSettle();

    expect(find.text('Deal Financials'), findsOneWidget);
    expect(find.text('Total Cash Received'), findsOneWidget);
    expect(find.text('Total Repair Costs'), findsOneWidget);
    expect(find.text('Branch Profitability'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dealTab-2')));
    await tester.pumpAndSettle();

    expect(find.text('Deal Transactions'), findsOneWidget);
    expect(find.text('Combat Spec H1 Sold'), findsOneWidget);
    expect(
      find.text('Louisville Slugger Atlas Received in Trade'),
      findsOneWidget,
    );
    expect(find.textContaining('View All'), findsNothing);
  });
}
