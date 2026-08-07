import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/warranty_replacement_deal.dart';

void main() {
  test('creates and retrieves warranty replacement Deal', () async {
    final repository = InMemoryWarrantyReplacementDealRepository();
    addTearDown(repository.dispose);

    final saved = await repository.createDeal(
      WarrantyReplacementDeal(
        id: 'deal-a',
        disposalTransactionId: 'disposal-a',
        disposedInventoryItemId: 'old-item',
        replacementInventoryItemId: 'new-item',
        replacementDate: DateTime(2026, 8, 7),
      ),
    );

    expect(await repository.getDeal('deal-a'), saved);
    expect(await repository.getDealForDisposal('disposal-a'), saved);
    expect(await repository.getDealForInventoryItem('old-item'), saved);
    expect(await repository.getDealForInventoryItem('new-item'), saved);
  });

  test('one disposal cannot create multiple replacement Deals', () async {
    final repository = InMemoryWarrantyReplacementDealRepository(
      initialDeals: [
        WarrantyReplacementDeal(
          id: 'deal-a',
          disposalTransactionId: 'disposal-a',
          disposedInventoryItemId: 'old-item',
          replacementInventoryItemId: 'new-item',
          replacementDate: DateTime(2026, 8, 7),
        ),
      ],
    );
    addTearDown(repository.dispose);

    expect(
      () => repository.createDeal(
        WarrantyReplacementDeal(
          id: 'deal-b',
          disposalTransactionId: 'disposal-a',
          disposedInventoryItemId: 'old-item',
          replacementInventoryItemId: 'another-item',
          replacementDate: DateTime(2026, 8, 8),
        ),
      ),
      throwsA(isA<DuplicateException>()),
    );
  });
}
