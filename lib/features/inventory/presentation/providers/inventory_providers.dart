import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_inventory_repository.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Provides the Firestore-backed inventory repository.
///
/// Phase 3 moves inventory persistence from the temporary in-memory
/// implementation to Cloud Firestore. Tests can still override this provider
/// with an in-memory or fake repository.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return FirestoreInventoryRepository();
});

final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.watchInventory();
});

final inventoryItemProvider = FutureProvider.family<InventoryItem?, String>((
  ref,
  itemId,
) {
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.getInventoryItem(itemId);
});
