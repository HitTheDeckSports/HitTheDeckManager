import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_date_range.dart';
import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_metrics.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

final dashboardAsOfProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

final dashboardDateRangeSelectionProvider =
    NotifierProvider<
      DashboardDateRangeSelectionController,
      DashboardDateRangeSelection
    >(DashboardDateRangeSelectionController.new);

class DashboardDateRangeSelectionController
    extends Notifier<DashboardDateRangeSelection> {
  @override
  DashboardDateRangeSelection build() {
    return const DashboardDateRangeSelection.monthToDate();
  }

  void selectPreset(DashboardDateRangePreset preset) {
    state = DashboardDateRangeSelection.preset(preset);
  }

  void selectCustom({required DateTime startDate, required DateTime endDate}) {
    state = DashboardDateRangeSelection.custom(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  final salesAsync = ref.watch(saleTransactionsProvider);
  final repairsAsync = ref.watch(repairTransactionsProvider);
  final asOf = ref.watch(dashboardAsOfProvider);
  final rangeSelection = ref.watch(dashboardDateRangeSelectionProvider);
  final dateRange = rangeSelection.resolve(asOf: asOf);

  return inventoryAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (inventoryItems) {
      return salesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        data: (saleTransactions) {
          return repairsAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
            data: (repairTransactions) {
              return AsyncValue.data(
                DashboardMetrics.calculate(
                  inventoryItems: inventoryItems,
                  saleTransactions: saleTransactions,
                  repairTransactions: repairTransactions,
                  asOf: asOf,
                  dateRange: dateRange,
                ),
              );
            },
          );
        },
      );
    },
  );
});
