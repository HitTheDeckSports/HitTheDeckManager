import 'package:uuid/uuid.dart';

import '../../domain/models/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class InMemoryInventoryRepository implements InventoryRepository {
  InMemoryInventoryRepository({
    List<InventoryItem> initialItems = const [],
    Uuid? uuid,
  }) : _items = [...initialItems],
       _uuid = uuid ?? const Uuid();

  final List<InventoryItem> _items;
  final Uuid _uuid;

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

    final savedItem = item.copyWith(id: item.id ?? _uuid.v4());

    if (_items.any((existingItem) => existingItem.id == savedItem.id)) {
      throw StateError(
        'An inventory item with ID ${savedItem.id} already exists.',
      );
    }

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
