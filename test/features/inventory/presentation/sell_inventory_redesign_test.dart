import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/sell_inventory_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  testWidgets('Sell Inventory redesign shows approved section hierarchy', (
    tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 32500,
      minimumPriceCents: 25000,
      status: InventoryStatus.available,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final contactRepository = InMemoryContactRepository();
    final transactionRepository = InMemoryTransactionRepository();
    final dealRepository = InMemoryDealRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAppPermissionsProvider.overrideWithValue(
            const AppPermissions.ownerOrAdmin(),
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          dealRepositoryProvider.overrideWithValue(dealRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SellInventoryScreen(initialItem: item)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Details'), findsOneWidget);
    expect(find.text('Payment Method'), findsAtLeastNWidgets(1));
    expect(find.text('Customer'), findsAtLeastNWidgets(1));
    expect(find.text('Trade-In Items (Optional)'), findsOneWidget);
    expect(find.text('Notes (Optional)'), findsOneWidget);
    expect(find.text('Live Sale Summary'), findsOneWidget);
    expect(
      find.byKey(const Key('sellInventorySelectedItemSummary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sellInventoryMinimumPriceFeedback')),
      findsOneWidget,
    );
    expect(find.text('Complete Sale'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
