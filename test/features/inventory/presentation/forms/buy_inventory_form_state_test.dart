import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/forms/buy_inventory_form_state.dart';

void main() {
  group('BuyInventoryFormState', () {
    test('converts valid form values into an InventoryItem', () {
      final state = BuyInventoryFormState(
        category: InventoryCategory.bat,
        brand: '  Combat  ',
        model: ' Spec H1 ',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValue: r'$200.00',
        condition: InventoryCondition.likeNew,
        purchaseDate: DateTime(2026, 7, 31),
        newValue: r'$499.99',
        askingPrice: r'$325.00',
        minimumPrice: r'$275.00',
        notes: ' Limited edition bat ',
        lengthInches: '32',
        weightOunces: '29',
        certification: ' BBCOR ',
        photoUrls: const ['photo-1', 'photo-2'],
      );

      final item = state.toInventoryItem();

      expect(item, isNotNull);
      expect(item?.category, InventoryCategory.bat);
      expect(item?.brand, 'Combat');
      expect(item?.model, 'Spec H1');
      expect(item?.acquisitionValueCents, 20000);
      expect(item?.newValueCents, 49999);
      expect(item?.askingPriceCents, 32500);
      expect(item?.minimumPriceCents, 27500);
      expect(item?.lengthInches, 32);
      expect(item?.weightOunces, 29);
      expect(item?.certification, 'BBCOR');
      expect(item?.notes, 'Limited edition bat');
      expect(item?.photoUrls, hasLength(2));
    });

    test('converts blank optional text fields to null', () {
      const state = BuyInventoryFormState(
        brand: 'Wilson',
        acquisitionValue: '150.00',
        model: '   ',
        notes: '',
        certification: ' ',
        handOrientation: '',
        catchersGearSize: '',
      );

      final item = state.toInventoryItem();

      expect(item, isNotNull);
      expect(item?.model, isNull);
      expect(item?.notes, isNull);
      expect(item?.certification, isNull);
      expect(item?.handOrientation, isNull);
      expect(item?.catchersGearSize, isNull);
    });

    test('returns null when acquisition value is invalid', () {
      const state = BuyInventoryFormState(
        brand: 'Combat',
        acquisitionValue: 'invalid',
      );

      expect(state.toInventoryItem(), isNull);
    });

    test('returns null when brand is blank', () {
      const state = BuyInventoryFormState(
        brand: '   ',
        acquisitionValue: '200.00',
      );

      expect(state.toInventoryItem(), isNull);
    });

    test('returns null when resulting item fails domain validation', () {
      const state = BuyInventoryFormState(
        brand: 'Combat',
        acquisitionValue: '200.00',
        askingPrice: '100.00',
        minimumPrice: '125.00',
      );

      expect(state.toInventoryItem(), isNull);
    });

    test('copyWith updates values without changing the original', () {
      const original = BuyInventoryFormState(
        brand: 'Combat',
        acquisitionValue: '200.00',
        condition: InventoryCondition.good,
      );

      final updated = original.copyWith(
        brand: 'Wilson',
        acquisitionValue: '175.00',
      );

      expect(original.brand, 'Combat');
      expect(original.acquisitionValue, '200.00');
      expect(updated.brand, 'Wilson');
      expect(updated.acquisitionValue, '175.00');
      expect(updated.condition, InventoryCondition.good);
    });

    test('copyWith can clear nullable values', () {
      final original = BuyInventoryFormState(
        brand: 'Combat',
        acquisitionValue: '200.00',
        condition: InventoryCondition.likeNew,
        purchaseDate: DateTime(2026, 7, 31),
        sellerContactId: 'contact-1',
      );

      final updated = original.copyWith(
        condition: null,
        purchaseDate: null,
        sellerContactId: null,
      );

      expect(updated.condition, isNull);
      expect(updated.purchaseDate, isNull);
      expect(updated.sellerContactId, isNull);
    });
  });
}
