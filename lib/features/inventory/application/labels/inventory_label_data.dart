import 'package:hit_the_deck_manager/features/inventory/application/qr/inventory_qr_codec.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';

final class InventoryLabelData {
  const InventoryLabelData({
    required this.qrValue,
    required this.inventoryNumber,
    required this.displayName,
  });

  final String qrValue;
  final String inventoryNumber;
  final String displayName;

  factory InventoryLabelData.fromInventoryItem(InventoryItem item) {
    final itemId = item.id?.trim();

    if (itemId == null || itemId.isEmpty) {
      throw ArgumentError(
        'Inventory labels require a saved inventory item ID.',
      );
    }

    final inventoryNumber = item.inventoryNumber?.trim();
    final model = item.model?.trim();

    final displayName = model == null || model.isEmpty
        ? item.brand.trim()
        : '${item.brand.trim()} $model';

    return InventoryLabelData(
      qrValue: InventoryQrCodec.encodeInventoryItemId(itemId),
      inventoryNumber: inventoryNumber == null || inventoryNumber.isEmpty
          ? 'Not assigned'
          : inventoryNumber,
      displayName: displayName,
    );
  }
}
