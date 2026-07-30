import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_inventory_repository.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InMemoryInventoryRepository();
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.getInventory();
});
