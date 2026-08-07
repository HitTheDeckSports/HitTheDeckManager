import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';

void main() {
  test('valid Deal requires one parent sale and unique child items', () {
    const deal = Deal(
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['bat-b'],
    );

    expect(deal.isValid, isTrue);
  });

  test('duplicate child inventory IDs are invalid', () {
    const deal = Deal(
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['bat-b', 'bat-b'],
    );

    expect(deal.isValid, isFalse);
  });

  test('Deal requires at least one direct child item', () {
    const deal = Deal(
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: [],
    );

    expect(deal.isValid, isFalse);
  });
}
