import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/forms/sell_inventory_form_state.dart';

void main() {
  group('SellInventoryFormState', () {
    const item = InventoryItem(
      id: 'item-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      model: 'Spec H1',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      askingPriceCents: 32500,
      status: InventoryStatus.available,
    );

    test('parses sale price and calculates live metrics', () {
      const state = SellInventoryFormState(
        selectedItem: item,
        salePrice: '325.00',
      );

      expect(state.salePriceCents, 32500);
      expect(state.profitCents, 12500);
      expect(state.grossMargin, closeTo(12500 / 32500, 0.000001));
    });

    test('returns null metrics when sale price is invalid', () {
      const state = SellInventoryFormState(
        selectedItem: item,
        salePrice: 'invalid',
      );

      expect(state.salePriceCents, isNull);
      expect(state.profitCents, isNull);
      expect(state.grossMargin, isNull);
    });

    test('returns null gross margin when sale price is zero', () {
      const zeroCostItem = InventoryItem(
        id: 'item-2',
        inventoryNumber: 'BAT-2608-0002',
        category: InventoryCategory.bat,
        brand: 'Easton',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 0,
      );

      const state = SellInventoryFormState(
        selectedItem: zeroCostItem,
        salePrice: '0',
      );

      expect(state.salePriceCents, 0);
      expect(state.profitCents, 0);
      expect(state.grossMargin, isNull);
    });

    test('creates a valid sale transaction', () {
      final saleDate = DateTime(2026, 8, 3);

      final state = SellInventoryFormState(
        selectedItem: item,
        salePrice: '325.00',
        saleDate: saleDate,
        paymentMethod: PaymentMethod.venmo,
        buyerContactId: 'contact-1',
        notes: '  Sold during tournament.  ',
      );

      final transaction = state.toSaleTransaction();

      expect(transaction, isNotNull);
      expect(transaction?.inventoryItemId, 'item-1');
      expect(transaction?.salePriceCents, 32500);
      expect(transaction?.saleDate, saleDate);
      expect(transaction?.paymentMethod, PaymentMethod.venmo);
      expect(transaction?.buyerContactId, 'contact-1');
      expect(transaction?.notes, 'Sold during tournament.');
      expect(transaction?.acquisitionValueCents, 20000);
      expect(transaction?.profitCents, 12500);
    });

    test('rejects incomplete or invalid sale data', () {
      final validDate = DateTime(2026, 8, 3);

      const missingItem = SellInventoryFormState(salePrice: '325.00');

      const unsavedItem = InventoryItem(
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
      );

      final missingItemId = SellInventoryFormState(
        selectedItem: unsavedItem,
        salePrice: '325.00',
        saleDate: validDate,
      );

      const missingDate = SellInventoryFormState(
        selectedItem: item,
        salePrice: '325.00',
      );

      final invalidPrice = SellInventoryFormState(
        selectedItem: item,
        salePrice: 'invalid',
        saleDate: validDate,
      );

      final negativePrice = SellInventoryFormState(
        selectedItem: item,
        salePrice: '-1.00',
        saleDate: validDate,
      );

      expect(missingItem.toSaleTransaction(), isNull);
      expect(missingItemId.toSaleTransaction(), isNull);
      expect(missingDate.toSaleTransaction(), isNull);
      expect(invalidPrice.toSaleTransaction(), isNull);
      expect(negativePrice.toSaleTransaction(), isNull);
    });

    test('copyWith updates values and can clear optional fields', () {
      final originalDate = DateTime(2026, 8, 3);

      final original = SellInventoryFormState(
        selectedItem: item,
        salePrice: '325.00',
        saleDate: originalDate,
        paymentMethod: PaymentMethod.cash,
        buyerContactId: 'contact-1',
        notes: 'Original notes.',
      );

      final updated = original.copyWith(
        salePrice: '350.00',
        paymentMethod: PaymentMethod.zelle,
        buyerContactId: null,
        notes: 'Updated notes.',
      );

      expect(updated.selectedItem, item);
      expect(updated.salePrice, '350.00');
      expect(updated.saleDate, originalDate);
      expect(updated.paymentMethod, PaymentMethod.zelle);
      expect(updated.buyerContactId, isNull);
      expect(updated.notes, 'Updated notes.');

      final cleared = updated.copyWith(selectedItem: null, saleDate: null);

      expect(cleared.selectedItem, isNull);
      expect(cleared.saleDate, isNull);
      expect(cleared.salePrice, '350.00');
    });
  });
}
