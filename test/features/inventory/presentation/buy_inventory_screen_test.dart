import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_controller.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/buy_inventory_screen.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  late InMemoryInventoryRepository inventoryRepository;
  late InMemoryContactRepository contactRepository;
  late ProviderContainer container;

  setUp(() {
    inventoryRepository = InMemoryInventoryRepository();
    contactRepository = InMemoryContactRepository();

    container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        contactRepositoryProvider.overrideWithValue(contactRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await inventoryRepository.dispose();
    await contactRepository.dispose();
  });

  Widget createTestApp() {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: BuyInventoryScreen())),
    );
  }

  testWidgets('displays the initial Buy Inventory fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Buy Inventory'), findsOneWidget);
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Acquisition Type'), findsOneWidget);
    expect(find.text('Acquisition Value'), findsOneWidget);
    expect(find.text('Condition'), findsOneWidget);
    expect(find.text('Purchase Date'), findsOneWidget);
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('New Value'), findsOneWidget);
    expect(find.text('Asking Price'), findsOneWidget);
    expect(find.text('Minimum Acceptable Price'), findsOneWidget);
    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('Bat Length'), findsOneWidget);
    expect(find.text('Bat Weight'), findsOneWidget);
    expect(find.text('Certification'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Save Inventory'), findsOneWidget);

    expect(find.byKey(const Key('buyInventoryCategoryField')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryBrandField')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryModelField')), findsOneWidget);
    expect(
      find.byKey(const Key('buyInventoryAcquisitionTypeField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('buyInventoryConditionField')), findsOneWidget);
    expect(
      find.byKey(const Key('buyInventoryPurchaseDateField')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('buyInventoryNewValueField')), findsOneWidget);
    expect(
      find.byKey(const Key('buyInventoryAskingPriceField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('buyInventoryMinimumPriceField')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('buyInventoryLengthField')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryWeightField')), findsOneWidget);
    expect(
      find.byKey(const Key('buyInventoryCertificationField')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('buyInventoryNotesField')), findsOneWidget);
    expect(find.byKey(const Key('buyInventorySubmitButton')), findsOneWidget);
  });
  testWidgets('shows glove-specific fields when Glove is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final categoryField = find.byKey(const Key('buyInventoryCategoryField'));

    await tester.tap(categoryField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Glove').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buyInventoryGloveSizeField')), findsOneWidget);
    expect(
      find.byKey(const Key('buyInventoryHandOrientationField')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('buyInventoryLengthField')), findsNothing);
    expect(find.byKey(const Key('buyInventoryWeightField')), findsNothing);
    expect(
      find.byKey(const Key('buyInventoryCertificationField')),
      findsNothing,
    );
  });

  testWidgets('shows catcher-specific field when Catcher’s Gear is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final categoryField = find.byKey(const Key('buyInventoryCategoryField'));

    await tester.tap(categoryField);
    await tester.pumpAndSettle();

    await tester.tap(find.text("Catcher's Gear").last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('buyInventoryCatchersGearSizeField')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('buyInventoryLengthField')), findsNothing);
    expect(find.byKey(const Key('buyInventoryGloveSizeField')), findsNothing);
  });

  testWidgets('shows only common details for Helmet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final categoryField = find.byKey(const Key('buyInventoryCategoryField'));

    await tester.tap(categoryField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Helmet').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buyInventoryNotesField')), findsOneWidget);

    expect(find.byKey(const Key('buyInventoryLengthField')), findsNothing);
    expect(find.byKey(const Key('buyInventoryGloveSizeField')), findsNothing);
    expect(
      find.byKey(const Key('buyInventoryCatchersGearSizeField')),
      findsNothing,
    );
  });
  testWidgets('updates the selected inventory condition', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final conditionField = find.byKey(const Key('buyInventoryConditionField'));

    await tester.ensureVisible(conditionField);
    await tester.tap(conditionField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Good').last);
    await tester.pumpAndSettle();

    final formState = container.read(buyInventoryFormControllerProvider);

    expect(formState.condition, InventoryCondition.good);
  });
  testWidgets('selects a purchase date from the date picker', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final purchaseDateField = find.byKey(
      const Key('buyInventoryPurchaseDateField'),
    );

    await tester.ensureVisible(purchaseDateField);
    await tester.tap(purchaseDateField);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final formState = container.read(buyInventoryFormControllerProvider);

    expect(formState.purchaseDate, isNotNull);

    final selectedDate = formState.purchaseDate!;
    final today = DateTime.now();

    expect(selectedDate.year, today.year);
    expect(selectedDate.month, today.month);
    expect(selectedDate.day, today.day);
  });

  testWidgets('shows required-field errors for blank submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Brand is required.'), findsOneWidget);
    expect(find.text('Acquisition value is required.'), findsOneWidget);
  });

  testWidgets('shows an error for invalid acquisition value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      'invalid',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid Acquisition value.'), findsOneWidget);
  });
  testWidgets('shows errors for invalid optional pricing values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '100.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryNewValueField')),
      'invalid',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAskingPriceField')),
      '-25',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryMinimumPriceField')),
      'invalid',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid New value.'), findsOneWidget);
    expect(find.text('Asking price cannot be negative.'), findsOneWidget);
    expect(
      find.text('Enter a valid Minimum acceptable price.'),
      findsOneWidget,
    );
  });
  testWidgets('shows errors for invalid bat measurements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '100.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryLengthField')),
      'invalid',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryWeightField')),
      '0',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid Bat length.'), findsOneWidget);
    expect(find.text('Bat weight must be greater than zero.'), findsOneWidget);
  });

  testWidgets('shows an error for invalid glove size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final formController = container.read(
      buyInventoryFormControllerProvider.notifier,
    );

    formController.setCategory(InventoryCategory.glove);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Rawlings',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '75.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryGloveSizeField')),
      '-11.5',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Glove size must be greater than zero.'), findsOneWidget);
  });
  testWidgets('saves inventory when basic information is valid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryModelField')),
      'Spec H1',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '200.00',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('was created.'), findsOneWidget);
    expect(find.text('Brand is required.'), findsNothing);
    expect(find.text('Acquisition value is required.'), findsNothing);
  });
  testWidgets('saves condition and purchase date with inventory item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    const selectedCondition = InventoryCondition.likeNew;
    final selectedPurchaseDate = DateTime(2026, 8, 2);

    final formController = container.read(
      buyInventoryFormControllerProvider.notifier,
    );

    formController.setCondition(selectedCondition);
    formController.setPurchaseDate(selectedPurchaseDate);

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Rawlings',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '125.00',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repository = container.read(inventoryRepositoryProvider);

    final items = await repository.watchInventory().firstWhere(
      (inventoryItems) => inventoryItems.isNotEmpty,
    );

    final savedItem = items.single;

    expect(savedItem.condition, selectedCondition);
    expect(savedItem.purchaseDate, selectedPurchaseDate);
  });
  testWidgets('saves optional pricing values with inventory item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Easton',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '150.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryNewValueField')),
      '399.99',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAskingPriceField')),
      '275.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryMinimumPriceField')),
      '225.00',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repository = container.read(inventoryRepositoryProvider);

    final items = await repository.watchInventory().firstWhere(
      (inventoryItems) => inventoryItems.isNotEmpty,
    );

    final savedItem = items.single;

    expect(savedItem.newValueCents, 39999);
    expect(savedItem.askingPriceCents, 27500);
    expect(savedItem.minimumPriceCents, 22500);
  });
  testWidgets('saves bat-specific fields and notes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '200.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryLengthField')),
      '32',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryWeightField')),
      '29',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryCertificationField')),
      'BBCOR',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryNotesField')),
      'Limited-edition bat.',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repository = container.read(inventoryRepositoryProvider);

    final items = await repository.watchInventory().firstWhere(
      (inventoryItems) => inventoryItems.isNotEmpty,
    );

    final savedItem = items.single;

    expect(savedItem.category, InventoryCategory.bat);
    expect(savedItem.lengthInches, 32);
    expect(savedItem.weightOunces, 29);
    expect(savedItem.certification, 'BBCOR');
    expect(savedItem.notes, 'Limited-edition bat.');
  });

  testWidgets('saves glove-specific fields', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final formController = container.read(
      buyInventoryFormControllerProvider.notifier,
    );

    formController.setCategory(InventoryCategory.glove);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Rawlings',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '125.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryGloveSizeField')),
      '11.5',
    );

    final orientationField = find.byKey(
      const Key('buyInventoryHandOrientationField'),
    );

    await tester.ensureVisible(orientationField);
    await tester.tap(orientationField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Right Hand Throw').last);
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repository = container.read(inventoryRepositoryProvider);

    final items = await repository.watchInventory().firstWhere(
      (inventoryItems) => inventoryItems.isNotEmpty,
    );

    final savedItem = items.single;

    expect(savedItem.category, InventoryCategory.glove);
    expect(savedItem.gloveSizeInches, 11.5);
    expect(savedItem.handOrientation, 'Right Hand Throw');
  });

  testWidgets('saves catcher’s gear size', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final formController = container.read(
      buyInventoryFormControllerProvider.notifier,
    );

    formController.setCategory(InventoryCategory.catchersGear);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'All-Star',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '175.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryCatchersGearSizeField')),
      'Adult',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repository = container.read(inventoryRepositoryProvider);

    final items = await repository.watchInventory().firstWhere(
      (inventoryItems) => inventoryItems.isNotEmpty,
    );

    final savedItem = items.single;

    expect(savedItem.category, InventoryCategory.catchersGear);
    expect(savedItem.catchersGearSize, 'Adult');
  });
  testWidgets('calculates drop from bat length and weight', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryLengthField')),
      '32',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryWeightField')),
      '29',
    );

    await tester.pumpAndSettle();

    final formState = container.read(buyInventoryFormControllerProvider);

    expect(formState.lengthInches, '32');
    expect(formState.weightOunces, '29');
    expect(formState.drop, '-3');
  });

  testWidgets('calculates bat weight from length and drop', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryLengthField')),
      '32',
    );

    await tester.enterText(find.byKey(const Key('buyInventoryDropField')), '3');

    await tester.pumpAndSettle();

    final formState = container.read(buyInventoryFormControllerProvider);

    expect(formState.lengthInches, '32');
    expect(formState.drop, '-3');
    expect(formState.weightOunces, '29');
  });

  testWidgets('recalculates drop when bat weight changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryLengthField')),
      '32',
    );

    await tester.enterText(find.byKey(const Key('buyInventoryDropField')), '3');

    await tester.enterText(
      find.byKey(const Key('buyInventoryWeightField')),
      '27',
    );

    await tester.pumpAndSettle();

    final formState = container.read(buyInventoryFormControllerProvider);

    expect(formState.weightOunces, '27');
    expect(formState.drop, '-5');
  });

  testWidgets('does not save hidden bat fields for a glove', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    final formController = container.read(
      buyInventoryFormControllerProvider.notifier,
    );

    formController.setLengthInches('32');
    formController.setWeightOunces('29');
    formController.setCertification('BBCOR');
    formController.setCategory(InventoryCategory.glove);

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Rawlings',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '100.00',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryGloveSizeField')),
      '11.5',
    );

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final repository = container.read(inventoryRepositoryProvider);

    final items = await repository.watchInventory().firstWhere(
      (inventoryItems) => inventoryItems.isNotEmpty,
    );

    final savedItem = items.single;

    expect(savedItem.category, InventoryCategory.glove);
    expect(savedItem.gloveSizeInches, 11.5);
    expect(savedItem.lengthInches, isNull);
    expect(savedItem.weightOunces, isNull);
    expect(savedItem.drop, isNull);
    expect(savedItem.certification, isNull);
  });
  testWidgets('seller dropdown displays saved contacts', (
    WidgetTester tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository();

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'contact-2', name: 'Jordan Smith'),
        Contact(id: 'contact-1', name: 'Alex Johnson'),
      ],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: BuyInventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final sellerField = find.byKey(const Key('buyInventorySellerField'));

    expect(sellerField, findsOneWidget);

    await tester.ensureVisible(sellerField);
    await tester.tap(sellerField);
    await tester.pumpAndSettle();

    expect(find.text('No Seller Selected'), findsAtLeastNWidgets(1));
    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('Jordan Smith'), findsOneWidget);
  });
  testWidgets('selected seller is saved on new inventory item', (
    WidgetTester tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository();

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [Contact(id: 'contact-1', name: 'Taylor Morgan')],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: BuyInventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buyInventoryBrandField')),
      'Combat',
    );

    await tester.enterText(
      find.byKey(const Key('buyInventoryAcquisitionValueField')),
      '200.00',
    );

    final sellerField = find.byKey(const Key('buyInventorySellerField'));

    await tester.ensureVisible(sellerField);
    await tester.tap(sellerField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Taylor Morgan'));
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('buyInventorySubmitButton'));

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    final items = await inventoryRepository.getInventory();

    expect(items, hasLength(1));
    expect(items.single.sellerContactId, 'contact-1');
  });
  testWidgets('editing inventory preselects the saved seller', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      sellerContactId: 'contact-1',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository(
      initialContacts: const [
        Contact(id: 'contact-1', name: 'Taylor Morgan'),
        Contact(id: 'contact-2', name: 'Jordan Smith'),
      ],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BuyInventoryScreen(existingItem: item)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final sellerField = tester.widget<DropdownButtonFormField<String?>>(
      find.byKey(const Key('buyInventorySellerField')),
    );

    expect(sellerField.initialValue, 'contact-1');
    expect(find.text('Taylor Morgan'), findsOneWidget);
  });
  testWidgets('missing linked seller does not crash edit form', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      sellerContactId: 'missing-contact',
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );

    final contactRepository = InMemoryContactRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BuyInventoryScreen(existingItem: item)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buyInventorySellerField')), findsOneWidget);

    expect(find.text('No Seller Selected'), findsOneWidget);
    expect(find.text('missing-contact'), findsNothing);
  });
}
