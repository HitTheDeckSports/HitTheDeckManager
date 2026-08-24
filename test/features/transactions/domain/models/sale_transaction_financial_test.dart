import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  group('SaleTransaction financial snapshot', () {
    test('includes repairs in total cost basis and profit', () {
      final sale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 24),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
        repairCostCents: 3500,
      );

      expect(sale.totalCostBasisCents, 23500);
      expect(sale.profitCents, 9000);
      expect(sale.grossMargin, closeTo(9000 / 32500, 0.000001));
    });

    test('defaults repair cost to zero for existing behavior', () {
      final sale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 24),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      expect(sale.repairCostCents, 0);
      expect(sale.totalCostBasisCents, 20000);
      expect(sale.profitCents, 12500);
    });

    test('rejects a negative repair snapshot', () {
      final sale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 24),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
        repairCostCents: -1,
      );

      expect(sale.isValid, isFalse);
    });

    test('copyWith preserves and updates repair snapshot', () {
      final original = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 24),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
        repairCostCents: 2500,
      );

      expect(original.copyWith().repairCostCents, 2500);
      expect(original.copyWith(repairCostCents: 4000).repairCostCents, 4000);
    });
  });
}
