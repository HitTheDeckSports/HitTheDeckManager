import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/create_trade_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  testWidgets('displays outgoing inventory and incoming item controls',
      (tester) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository();
    final contactRepository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'contact-1', name: 'Alex Johnson'),
      ],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CreateTradeScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Create Trade'), findsAtLeastNWidgets(1));
    expect(find.text('BAT-2608-0001 — Combat Spec H1'), findsOneWidget);
    expect(find.byKey(const Key('tradeContactField')), findsOneWidget);
    expect(
      find.byKey(const Key('addIncomingTradeItemButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('createTradeSubmitButton')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('addIncomingTradeItemButton')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('incomingTradeBrand-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('incomingTradeValue-0')), findsOneWidget);
  });
}
