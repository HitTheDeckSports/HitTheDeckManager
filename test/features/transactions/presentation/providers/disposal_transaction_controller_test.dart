import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/disposal_transaction_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  const item = InventoryItem(
    id: 'item-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Sample',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 15000,
    status: InventoryStatus.available,
  );

  test('disposing inventory marks item disposed and records reason', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository();
    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(disposalTransactionControllerProvider.future);
    final disposal = await container
        .read(disposalTransactionControllerProvider.notifier)
        .disposeInventoryItem(
          item: item,
          disposalDate: DateTime(2026, 8, 7),
          reason: DisposalReason.damagedBeyondRepair,
          notes: 'Barrel cracked during inspection.',
        );
    final updated = await inventoryRepository.getInventoryItem('item-a');
    expect(updated?.status, InventoryStatus.disposed);
    expect(disposal.reason, DisposalReason.damagedBeyondRepair);
    expect(disposal.notes, 'Barrel cracked during inspection.');
  });

  test('warranty replacement disposal is marked for Deal follow-up', () async {
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [item],
    );
    final transactionRepository = InMemoryTransactionRepository();
    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(disposalTransactionControllerProvider.future);
    final disposal = await container
        .read(disposalTransactionControllerProvider.notifier)
        .disposeInventoryItem(
          item: item,
          disposalDate: DateTime(2026, 8, 7),
          reason: DisposalReason.warrantyReplacement,
        );
    expect(disposal.requiresReplacementDeal, isTrue);
  });

  test('sold inventory cannot be disposed', () async {
    const soldItem = InventoryItem(
      id: 'item-sold',
      category: InventoryCategory.bat,
      brand: 'Sold Sample',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.sold,
    );
    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [soldItem],
    );
    final transactionRepository = InMemoryTransactionRepository();
    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(disposalTransactionControllerProvider.future);
    await expectLater(
      container
          .read(disposalTransactionControllerProvider.notifier)
          .disposeInventoryItem(
            item: soldItem,
            disposalDate: DateTime(2026, 8, 7),
            reason: DisposalReason.other,
          ),
      throwsA(isA<StateError>()),
    );
    expect(await transactionRepository.getDisposals(), isEmpty);
  });
}
