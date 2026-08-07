import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/consignment_transaction_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  const consignedItem = InventoryItem(
    id: 'item-a',
    inventoryNumber: 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Combat',
    acquisitionType: AcquisitionType.consignment,
    acquisitionValueCents: 0,
    sellerContactId: 'contact-a',
    status: InventoryStatus.available,
  );

  test('creates consignment for consigned inventory', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(consignmentTransactionControllerProvider.future);

    final saved = await container
        .read(consignmentTransactionControllerProvider.notifier)
        .createConsignment(
          item: consignedItem,
          consignmentDate: DateTime(2026, 8, 7),
          commissionCents: 5000,
          notes: r'Hit the Deck earns $50 when sold.',
        );

    expect(saved.inventoryItemId, 'item-a');
    expect(saved.commissionCents, 5000);
    expect(saved.consignorContactId, 'contact-a');
  });

  test('purchased inventory cannot create consignment', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(consignmentTransactionControllerProvider.future);

    await expectLater(
      container
          .read(consignmentTransactionControllerProvider.notifier)
          .createConsignment(
            item: consignedItem.copyWith(
              acquisitionType: AcquisitionType.purchased,
            ),
            consignmentDate: DateTime(2026, 8, 7),
            commissionCents: 5000,
          ),
      throwsA(isA<StateError>()),
    );

    expect(await repository.getConsignments(), isEmpty);
  });

  test('sold consigned inventory cannot start a new agreement', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(consignmentTransactionControllerProvider.future);

    await expectLater(
      container
          .read(consignmentTransactionControllerProvider.notifier)
          .createConsignment(
            item: consignedItem.copyWith(status: InventoryStatus.sold),
            consignmentDate: DateTime(2026, 8, 7),
            commissionCents: 5000,
          ),
      throwsA(isA<StateError>()),
    );
  });
}
