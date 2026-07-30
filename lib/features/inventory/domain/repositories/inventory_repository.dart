import '../models/inventory_item.dart';

abstract interface class InventoryRepository {
  /// Returns all inventory records available to the current user.
  Future<List<InventoryItem>> getInventory();

  /// Returns one inventory item, or null when the ID does not exist.
  Future<InventoryItem?> getInventoryItem(String id);

  /// Creates a new inventory item and returns the saved record.
  ///
  /// The returned item should contain its assigned ID and inventory number.
  Future<InventoryItem> createInventoryItem(InventoryItem item);

  /// Saves changes to an existing inventory item.
  Future<InventoryItem> updateInventoryItem(InventoryItem item);

  /// Permanently removes an inventory record.
  ///
  /// Normal business workflows should generally change an item's status
  /// instead of deleting it.
  Future<void> deleteInventoryItem(String id);
}
