import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
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
      final dealRepository = InMemoryWarrantyReplacementDealRepository();

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(dealRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          warrantyReplacementDealRepositoryProvider.overrideWithValue(
            dealRepository,
          ),
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
    },
  );

  test('non-warranty disposal cannot create replacement', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [disposedItem],
    );
    final transactionRepository = InMemoryTransactionRepository();
    final dealRepository = InMemoryWarrantyReplacementDealRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(dealRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
        warrantyReplacementDealRepositoryProvider.overrideWithValue(
          dealRepository,
        ),
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
  });
}
