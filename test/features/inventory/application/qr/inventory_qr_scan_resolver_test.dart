import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/qr/inventory_qr_scan_resolver.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';

void main() {
  test('returns invalidCode for a non-inventory QR value', () async {
    final repository = InMemoryInventoryRepository();
    addTearDown(repository.dispose);

    final resolver = InventoryQrScanResolver(repository: repository);

    final result = await resolver.resolve('https://example.com/not-inventory');

    expect(result.type, InventoryQrScanResultType.invalidCode);
    expect(result.itemId, isNull);
  });

  test('returns itemNotFound when the QR item does not exist', () async {
    final repository = InMemoryInventoryRepository();
    addTearDown(repository.dispose);

    final resolver = InventoryQrScanResolver(repository: repository);

    final result = await resolver.resolve(
      'hitthedeck://inventory/missing-item',
    );

    expect(result.type, InventoryQrScanResultType.itemNotFound);
    expect(result.itemId, 'missing-item');
  });

  test('returns valid when the QR inventory item exists', () async {
    const item = InventoryItem(
      id: 'item-123',
      inventoryNumber: 'BAT-2608-0123',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 10000,
    );

    final repository = InMemoryInventoryRepository(initialItems: [item]);
    addTearDown(repository.dispose);

    final resolver = InventoryQrScanResolver(repository: repository);

    final result = await resolver.resolve('hitthedeck://inventory/item-123');

    expect(result.type, InventoryQrScanResultType.valid);
    expect(result.itemId, 'item-123');
  });
}
