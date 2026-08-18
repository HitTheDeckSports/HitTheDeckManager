final class InventoryQrCodec {
  const InventoryQrCodec._();

  static const String scheme = 'hitthedeck';
  static const String inventoryHost = 'inventory';

  static String encodeInventoryItemId(String itemId) {
    final normalizedItemId = itemId.trim();

    if (normalizedItemId.isEmpty) {
      throw ArgumentError.value(
        itemId,
        'itemId',
        'Inventory item ID cannot be empty.',
      );
    }

    return Uri(
      scheme: scheme,
      host: inventoryHost,
      pathSegments: [normalizedItemId],
    ).toString();
  }

  static String? tryParseInventoryItemId(String rawValue) {
    final normalizedValue = rawValue.trim();

    if (normalizedValue.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(normalizedValue);

    if (uri == null ||
        uri.scheme != scheme ||
        uri.host != inventoryHost ||
        uri.pathSegments.length != 1 ||
        uri.pathSegments.single.trim().isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }

    return uri.pathSegments.single;
  }
}
