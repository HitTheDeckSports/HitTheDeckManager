import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/record_consignment_screen.dart';

void main() {
  testWidgets('records commission agreement for consigned inventory', (
    tester,
  ) async {
    const item = InventoryItem(
      id: 'item-a',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.consignment,
      acquisitionValueCents: 0,
      sellerContactId: 'contact-a',
      status: InventoryStatus.available,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository();

    final router = GoRouter(
      initialLocation: '/inventory/item-a/consignment/new',
      routes: [
        GoRoute(
          path: AppRoutes.recordConsignment,
          name: AppRouteNames.recordConsignment,
          builder: (context, state) => const Scaffold(
            body: RecordConsignmentScreen(inventoryItemId: 'item-a'),
          ),
        ),
        GoRoute(
          path: AppRoutes.inventoryDetail,
          name: AppRouteNames.inventoryDetail,
          builder: (context, state) =>
              const Scaffold(body: Text('Inventory detail reached')),
        ),
      ],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('consignmentCommissionField')),
      '50.00',
    );

    final saveButton = find.byKey(const Key('saveConsignmentAgreementButton'));

    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final saved = await transactionRepository.getConsignmentForInventoryItem(
      'item-a',
    );

    expect(saved, isNotNull);
    expect(saved?.commissionCents, 5000);
    expect(saved?.consignorContactId, 'contact-a');
    expect(find.text('Inventory detail reached'), findsOneWidget);
  });
}
