import '../../domain/repositories/inventory_repository.dart';
import 'inventory_qr_codec.dart';

enum InventoryQrScanResultType { valid, invalidCode, itemNotFound }

final class InventoryQrScanResult {
  const InventoryQrScanResult._({required this.type, this.itemId});

  const InventoryQrScanResult.valid(String itemId)
    : this._(type: InventoryQrScanResultType.valid, itemId: itemId);

  const InventoryQrScanResult.invalidCode()
    : this._(type: InventoryQrScanResultType.invalidCode);

  const InventoryQrScanResult.itemNotFound(String itemId)
    : this._(type: InventoryQrScanResultType.itemNotFound, itemId: itemId);

  final InventoryQrScanResultType type;
  final String? itemId;
}

final class InventoryQrScanResolver {
  const InventoryQrScanResolver({required this._repository});

  final InventoryRepository _repository;

  Future<InventoryQrScanResult> resolve(String rawValue) async {
    final itemId = InventoryQrCodec.tryParseInventoryItemId(rawValue);

    if (itemId == null) {
      return const InventoryQrScanResult.invalidCode();
    }

    final item = await _repository.getInventoryItem(itemId);

    if (item == null) {
      return InventoryQrScanResult.itemNotFound(itemId);
    }

    return InventoryQrScanResult.valid(itemId);
  }
}
