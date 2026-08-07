import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/deal_detail_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  testWidgets('Deal detail displays summary and child inventory', (
    tester,
  ) async {
    final parentSale = SaleTransaction(
      id: 'sale-a',
      inventoryItemId: 'bat-a',
      salePriceCents: 20000,
      tradeInCreditCents: 10000,
      saleDate: DateTime(2026, 8, 6),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 15000,
    );

    const child = InventoryItem(
      id: 'bat-b',
      inventoryNumber: 'BAT-2608-0002',
      category: InventoryCategory.bat,
      brand: 'Bat B',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 10000,
      askingPriceCents: 20000,
      status: InventoryStatus.available,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [child],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [parentSale],
    );
    final dealRepository = InMemoryDealRepository(
      initialDeals: const [
        Deal(
          id: 'deal-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: ['bat-b'],
        ),
      ],
    );

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
          dealRepositoryProvider.overrideWithValue(dealRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DealDetailScreen(dealId: 'deal-a')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Open'), findsAtLeastNWidgets(1));
    expect(find.text(r'$50.00'), findsNWidgets(2));
    expect(find.text(r'$100.00'), findsNWidgets(2));
    expect(find.text(r'$150.00'), findsOneWidget);
    expect(find.text('BAT-2608-0002 â€” Bat B'), findsOneWidget);
  });
}
