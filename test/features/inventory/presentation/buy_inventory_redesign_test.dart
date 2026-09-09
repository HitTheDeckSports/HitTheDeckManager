import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_location_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_location.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/buy_inventory_screen.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_location_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';

void main() {
  testWidgets('Buy Inventory redesign uses approved sectioned layout', (
    tester,
  ) async {
    final inventoryRepository = InMemoryInventoryRepository();
    final contactRepository = InMemoryContactRepository();
    final locationRepository = InMemoryInventoryLocationRepository(
      initialLocations: const [
        InventoryLocation(id: 'main-rack', name: 'Main Rack'),
      ],
    );

    addTearDown(inventoryRepository.dispose);
    addTearDown(contactRepository.dispose);
    addTearDown(locationRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          contactRepositoryProvider.overrideWithValue(contactRepository),
          inventoryLocationRepositoryProvider.overrideWithValue(
            locationRepository,
          ),
          currentAppPermissionsProvider.overrideWithValue(
            const AppPermissions.ownerOrAdmin(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: BuyInventoryScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buyInventoryBackButton')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryCancelButton')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryBasicSection')), findsOneWidget);
    expect(find.byKey(const Key('buyInventorySellerSection')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryPricingSection')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryDetailsSection')), findsOneWidget);
    expect(find.byKey(const Key('buyInventoryPhotosSection')), findsOneWidget);
    expect(
      find.byKey(const Key('buyInventoryBatCalculationHint')),
      findsOneWidget,
    );
    expect(find.text('Save Inventory'), findsOneWidget);
  });
}
