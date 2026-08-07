import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';

void main() {
  test('creates and retrieves consignment transaction', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final saved = await repository.createConsignment(
      ConsignmentTransaction(
        id: 'consignment-a',
        inventoryItemId: 'item-a',
        consignmentDate: DateTime(2026, 8, 7),
        commissionCents: 5000,
      ),
    );

    expect(await repository.getConsignment('consignment-a'), saved);
    expect(await repository.getConsignmentForInventoryItem('item-a'), saved);
  });

  test('inventory item cannot have duplicate consignment records', () async {
    final repository = InMemoryTransactionRepository(
      initialConsignments: [
        ConsignmentTransaction(
          id: 'consignment-a',
          inventoryItemId: 'item-a',
          consignmentDate: DateTime(2026, 8, 7),
          commissionCents: 5000,
        ),
      ],
    );
    addTearDown(repository.dispose);

    expect(
      () => repository.createConsignment(
        ConsignmentTransaction(
          id: 'consignment-b',
          inventoryItemId: 'item-a',
          consignmentDate: DateTime(2026, 8, 8),
          commissionCents: 6000,
        ),
      ),
      throwsA(isA<DuplicateException>()),
    );
  });

  test('watchConsignments emits repository changes', () async {
    final repository = InMemoryTransactionRepository();
    addTearDown(repository.dispose);

    final emissions = <List<ConsignmentTransaction>>[];
    final subscription = repository.watchConsignments().listen(emissions.add);
    addTearDown(subscription.cancel);

    await Future<void>.delayed(Duration.zero);

    await repository.createConsignment(
      ConsignmentTransaction(
        id: 'consignment-a',
        inventoryItemId: 'item-a',
        consignmentDate: DateTime(2026, 8, 7),
        commissionCents: 5000,
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(emissions, hasLength(2));
    expect(emissions.last.single.id, 'consignment-a');
  });
}
