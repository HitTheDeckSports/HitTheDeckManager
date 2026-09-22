import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_location_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_location.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/inventory_locations_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_location_providers.dart';

void main() {
  group('Managed Inventory Locations', () {
    test('creates, renames, deactivates, and restores locations', () async {
      final repository = InMemoryInventoryLocationRepository();
      addTearDown(repository.dispose);
      final created = await repository.createLocation('  Main Bat Rack  ');
      expect(created.name, 'Main Bat Rack');
      expect(created.active, isTrue);
      final renamed = await repository.renameLocation(created.id, 'Facility A');
      expect(renamed.name, 'Facility A');
      expect(
        (await repository.setLocationActive(created.id, false)).active,
        isFalse,
      );
      expect(
        (await repository.setLocationActive(created.id, true)).active,
        isTrue,
      );
    });

    test('location names are unique ignoring case and whitespace', () async {
      final repository = InMemoryInventoryLocationRepository(
        initialLocations: const [
          InventoryLocation(id: 'location-1', name: 'Storage'),
        ],
      );
      addTearDown(repository.dispose);
      expect(
        () => repository.createLocation(' storage '),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('management screen lists active and inactive locations', (
      tester,
    ) async {
      final repository = InMemoryInventoryLocationRepository(
        initialLocations: const [
          InventoryLocation(id: 'main-rack', name: 'Main Rack'),
          InventoryLocation(
            id: 'old-display',
            name: 'Old Display',
            active: false,
          ),
        ],
      );
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryLocationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: InventoryLocationsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Main Rack'), findsOneWidget);
      expect(find.text('Old Display'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(
        find.byKey(const Key('addInventoryLocationButton')),
        findsOneWidget,
      );
    });

    testWidgets('can add a location from the management screen', (
      tester,
    ) async {
      final repository = InMemoryInventoryLocationRepository();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryLocationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: InventoryLocationsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addInventoryLocationButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inventoryLocationNameField')),
        'Facility B',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Facility B'), findsOneWidget);
    });
  });
}
