import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/qr/inventory_qr_codec.dart';

void main() {
  group('InventoryQrCodec.encodeInventoryItemId', () {
    test('creates the inventory QR URI', () {
      expect(
        InventoryQrCodec.encodeInventoryItemId('item-123'),
        'hitthedeck://inventory/item-123',
      );
    });

    test('trims the inventory item ID', () {
      expect(
        InventoryQrCodec.encodeInventoryItemId('  item-123  '),
        'hitthedeck://inventory/item-123',
      );
    });

    test('rejects an empty inventory item ID', () {
      expect(
        () => InventoryQrCodec.encodeInventoryItemId('   '),
        throwsArgumentError,
      );
    });
  });

  group('InventoryQrCodec.tryParseInventoryItemId', () {
    test('returns the inventory item ID from a valid QR value', () {
      expect(
        InventoryQrCodec.tryParseInventoryItemId(
          'hitthedeck://inventory/item-123',
        ),
        'item-123',
      );
    });

    test('supports encoded inventory item IDs', () {
      final encoded = InventoryQrCodec.encodeInventoryItemId('item 123');

      expect(InventoryQrCodec.tryParseInventoryItemId(encoded), 'item 123');
    });

    test('rejects an unrelated web URL', () {
      expect(
        InventoryQrCodec.tryParseInventoryItemId(
          'https://example.com/inventory/item-123',
        ),
        isNull,
      );
    });

    test('rejects another Hit the Deck QR type', () {
      expect(
        InventoryQrCodec.tryParseInventoryItemId(
          'hitthedeck://contact/contact-123',
        ),
        isNull,
      );
    });

    test('rejects a QR with extra path segments', () {
      expect(
        InventoryQrCodec.tryParseInventoryItemId(
          'hitthedeck://inventory/item-123/extra',
        ),
        isNull,
      );
    });

    test('rejects a QR with query parameters', () {
      expect(
        InventoryQrCodec.tryParseInventoryItemId(
          'hitthedeck://inventory/item-123?test=true',
        ),
        isNull,
      );
    });

    test('rejects a QR with a fragment', () {
      expect(
        InventoryQrCodec.tryParseInventoryItemId(
          'hitthedeck://inventory/item-123#test',
        ),
        isNull,
      );
    });

    test('rejects an empty value', () {
      expect(InventoryQrCodec.tryParseInventoryItemId('   '), isNull);
    });
  });
}
