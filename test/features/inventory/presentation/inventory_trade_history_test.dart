import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_item_detail_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  const soldItem = InventoryItem(
    id: 'sold-item',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    model: 'Spec H1',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 20000,
    status: InventoryStatus.sold,
  );

  const tradeInItem = InventoryItem(
    id: 'trade-in-item',
    inventoryNumber: 'GLV-2608-0001',
    category: InventoryCategory.glove,
    brand: 'Wilson',
    model: 'A2000',
    acquisitionType: AcquisitionType.traded,
    acquisitionValueCents: 14000,
    status: InventoryStatus.available,
  );

  final sale = SaleTransaction(
    id: 'sale-1',
    inventoryItemId: 'sold-item',
    salePriceCents: 32500,
    tradeInCreditCents: 14000,
    saleDate: DateTime(2026, 8, 3),
    paymentMethod: PaymentMethod.venmo,
    acquisitionValueCents: 20000,
  );

  final trade = TradeTransaction(
    id: 'trade-1',
    saleTransactionId: 'sale-1',
    outgoingInventoryItemIds: const ['sold-item'],
    incomingInventoryItemIds: const ['trade-in-item'],
    tradeDate: DateTime(2026, 8, 3),
  );

  testWidgets('sold item displays trade-in inventory received', (tester) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem, tradeInItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
      initialTrades: [trade],
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
          home: Scaffold(body: InventoryItemDetailScreen(itemId: 'sold-item')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Trade History'), findsOneWidget);
    expect(find.text('Sold item in a trade-in sale'), findsOneWidget);
    expect(find.text('GLV-2608-0001 â€” Wilson A2000'), findsOneWidget);
    expect(find.text(r'$140.00'), findsOneWidget);
    expect(find.text('View Original Sale'), findsOneWidget);
  });

  testWidgets('incoming trade-in displays the original sold item', (
    tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem, tradeInItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
      initialTrades: [trade],
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
          home: Scaffold(
            body: InventoryItemDetailScreen(itemId: 'trade-in-item'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Trade History'), findsOneWidget);
    expect(find.text('Inventory received as a trade-in'), findsOneWidget);
    expect(find.text('BAT-2608-0001 â€” Combat Spec H1'), findsOneWidget);
    expect(find.text('View Original Sale'), findsOneWidget);
  });
}
