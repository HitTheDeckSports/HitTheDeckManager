import '../models/inventory_location.dart';

abstract interface class InventoryLocationRepository {
  Stream<List<InventoryLocation>> watchLocations();
  Future<InventoryLocation> createLocation(String name);
  Future<InventoryLocation> renameLocation(String id, String name);
  Future<InventoryLocation> setLocationActive(String id, bool active);
}
