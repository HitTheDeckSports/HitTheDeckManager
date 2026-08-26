import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../application/contact_relationship.dart';

final contactRelationshipsProvider =
    Provider<AsyncValue<Map<String, ContactRelationship>>>((ref) {
      final inventoryAsync = ref.watch(inventoryItemsProvider);
      final salesAsync = ref.watch(saleTransactionsProvider);
      final tradesAsync = ref.watch(tradeTransactionsProvider);
      final consignmentsAsync = ref.watch(consignmentTransactionsProvider);
      final values = <AsyncValue<Object?>>[
        inventoryAsync,
        salesAsync,
        tradesAsync,
        consignmentsAsync,
      ];

      if (values.any((value) => value.isLoading)) {
        return const AsyncLoading();
      }

      for (final value in values) {
        if (value.hasError) {
          return AsyncError(value.error!, value.stackTrace ?? StackTrace.empty);
        }
      }

      final inventory = inventoryAsync.requireValue;
      final sales = salesAsync.requireValue;
      final trades = tradesAsync.requireValue;
      final consignments = consignmentsAsync.requireValue;
      final rawContactIds = <String?>{
        ...inventory.map((item) => item.sellerContactId),
        ...sales.map((sale) => sale.buyerContactId),
        ...trades.map((trade) => trade.contactId),
        ...consignments.map((consignment) => consignment.consignorContactId),
      };
      final contactIds = rawContactIds
          .whereType<String>()
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty);

      return AsyncData(
        Map.unmodifiable({
          for (final contactId in contactIds)
            contactId: buildContactRelationship(
              contactId: contactId,
              inventory: inventory,
              sales: sales,
              trades: trades,
              consignments: consignments,
            ),
        }),
      );
    });
