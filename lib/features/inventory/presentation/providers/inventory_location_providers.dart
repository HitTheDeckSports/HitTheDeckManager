import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_inventory_location_repository.dart';
import '../../domain/models/inventory_location.dart';
import '../../domain/repositories/inventory_location_repository.dart';

final inventoryLocationRepositoryProvider =
    Provider<InventoryLocationRepository>((ref) {
      return FirestoreInventoryLocationRepository();
    });

final inventoryLocationsProvider = StreamProvider<List<InventoryLocation>>((
  ref,
) {
  return ref.watch(inventoryLocationRepositoryProvider).watchLocations();
});

final activeInventoryLocationsProvider =
    Provider<AsyncValue<List<InventoryLocation>>>((ref) {
      return ref
          .watch(inventoryLocationsProvider)
          .whenData(
            (locations) => locations
                .where((location) => location.active)
                .toList(growable: false),
          );
    });
