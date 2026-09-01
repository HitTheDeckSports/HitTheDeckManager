import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';

void main() {
  test('creates and retrieves a Deal by parent and child links', () async {
    final repository = InMemoryDealRepository();
    addTearDown(repository.dispose);

    final saved = await repository.createDeal(
      const Deal(
        id: 'deal-a',
        parentSaleTransactionId: 'sale-a',
        childInventoryItemIds: ['bat-b'],
      ),
    );

    expect(await repository.getDeal(saved.id!), saved);
    expect(await repository.getDealForParentSale('sale-a'), saved);
    expect(await repository.getDealForChildInventoryItem('bat-b'), saved);
  });

  test('new Deal initializes lineage with direct children', () async {
    final repository = InMemoryDealRepository();
    addTearDown(repository.dispose);

    final saved = await repository.createDeal(
      const Deal(
        id: 'deal-a',
        parentSaleTransactionId: 'sale-a',
        childInventoryItemIds: ['bat-b'],
      ),
    );

    expect(saved.lineageInventoryItemIds, const ['bat-b']);
    expect(await repository.getDealForLineageInventoryItem('bat-b'), saved);
  });

  test('finds a Deal by a later descendant in its lineage', () async {
    final repository = InMemoryDealRepository(
      initialDeals: const [
        Deal(
          id: 'deal-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: ['bat-b'],
          lineageInventoryItemIds: ['bat-b', 'bat-c', 'bat-d'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    final found = await repository.getDealForLineageInventoryItem('bat-d');

    expect(found?.id, 'deal-a');
    expect(await repository.getDealForChildInventoryItem('bat-d'), isNull);
  });

  test('one lineage item cannot belong to multiple Deals', () async {
    final repository = InMemoryDealRepository(
      initialDeals: const [
        Deal(
          id: 'deal-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: ['bat-b'],
          lineageInventoryItemIds: ['bat-b', 'bat-descendant'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    expect(
      () => repository.createDeal(
        const Deal(
          id: 'deal-c',
          parentSaleTransactionId: 'sale-c',
          childInventoryItemIds: ['bat-descendant'],
        ),
      ),
      throwsA(isA<DuplicateException>()),
    );
  });
  test('one child item cannot belong to multiple Deals', () async {
    final repository = InMemoryDealRepository(
      initialDeals: const [
        Deal(
          id: 'deal-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: ['bat-b'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    expect(
      () => repository.createDeal(
        const Deal(
          id: 'deal-c',
          parentSaleTransactionId: 'sale-c',
          childInventoryItemIds: ['bat-b'],
        ),
      ),
      throwsA(isA<DuplicateException>()),
    );
  });

  test('watchDeals emits repository changes', () async {
    final repository = InMemoryDealRepository();
    addTearDown(repository.dispose);

    final emissions = <List<Deal>>[];
    final subscription = repository.watchDeals().listen(emissions.add);
    addTearDown(subscription.cancel);

    await Future<void>.delayed(Duration.zero);

    await repository.createDeal(
      const Deal(
        id: 'deal-a',
        parentSaleTransactionId: 'sale-a',
        childInventoryItemIds: ['bat-b'],
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(emissions, hasLength(2));
    expect(emissions.last.single.id, 'deal-a');
  });
}
