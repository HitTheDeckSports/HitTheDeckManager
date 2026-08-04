import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/sell_inventory_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  late InMemoryInventoryRepository inventoryRepository;
  late ProviderContainer container;

  const availableItem = InventoryItem(
    id: 'item-1',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    model: 'Spec H1',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 20000,
    askingPriceCents: 32500,
    status: InventoryStatus.available,
  );

  setUp(() {
    inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [availableItem],
    );

    container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await inventoryRepository.dispose();
  });

  Widget createTestApp() {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: SellInventoryScreen())),
    );
  }

  testWidgets('displays the initial Sell Inventory fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Sell Inventory'), findsOneWidget);
    expect(find.text('Sale Information'), findsOneWidget);
    expect(find.text('Inventory Item'), findsOneWidget);
    expect(find.text('Sale Price'), findsNWidgets(2));
    expect(find.text('Sale Date'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Live Sale Summary'), findsOneWidget);
    expect(find.text('Complete Sale'), findsOneWidget);

    expect(find.byKey(const Key('sellInventoryItemField')), findsOneWidget);
    expect(
      find.byKey(const Key('sellInventorySalePriceField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sellInventorySaleDateButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sellInventoryPaymentMethodField')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sellInventoryNotesField')), findsOneWidget);
    expect(find.byKey(const Key('sellInventorySubmitButton')), findsOneWidget);
  });

  testWidgets('only available inventory appears in the selector', (
    WidgetTester tester,
  ) async {
    const inactiveItem = InventoryItem(
      id: 'item-2',
      inventoryNumber: 'GLV-2608-0001',
      category: InventoryCategory.glove,
      brand: 'Wilson',
      model: 'A2000',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.inactive,
    );

    const brokenItem = InventoryItem(
      id: 'item-3',
      inventoryNumber: 'BAT-2608-0002',
      category: InventoryCategory.bat,
      brand: 'Easton',
      model: 'Hype Fire',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 17500,
      status: InventoryStatus.broken,
    );

    const soldItem = InventoryItem(
      id: 'item-4',
      inventoryNumber: 'HLM-2608-0001',
      category: InventoryCategory.helmet,
      brand: 'Rawlings',
      model: 'Mach',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 5000,
      status: InventoryStatus.sold,
    );

    await inventoryRepository.dispose();

    inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [availableItem, inactiveItem, brokenItem, soldItem],
    );

    container.dispose();

    container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
      ],
    );

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final itemField = find.byKey(const Key('sellInventoryItemField'));

    await tester.tap(itemField);
    await tester.pumpAndSettle();

    expect(find.text('BAT-2608-0001 — Combat Spec H1'), findsOneWidget);

    expect(find.text('GLV-2608-0001 — Wilson A2000'), findsNothing);

    expect(find.text('BAT-2608-0002 — Easton Hype Fire'), findsNothing);

    expect(find.text('HLM-2608-0001 — Rawlings Mach'), findsNothing);
  });
  testWidgets('selecting an item preloads price and updates live summary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final itemField = find.byKey(const Key('sellInventoryItemField'));

    await tester.tap(itemField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('BAT-2608-0001 — Combat Spec H1').last);

    await tester.pumpAndSettle();

    final salePriceField = tester.widget<TextFormField>(
      find.byKey(const Key('sellInventorySalePriceField')),
    );

    expect(salePriceField.initialValue, '325.00');

    expect(find.text(r'$325.00'), findsOneWidget);

    expect(find.textContaining(r'Asking Price: $325.00'), findsOneWidget);
    expect(find.text(r'$200.00'), findsAtLeastNWidgets(1));
    expect(find.text(r'$125.00'), findsOneWidget);
    expect(find.text('38.5%'), findsOneWidget);
  });
  testWidgets('buyer dropdown displays saved contacts', (
    WidgetTester tester,
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
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository();

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'contact-2', name: 'Jordan Smith'),
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
        child: const MaterialApp(home: Scaffold(body: SellInventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final buyerField = find.byKey(const Key('sellInventoryBuyerField'));

    expect(buyerField, findsOneWidget);

    await tester.ensureVisible(buyerField);
    await tester.tap(buyerField);
    await tester.pumpAndSettle();

    expect(find.text('No Buyer Selected'), findsAtLeastNWidgets(1));
    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('Jordan Smith'), findsOneWidget);
  });
  testWidgets('completed sale stores selected buyer contact ID', (
    WidgetTester tester,
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
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository();

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [Contact(id: 'contact-1', name: 'Taylor Morgan')],
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
        child: const MaterialApp(home: Scaffold(body: SellInventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sellInventoryItemField')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BAT-2608-0001 — Combat Spec H1').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sellInventorySalePriceField')),
      '325.00',
    );

    await tester.pumpAndSettle();

    final buyerField = find.byKey(const Key('sellInventoryBuyerField'));

    await tester.ensureVisible(buyerField);
    await tester.tap(buyerField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Taylor Morgan'));
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('sellInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final sales = await transactionRepository.getSales();

    expect(sales, hasLength(1));
    expect(sales.single.inventoryItemId, 'item-1');
    expect(sales.single.buyerContactId, 'contact-1');

    final soldItem = await inventoryRepository.getInventoryItem('item-1');

    expect(soldItem?.status, InventoryStatus.sold);
  });
  testWidgets('sale can be completed without selecting a buyer', (
    WidgetTester tester,
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
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final transactionRepository = InMemoryTransactionRepository();
    final contactRepository = InMemoryContactRepository();

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
        child: const MaterialApp(home: Scaffold(body: SellInventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sellInventoryItemField')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BAT-2608-0001 — Combat Spec H1').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sellInventorySalePriceField')),
      '325.00',
    );

    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('sellInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final sales = await transactionRepository.getSales();

    expect(sales, hasLength(1));
    expect(sales.single.buyerContactId, isNull);
  });
}
