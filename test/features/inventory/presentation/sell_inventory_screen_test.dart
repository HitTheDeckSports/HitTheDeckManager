import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/sell_inventory_screen.dart';

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
}
