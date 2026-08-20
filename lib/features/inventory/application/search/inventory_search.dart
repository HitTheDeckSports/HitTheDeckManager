import '../../domain/models/inventory_enums.dart';
import '../../domain/models/inventory_item.dart';

final class InventorySearch {
  const InventorySearch._();

  static List<InventoryItem> filter(
    Iterable<InventoryItem> items,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List<InventoryItem>.unmodifiable(items);
    }

    final terms = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);

    return List<InventoryItem>.unmodifiable(
      items.where((item) {
        final searchableText = _searchableText(item);

        return terms.every(searchableText.contains);
      }),
    );
  }

  static String _searchableText(InventoryItem item) {
    return [
      item.inventoryNumber,
      item.brand,
      item.model,
      item.category.label,
      item.status.label,
      item.condition?.label,
      item.certification,
      item.notes,
      item.lengthInches?.toString(),
      item.weightOunces?.toString(),
      item.drop?.toString(),
      item.gloveSizeInches?.toString(),
      item.handOrientation,
      item.catchersGearSize,
    ].whereType<Object>().join(' ').toLowerCase();
  }
}
