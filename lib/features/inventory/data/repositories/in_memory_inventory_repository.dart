import 'package:uuid/uuid.dart';

import '../../domain/models/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/services/inventory_number_generator.dart';
import '../services/in_memory_inventory_number_generator.dart';

class InMemoryInventoryRepository implements InventoryRepository {
  InMemoryInventoryRepository({
    List<InventoryItem> initialItems = const [],
    Uuid? uuid,
    InventoryNumberGenerator? inventoryNumberGenerator,
  }) : _items = [...initialItems],
       _uuid = uuid ?? const Uuid(),
       _inventoryNumberGenerator =
           inventoryNumberGenerator ?? InMemoryInventoryNumberGenerator();

  final List<InventoryItem> _items;
  final Uuid _uuid;
  final InventoryNumberGenerator _inventoryNumberGenerator;

  @override
  Future<List<InventoryItem>> getInventory() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<InventoryItem?> getInventoryItem(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  @override
  Future<InventoryItem> createInventoryItem(InventoryItem item) async {
    if (!item.isValid) {
      throw ArgumentError(item.validationErrors.join(' '));
    }

    final itemId = item.id ?? _uuid.v4();

    if (_items.any((existingItem) => existingItem.id == itemId)) {
      throw StateError('An inventory item with ID $itemId already exists.');
    }

    final inventoryNumber =
        item.inventoryNumber ??
        await _inventoryNumberGenerator.generate(
          category: item.category,
          date: item.purchaseDate ?? DateTime.now(),
        );

    final savedItem = item.copyWith(
      id: itemId,
      inventoryNumber: inventoryNumber,
    );

    _items.add(savedItem);

    return savedItem;
  }

  @override
  Future<InventoryItem> updateInventoryItem(InventoryItem item) async {
    if (item.id == null) {
      throw ArgumentError(
        'An inventory item must have an ID before it can be updated.',
      );
    }

    if (!item.isValid) {
      throw ArgumentError(item.validationErrors.join(' '));
    }

    final index = _items.indexWhere(
      (existingItem) => existingItem.id == item.id,
    );

    if (index == -1) {
      throw StateError('No inventory item exists with ID ${item.id}.');
    }

    _items[index] = item;
    return item;
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    final originalLength = _items.length;

    _items.removeWhere((item) => item.id == id);

    if (_items.length == originalLength) {
      throw StateError('No inventory item exists with ID $id.');
    }
  }
}
