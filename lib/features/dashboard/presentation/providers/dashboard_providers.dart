import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_metrics.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

final dashboardAsOfProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  final salesAsync = ref.watch(saleTransactionsProvider);
  final asOf = ref.watch(dashboardAsOfProvider);

  return inventoryAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (inventoryItems) {
      return salesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        data: (saleTransactions) {
          return AsyncValue.data(
            DashboardMetrics.calculate(
              inventoryItems: inventoryItems,
              saleTransactions: saleTransactions,
              asOf: asOf,
            ),
          );
        },
      );
    },
  );
});
