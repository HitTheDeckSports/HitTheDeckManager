import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  testWidgets('displays a sale transaction and related inventory item', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      notes: 'Sold during tournament.',
      acquisitionValueCents: 20000,
    );

    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Transaction'), findsOneWidget);
    expect(find.text('Transaction Summary'), findsOneWidget);
    expect(find.text('Financial Summary'), findsOneWidget);

    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('08/03/2026'), findsAtLeastNWidgets(1));
    expect(find.text('Cash'), findsOneWidget);

    expect(find.text('BAT-2608-0001 — Combat Spec H1'), findsOneWidget);

    expect(find.text(r'$325.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsOneWidget);
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(find.text('38.5%'), findsOneWidget);

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Sold during tournament.'), findsOneWidget);
  });

  testWidgets('displays not-found state for an unknown transaction', (
    WidgetTester tester,
  ) async {
    final transactionRepository = InMemoryTransactionRepository();

    final inventoryRepository = InMemoryInventoryRepository();

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'missing-sale'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Transaction Details'), findsOneWidget);
    expect(find.text('Transaction not found.'), findsOneWidget);

    expect(
      find.text(
        'The transaction may have been removed or is no longer available.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('handles a missing related inventory item', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'missing-item',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.card,
      acquisitionValueCents: 20000,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository();

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory record unavailable'), findsOneWidget);

    expect(find.text('missing-item'), findsNothing);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text(r'$325.00'), findsOneWidget);
  });
  testWidgets('transaction without a buyer displays no buyer linked', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 20000,
    );

    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository();

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Buyer Information'), findsOneWidget);
    expect(find.text('No buyer linked'), findsOneWidget);

    expect(
      find.byKey(const Key('transactionDetailViewBuyerButton')),
      findsNothing,
    );
  });
  testWidgets('linked buyer information is displayed', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      buyerContactId: 'contact-1',
      acquisitionValueCents: 20000,
    );

    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    const buyer = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
      email: 'taylor@example.com',
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [buyer],
    );

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Buyer Information'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsOneWidget);
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);

    expect(
      find.byKey(const Key('transactionDetailViewBuyerButton')),
      findsOneWidget,
    );
  });
  testWidgets('missing linked buyer displays warning', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      buyerContactId: 'missing-contact',
      acquisitionValueCents: 20000,
    );

    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository();

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'sale-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Buyer Information'), findsOneWidget);

    expect(
      find.text(
        'A buyer is linked to this sale, but the Contact record is unavailable.',
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('transactionDetailViewBuyerButton')),
      findsNothing,
    );
  });
  testWidgets('View Buyer opens the linked contact detail screen', (
    WidgetTester tester,
  ) async {
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 32500,
      saleDate: DateTime(2026, 8, 3),
      paymentMethod: PaymentMethod.cash,
      buyerContactId: 'contact-1',
      acquisitionValueCents: 20000,
    );

    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.sold,
    );

    const buyer = Contact(
      id: 'contact-1',
      name: 'Taylor Morgan',
      phone: '555-123-4567',
      email: 'taylor@example.com',
      address: '100 Main Street',
      notes: 'Repeat buyer.',
    );

    final transactionRepository = InMemoryTransactionRepository(
      initialSales: [sale],
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [buyer],
    );

    addTearDown(transactionRepository.dispose);
    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    final router = GoRouter(
      initialLocation: '/transactions/sale-1',
      routes: [
        GoRoute(
          path: AppRoutes.transactionDetail,
          name: AppRouteNames.transactionDetail,
          builder: (context, state) {
            return Scaffold(
              body: TransactionDetailScreen(
                transactionId: state.pathParameters['transactionId']!,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.contactDetail,
          name: AppRouteNames.contactDetail,
          builder: (context, state) {
            return Scaffold(
              body: ContactDetailScreen(
                contactId: state.pathParameters['contactId']!,
              ),
            );
          },
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final viewBuyerButton = find.byKey(
      const Key('transactionDetailViewBuyerButton'),
    );

    expect(viewBuyerButton, findsOneWidget);

    await tester.ensureVisible(viewBuyerButton);
    await tester.pumpAndSettle();

    await tester.tap(viewBuyerButton);
    await tester.pumpAndSettle();

    expect(find.text('Contact Details'), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
    expect(find.text('555-123-4567'), findsOneWidget);
    expect(find.text('taylor@example.com'), findsOneWidget);
    expect(find.text('100 Main Street'), findsOneWidget);
    expect(find.text('Repeat buyer.'), findsOneWidget);
  });
}
