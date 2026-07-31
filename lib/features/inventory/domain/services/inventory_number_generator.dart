import '../models/inventory_enums.dart';

abstract interface class InventoryNumberGenerator {
  Future<String> generate({
    required InventoryCategory category,
    required DateTime date,
  });
}
