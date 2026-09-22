import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/contacts/application/contact_relationship.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_relationship_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test('aggregates relationships for every referenced contact', () async {
    final container = ProviderContainer(
      overrides: [
        inventoryItemsProvider.overrideWith(
          (ref) => Stream.value([
            const InventoryItem(
              id: 'item-1',
              category: InventoryCategory.bat,
              brand: 'Test',
              acquisitionType: AcquisitionType.purchased,
              acquisitionValueCents: 5000,
              sellerContactId: 'seller',
            ),
          ]),
        ),
        saleTransactionsProvider.overrideWith(
          (ref) => Stream.value([
            SaleTransaction(
              inventoryItemId: 'item-1',
              salePriceCents: 10000,
              acquisitionValueCents: 5000,
              saleDate: DateTime(2026, 4, 1),
              paymentMethod: PaymentMethod.cash,
              buyerContactId: 'buyer',
            ),
          ]),
        ),
        tradeTransactionsProvider.overrideWith(
          (ref) => Stream.value(<TradeTransaction>[]),
        ),
        consignmentTransactionsProvider.overrideWith(
          (ref) => Stream.value(<ConsignmentTransaction>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final relationships = await _nextRelationshipResult(container);

    expect(relationships.hasValue, isTrue);
    expect(relationships.requireValue['seller']?.soldToUsCount, 1);
    expect(relationships.requireValue['buyer']?.boughtFromUsCount, 1);
  });

  test('propagates a source error without returning partial totals', () async {
    final container = ProviderContainer(
      overrides: [
        inventoryItemsProvider.overrideWith(
          (ref) => Stream<List<InventoryItem>>.error(StateError('inventory')),
        ),
        saleTransactionsProvider.overrideWith(
          (ref) => Stream.value(<SaleTransaction>[]),
        ),
        tradeTransactionsProvider.overrideWith(
          (ref) => Stream.value(<TradeTransaction>[]),
        ),
        consignmentTransactionsProvider.overrideWith(
          (ref) => Stream.value(<ConsignmentTransaction>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final relationships = await _nextRelationshipResult(container);

    expect(relationships.hasError, isTrue);
    expect(relationships.error, isA<StateError>());
  });
}

Future<AsyncValue<Map<String, ContactRelationship>>> _nextRelationshipResult(
  ProviderContainer container,
) async {
  final completer = Completer<AsyncValue<Map<String, ContactRelationship>>>();
  final subscription = container.listen(contactRelationshipsProvider, (
    previous,
    next,
  ) {
    if (!next.isLoading && !completer.isCompleted) {
      completer.complete(next);
    }
  }, fireImmediately: true);

  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}
