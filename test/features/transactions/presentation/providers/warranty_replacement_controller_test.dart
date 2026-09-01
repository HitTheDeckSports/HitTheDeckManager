import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_providers.dart';

void main() {
  const disposedItem = InventoryItem(
    id: 'old-item',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    model: 'Spec H1',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 15000,
    condition: InventoryCondition.good,
    status: InventoryStatus.disposed,
    askingPriceCents: 25000,
  );

  final disposal = DisposalTransaction(
    id: 'disposal-a',
    inventoryItemId: 'old-item',
    disposalDate: DateTime(2026, 8, 7),
    reason: DisposalReason.warrantyReplacement,
  );

  test(
    'creates replacement inventory and Deal while preserving cost basis',
    () async {
      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: const [disposedItem],
      );
      final transactionRepository = InMemoryTransactionRepository(
        initialDisposals: [disposal],
      );
      final warrantyDealRepository =
          InMemoryWarrantyReplacementDealRepository();
      final lineageDealRepository = InMemoryDealRepository();

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(warrantyDealRepository.dispose);
      addTearDown(lineageDealRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          warrantyReplacementDealRepositoryProvider.overrideWithValue(
            warrantyDealRepository,
          ),
          dealRepositoryProvider.overrideWithValue(lineageDealRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(warrantyReplacementControllerProvider.future);

      final deal = await container
          .read(warrantyReplacementControllerProvider.notifier)
          .createReplacement(
            disposal: disposal,
            disposedItem: disposedItem,
            replacementDate: DateTime(2026, 8, 8),
          );

      final replacement = await inventoryRepository.getInventoryItem(
        deal.replacementInventoryItemId,
      );
      final updatedDisposal = await transactionRepository.getDisposal(
        'disposal-a',
      );

      expect(replacement, isNotNull);
      expect(replacement?.status, InventoryStatus.available);
      expect(replacement?.condition, InventoryCondition.newItem);
      expect(replacement?.acquisitionValueCents, 15000);
      expect(replacement?.brand, 'Combat');
      expect(replacement?.model, 'Spec H1');
      expect(updatedDisposal?.replacementInventoryItemId, replacement?.id);
      expect(deal.disposedInventoryItemId, 'old-item');
      expect(await lineageDealRepository.getDeals(), isEmpty);
    },
  );

  test(
    'warranty replacement continues the same recursive Deal lineage',
    () async {
      const tradeInDisposedItem = InventoryItem(
        id: 'trade-item',
        inventoryNumber: 'BAT-2608-0042',
        category: InventoryCategory.bat,
        brand: 'Easton',
        model: 'Hype Fire',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 20000,
        condition: InventoryCondition.good,
        status: InventoryStatus.disposed,
        askingPriceCents: 30000,
      );

      final warrantyDisposal = DisposalTransaction(
        id: 'disposal-lineage',
        inventoryItemId: 'trade-item',
        disposalDate: DateTime(2026, 9, 3),
        reason: DisposalReason.warrantyReplacement,
      );

      const originalDeal = Deal(
        id: 'deal-root',
        parentSaleTransactionId: 'sale-root',
        childInventoryItemIds: ['trade-item'],
        lineageInventoryItemIds: ['trade-item'],
      );

      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: const [tradeInDisposedItem],
      );
      final transactionRepository = InMemoryTransactionRepository(
        initialDisposals: [warrantyDisposal],
      );
      final warrantyDealRepository =
          InMemoryWarrantyReplacementDealRepository();
      final lineageDealRepository = InMemoryDealRepository(
        initialDeals: const [originalDeal],
      );

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(warrantyDealRepository.dispose);
      addTearDown(lineageDealRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          warrantyReplacementDealRepositoryProvider.overrideWithValue(
            warrantyDealRepository,
          ),
          dealRepositoryProvider.overrideWithValue(lineageDealRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(warrantyReplacementControllerProvider.future);

      final warrantyDeal = await container
          .read(warrantyReplacementControllerProvider.notifier)
          .createReplacement(
            disposal: warrantyDisposal,
            disposedItem: tradeInDisposedItem,
            replacementDate: DateTime(2026, 9, 4),
          );

      final replacementId = warrantyDeal.replacementInventoryItemId;
      final deals = await lineageDealRepository.getDeals();

      expect(deals, hasLength(1));
      final continuedDeal = deals.single;

      expect(continuedDeal.id, 'deal-root');
      expect(continuedDeal.parentSaleTransactionId, 'sale-root');
      expect(continuedDeal.childInventoryItemIds, const ['trade-item']);
      expect(
        continuedDeal.effectiveLineageInventoryItemIds,
        containsAll(['trade-item', replacementId]),
      );
      expect(
        (await lineageDealRepository.getDealForLineageInventoryItem(
          replacementId,
        ))?.id,
        'deal-root',
      );

      expect(
        await transactionRepository.getTradesForInventoryItem(replacementId),
        isEmpty,
      );

      expect(warrantyDeal.disposedInventoryItemId, 'trade-item');
      expect(warrantyDeal.replacementInventoryItemId, replacementId);
    },
  );

  test('non-warranty disposal cannot create replacement', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [disposedItem],
    );
    final transactionRepository = InMemoryTransactionRepository();
    final warrantyDealRepository = InMemoryWarrantyReplacementDealRepository();
    final lineageDealRepository = InMemoryDealRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(warrantyDealRepository.dispose);
    addTearDown(lineageDealRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
        warrantyReplacementDealRepositoryProvider.overrideWithValue(
          warrantyDealRepository,
        ),
        dealRepositoryProvider.overrideWithValue(lineageDealRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(warrantyReplacementControllerProvider.future);

    await expectLater(
      container
          .read(warrantyReplacementControllerProvider.notifier)
          .createReplacement(
            disposal: DisposalTransaction(
              id: 'disposal-other',
              inventoryItemId: 'old-item',
              disposalDate: DateTime(2026, 8, 7),
              reason: DisposalReason.other,
            ),
            disposedItem: disposedItem,
            replacementDate: DateTime(2026, 8, 8),
          ),
      throwsA(isA<StateError>()),
    );

    expect(await lineageDealRepository.getDeals(), isEmpty);
  });
}
