import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';

void main() {
  test('creates and retrieves disposal transactions', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);
    final saved = await repository.createDisposal(
      DisposalTransaction(
        id: 'disposal-a',
        inventoryItemId: 'item-a',
        disposalDate: DateTime(2026, 8, 7),
        reason: DisposalReason.damagedBeyondRepair,
      ),
    );
    expect(await repository.getDisposal('disposal-a'), saved);
    expect(await repository.getDisposalsForInventoryItem('item-a'), [saved]);
  });

  test('an inventory item cannot be disposed twice', () async {
    final repository = InMemoryTransactionRepository(
      initialDisposals: [
        DisposalTransaction(
          id: 'disposal-a',
          inventoryItemId: 'item-a',
          disposalDate: DateTime(2026, 8, 7),
          reason: DisposalReason.obsolete,
        ),
      ],
    );
    addTearDown(repository.dispose);
    expect(
      () => repository.createDisposal(
        DisposalTransaction(
          id: 'disposal-b',
          inventoryItemId: 'item-a',
          disposalDate: DateTime(2026, 8, 8),
          reason: DisposalReason.other,
        ),
      ),
      throwsA(isA<DuplicateException>()),
    );
  });

  test('watchDisposals emits repository changes', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);
    final emissions = <List<DisposalTransaction>>[];
    final subscription = repository.watchDisposals().listen(emissions.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    await repository.createDisposal(
      DisposalTransaction(
        id: 'disposal-a',
        inventoryItemId: 'item-a',
        disposalDate: DateTime(2026, 8, 7),
        reason: DisposalReason.donated,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(emissions, hasLength(2));
    expect(emissions.last.single.id, 'disposal-a');
  });
}
