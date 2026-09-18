import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/contact_detail_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/transaction_detail_screen.dart';

void main() {
  testWidgets('uses approved Sale Transaction detail hierarchy', (
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
      condition: InventoryCondition.likeNew,
      lengthInches: 32,
      weightOunces: 29,
      certification: 'BBCOR',
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

    expect(find.byKey(const Key('saleTransactionItemHero')), findsOneWidget);
    expect(
      find.byKey(const Key('saleTransactionDetailsSection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('saleFinancialSummarySection')),
      findsOneWidget,
    );

    expect(find.text('Sale Transaction'), findsNothing);
    expect(find.text('Transaction Summary'), findsNothing);
    expect(find.text('Transaction Details'), findsOneWidget);
    expect(find.text('Financial Summary'), findsOneWidget);

    expect(find.text('BAT-2608-0001'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const Key('transactionDetailInventoryLink')),
      findsOneWidget,
    );
    expect(find.text('Combat Spec H1'), findsOneWidget);
    expect(find.text('32"  •  29 oz  •  BBCOR'), findsOneWidget);
    expect(find.text('Like New'), findsOneWidget);
    expect(find.text('Sold'), findsOneWidget);

    expect(find.text(r'$325.00'), findsNWidgets(2));
    expect(find.text(r'$200.00'), findsOneWidget);
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(find.text('38.5%'), findsOneWidget);

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Sold during tournament.'), findsOneWidget);
  });

  testWidgets('linked buyer is condensed to name only', (
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

    expect(find.text('Buyer'), findsOneWidget);
    expect(find.text('Buyer Information'), findsNothing);
    expect(find.text('Taylor Morgan'), findsOneWidget);
    expect(find.text('555-123-4567'), findsNothing);
    expect(find.text('taylor@example.com'), findsNothing);
    expect(find.text('Tap to view contact'), findsNothing);
    expect(
      find.byKey(const Key('transactionDetailViewBuyerButton')),
      findsOneWidget,
    );
  });

  testWidgets('View Buyer opens linked contact detail', (
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
          builder: (context, state) => Scaffold(
            body: TransactionDetailScreen(
              transactionId: state.pathParameters['transactionId']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.contactDetail,
          name: AppRouteNames.contactDetail,
          builder: (context, state) => Scaffold(
            body: ContactDetailScreen(
              contactId: state.pathParameters['contactId']!,
            ),
          ),
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

    final buyerLink = find.byKey(const Key('transactionDetailViewBuyerButton'));
    expect(buyerLink, findsOneWidget);

    await tester.ensureVisible(buyerLink);
    await tester.tap(buyerLink);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contactIdentityCard')), findsOneWidget);
    expect(find.text('Taylor Morgan'), findsAtLeastNWidgets(1));
  });

  testWidgets('unknown transaction keeps not-found state', (
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

    expect(find.text('Transaction not found.'), findsOneWidget);
  });
}
