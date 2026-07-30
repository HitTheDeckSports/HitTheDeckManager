import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  testWidgets('InventoryScreen displays an empty state', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryInventoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('No inventory items yet.'), findsOneWidget);
    expect(
      find.text('Use Buy Inventory to add your first item.'),
      findsOneWidget,
    );
  });

  testWidgets('InventoryScreen displays repository items', (
    WidgetTester tester,
  ) async {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2607-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 inventory item'), findsOneWidget);
    expect(find.text('Combat'), findsOneWidget);
    expect(find.text('Bat'), findsOneWidget);
    expect(find.text('BAT-2607-0001'), findsOneWidget);
    expect(find.text('No inventory items yet.'), findsNothing);
  });
}
