import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  group('SaleTransaction', () {
    test('calculates profit and gross margin', () {
      final transaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      expect(transaction.profitCents, 12500);
      expect(transaction.grossMargin, closeTo(12500 / 32500, 0.000001));
    });

    test('returns null metrics when acquisition value is unavailable', () {
      final transaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.card,
      );

      expect(transaction.profitCents, isNull);
      expect(transaction.grossMargin, isNull);
    });

    test('returns null gross margin when sale price is zero', () {
      final transaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 0,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.venmo,
        acquisitionValueCents: 0,
      );

      expect(transaction.profitCents, 0);
      expect(transaction.grossMargin, isNull);
    });

    test('validates required values', () {
      final validTransaction = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.paypal,
        acquisitionValueCents: 20000,
      );

      final missingItemId = validTransaction.copyWith(inventoryItemId: '');

      final negativeSalePrice = validTransaction.copyWith(salePriceCents: -1);

      final missingAcquisitionValue = validTransaction.copyWith(
        acquisitionValueCents: null,
      );

      expect(validTransaction.isValid, isTrue);
      expect(missingItemId.isValid, isFalse);
      expect(negativeSalePrice.isValid, isFalse);
      expect(missingAcquisitionValue.isValid, isFalse);
    });

    test('copyWith updates values and preserves unchanged fields', () {
      final original = SaleTransaction(
        id: 'sale-1',
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.cash,
        buyerContactId: 'contact-1',
        notes: 'Original notes.',
        acquisitionValueCents: 20000,
      );

      final updated = original.copyWith(
        salePriceCents: 35000,
        paymentMethod: PaymentMethod.zelle,
        notes: null,
      );

      expect(updated.id, original.id);
      expect(updated.inventoryItemId, original.inventoryItemId);
      expect(updated.salePriceCents, 35000);
      expect(updated.saleDate, original.saleDate);
      expect(updated.paymentMethod, PaymentMethod.zelle);
      expect(updated.buyerContactId, original.buyerContactId);
      expect(updated.notes, isNull);
      expect(updated.acquisitionValueCents, original.acquisitionValueCents);
    });
  });
}
