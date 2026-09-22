import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';

void main() {
  test('Deal display numbers use year and creation sequence', () async {
    final repository = InMemoryDealRepository(
      initialDeals: [
        Deal(
          id: 'firebase-random-a',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: const ['item-a'],
          createdAt: DateTime(2026, 1, 5, 9),
        ),
        Deal(
          id: 'firebase-random-b',
          parentSaleTransactionId: 'sale-b',
          childInventoryItemIds: const ['item-b'],
          createdAt: DateTime(2026, 2, 1, 11),
        ),
        Deal(
          id: 'firebase-random-c',
          parentSaleTransactionId: 'sale-c',
          childInventoryItemIds: const ['item-c'],
          createdAt: DateTime(2027, 1, 2, 8),
        ),
      ],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [dealRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(
        dealDisplayNumberProvider('firebase-random-a').future,
      ),
      '2026-001',
    );
    expect(
      await container.read(
        dealDisplayNumberProvider('firebase-random-b').future,
      ),
      '2026-002',
    );
    expect(
      await container.read(
        dealDisplayNumberProvider('firebase-random-c').future,
      ),
      '2027-001',
    );
  });

  test('Deal display number never falls back to Firebase ID', () async {
    final repository = InMemoryDealRepository(
      initialDeals: const [
        Deal(
          id: 'wUS69gyl9NelSkyQPGUG',
          parentSaleTransactionId: 'sale-a',
          childInventoryItemIds: ['item-a'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [dealRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(
        dealDisplayNumberProvider('wUS69gyl9NelSkyQPGUG').future,
      ),
      isNull,
    );
  });
}
