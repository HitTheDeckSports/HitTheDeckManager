import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';

void main() {
  group('InventoryItem', () {
    test('defaults to available status', () {
      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      expect(item.status, InventoryStatus.available);
      expect(item.isAvailable, isTrue);
      expect(item.isSold, isFalse);
    });

    test('calculates potential profit from asking price', () {
      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        askingPriceCents: 32500,
      );

      expect(item.hasAskingPrice, isTrue);
      expect(item.potentialProfitCents, 12500);
    });

    test('returns null potential profit when asking price is missing', () {
      const item = InventoryItem(
        category: InventoryCategory.glove,
        brand: 'Wilson',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 15000,
      );

      expect(item.hasAskingPrice, isFalse);
      expect(item.potentialProfitCents, isNull);
    });

    test('stores photo references', () {
      const item = InventoryItem(
        category: InventoryCategory.helmet,
        brand: 'Easton',
        acquisitionType: AcquisitionType.consignment,
        acquisitionValueCents: 5000,
        photoUrls: [
          'https://example.com/photo-1.jpg',
          'https://example.com/photo-2.jpg',
        ],
      );

      expect(item.photoUrls, hasLength(2));
    });

    test('copyWith creates an updated item without changing the original', () {
      const original = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        askingPriceCents: 30000,
      );

      final updated = original.copyWith(
        status: InventoryStatus.sold,
        askingPriceCents: 32500,
      );

      expect(original.status, InventoryStatus.available);
      expect(original.askingPriceCents, 30000);

      expect(updated.status, InventoryStatus.sold);
      expect(updated.askingPriceCents, 32500);
      expect(updated.brand, original.brand);
      expect(updated.acquisitionValueCents, original.acquisitionValueCents);
    });
    test('accepts a valid inventory item', () {
      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        askingPriceCents: 32500,
        minimumPriceCents: 27500,
      );

      expect(item.isValid, isTrue);
      expect(item.validationErrors, isEmpty);
    });

    test('requires a non-empty brand', () {
      const item = InventoryItem(
        category: InventoryCategory.bat,
        brand: '   ',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      expect(item.isValid, isFalse);
      expect(item.validationErrors, contains('Brand is required.'));
    });

    test('rejects negative monetary values', () {
      const item = InventoryItem(
        category: InventoryCategory.glove,
        brand: 'Wilson',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: -100,
        newValueCents: -200,
        askingPriceCents: -300,
        minimumPriceCents: -400,
      );

      expect(item.isValid, isFalse);
      expect(
        item.validationErrors,
        containsAll([
          'Acquisition value cannot be negative.',
          'New value cannot be negative.',
          'Asking price cannot be negative.',
          'Minimum price cannot be negative.',
        ]),
      );
    });

    test('rejects a minimum price greater than the asking price', () {
      const item = InventoryItem(
        category: InventoryCategory.helmet,
        brand: 'Easton',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 5000,
        askingPriceCents: 8000,
        minimumPriceCents: 9000,
      );

      expect(item.isValid, isFalse);
      expect(
        item.validationErrors,
        contains('Minimum price cannot exceed asking price.'),
      );
    });

    test('rejects more than 10 photos', () {
      const item = InventoryItem(
        category: InventoryCategory.catchersGear,
        brand: 'All-Star',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 25000,
        photoUrls: [
          'photo-1',
          'photo-2',
          'photo-3',
          'photo-4',
          'photo-5',
          'photo-6',
          'photo-7',
          'photo-8',
          'photo-9',
          'photo-10',
          'photo-11',
        ],
      );

      expect(item.isValid, isFalse);
      expect(
        item.validationErrors,
        contains('An inventory item cannot have more than 10 photos.'),
      );
    });
    test('copyWith can clear optional values', () {
      const original = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        askingPriceCents: 32500,
        notes: 'Limited edition bat',
      );

      final updated = original.copyWith(
        model: null,
        askingPriceCents: null,
        notes: null,
      );

      expect(updated.model, isNull);
      expect(updated.askingPriceCents, isNull);
      expect(updated.notes, isNull);
      expect(updated.brand, original.brand);
    });
  });
  test('saved items with the same id are equal', () {
    const first = InventoryItem(
      id: 'item-1',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    const second = InventoryItem(
      id: 'item-1',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 25000,
    );

    expect(first, equals(second));
    expect(first.hashCode, equals(second.hashCode));
  });

  test('saved items with different ids are not equal', () {
    const first = InventoryItem(
      id: 'item-1',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    const second = InventoryItem(
      id: 'item-2',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
    );

    expect(first, isNot(equals(second)));
  });

  test('separate unsaved items are not equal', () {
    final first = InventoryItem(
      category: InventoryCategory.glove,
      brand: 'Wilson',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 15000,
    );

    final second = InventoryItem(
      category: InventoryCategory.glove,
      brand: 'Wilson',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 15000,
    );

    expect(first, isNot(equals(second)));
  });

  test('an unsaved item is equal to itself', () {
    const item = InventoryItem(
      category: InventoryCategory.helmet,
      brand: 'Easton',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 5000,
    );

    expect(item, equals(item));
  });
}
