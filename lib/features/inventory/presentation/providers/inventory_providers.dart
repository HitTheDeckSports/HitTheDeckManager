import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_inventory_repository.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InMemoryInventoryRepository();
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
