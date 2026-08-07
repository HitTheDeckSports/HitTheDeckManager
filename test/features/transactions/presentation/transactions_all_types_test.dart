import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transactions_screen.dart';

void main() {
  const item = InventoryItem(
    id: 'item-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    acquisitionType: AcquisitionType.consignment,
    acquisitionValueCents: 0,
    status: InventoryStatus.available,
  );

  testWidgets('transaction history remains populated when there are no sales', (
    tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialRepairs: [
        RepairTransaction(
          id: 'repair-a',
          inventoryItemId: 'item-a',
          repairDate: DateTime(2026, 8, 7),
          costCents: 2500,
          description: 'Grip replacement',
        ),
      ],
      initialTrades: [
        TradeTransaction(
          id: 'trade-a',
          outgoingInventoryItemIds: const [],
          incomingInventoryItemIds: const ['item-a'],
          tradeDate: DateTime(2026, 8, 6),
        ),
      ],
      initialDisposals: [
        DisposalTransaction(
          id: 'disposal-a',
          inventoryItemId: 'item-a',
          disposalDate: DateTime(2026, 8, 5),
          reason: DisposalReason.other,
        ),
      ],
      initialConsignments: [
        ConsignmentTransaction(
          id: 'consignment-a',
          inventoryItemId: 'item-a',
          consignmentDate: DateTime(2026, 8, 4),
          commissionCents: 5000,
        ),
      ],
    );
    final dealRepository = InMemoryDealRepository();

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
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No transactions yet.'), findsNothing);
    expect(find.text('Sales (0)'), findsOneWidget);
    expect(find.text('Trade-Ins (1)'), findsOneWidget);
    expect(find.text('Repairs (1)'), findsOneWidget);
    expect(find.text('Disposals (1)'), findsOneWidget);
    expect(find.text('Consignments (1)'), findsOneWidget);
    expect(find.text('Grip replacement'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text(r'$50.00'), findsWidgets);
  });

  testWidgets('empty transaction history requires every category to be empty', (
    tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository();
    final transactionRepository = InMemoryTransactionRepository();
    final dealRepository = InMemoryDealRepository();

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
        child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No transactions yet.'), findsOneWidget);
  });
}
