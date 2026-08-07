import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';

void main() {
  test('valid consignment records commission and consignor', () {
    final consignment = ConsignmentTransaction(
      inventoryItemId: 'item-a',
      consignmentDate: DateTime(2026, 8, 7),
      commissionCents: 5000,
      consignorContactId: 'contact-a',
    );

    expect(consignment.isValid, isTrue);
    expect(consignment.isCompleted, isFalse);
  });

  test('consignor payout is sale price minus commission', () {
    final consignment = ConsignmentTransaction(
      inventoryItemId: 'item-a',
      consignmentDate: DateTime(2026, 8, 7),
      commissionCents: 5000,
    );

    expect(consignment.consignorPayoutCentsForSale(20000), 15000);
  });

  test('negative commission is invalid', () {
    final consignment = ConsignmentTransaction(
      inventoryItemId: 'item-a',
      consignmentDate: DateTime(2026, 8, 7),
      commissionCents: -1,
    );

    expect(consignment.isValid, isFalse);
  });
}
