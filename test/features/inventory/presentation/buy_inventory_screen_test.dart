import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_controller.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/buy_inventory_screen.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
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
    expect(find.byKey(const Key('buyInventorySubmitButton')), findsOneWidget);
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
}
