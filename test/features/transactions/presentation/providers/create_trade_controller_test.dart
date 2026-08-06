import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/incoming_trade_item_draft.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/create_trade_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test('creates incoming items, inactivates outgoing items, and saves trade',
      () async {
    const outgoing = InventoryItem(
      id: 'out-1',
      inventoryNumber: 'BAT-2608-0001',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 20000,
      status: InventoryStatus.available,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [outgoing],
    );
    final transactionRepository = InMemoryTransactionRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(
          transactionRepository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(createTradeControllerProvider.future);

    final trade = await container
        .read(createTradeControllerProvider.notifier)
        .createTrade(
          CreateTradeRequest(
            outgoingInventoryItemIds: const ['out-1'],
            incomingItems: const [
              IncomingTradeItemDraft(
                category: InventoryCategory.glove,
                brand: 'Rawlings',
                model: 'Heart of the Hide',
                acquisitionValueCents: 15000,
              ),
            ],
            tradeDate: DateTime(2026, 8, 6),
            contactId: 'contact-1',
          ),
        );

    expect(trade.id, isNotNull);
    expect(trade.outgoingInventoryItemIds, ['out-1']);
    expect(trade.incomingInventoryItemIds, hasLength(1));

    final updatedOutgoing =
        await inventoryRepository.getInventoryItem('out-1');
    expect(updatedOutgoing?.status, InventoryStatus.inactive);

    final incoming = await inventoryRepository.getInventoryItem(
      trade.incomingInventoryItemIds.single,
    );
    expect(incoming?.brand, 'Rawlings');
    expect(incoming?.acquisitionType, AcquisitionType.traded);
    expect(incoming?.status, InventoryStatus.available);
    expect(incoming?.sellerContactId, 'contact-1');
    expect(incoming?.purchaseDate, DateTime(2026, 8, 6));
  });

  test('rejects a trade without any items', () async {
    final inventoryRepository = InMemoryInventoryRepository();
    final transactionRepository = InMemoryTransactionRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        transactionRepositoryProvider.overrideWithValue(
          transactionRepository,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(createTradeControllerProvider.future);

    await expectLater(
      container.read(createTradeControllerProvider.notifier).createTrade(
            CreateTradeRequest(
              outgoingInventoryItemIds: const [],
              incomingItems: const [],
              tradeDate: DateTime(2026, 8, 6),
            ),
          ),
      throwsA(isA<StateError>()),
    );

    expect(await transactionRepository.getTrades(), isEmpty);
  });
}
