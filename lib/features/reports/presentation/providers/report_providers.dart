import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/reports/application/report_date_range.dart';
import 'package:hit_the_deck_manager/features/reports/application/reports_snapshot.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

final reportAsOfProvider = Provider<DateTime>((ref) => DateTime.now());

final reportDateRangeSelectionProvider =
    NotifierProvider<
      ReportDateRangeSelectionController,
      ReportDateRangeSelection
    >(ReportDateRangeSelectionController.new);

class ReportDateRangeSelectionController
    extends Notifier<ReportDateRangeSelection> {
  @override
  ReportDateRangeSelection build() =>
      const ReportDateRangeSelection.monthToDate();

  void selectPreset(ReportDateRangePreset preset) {
    state = ReportDateRangeSelection.preset(preset);
  }

  void selectCustom({required DateTime startDate, required DateTime endDate}) {
    state = ReportDateRangeSelection.custom(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

final reportDealMaxDepthProvider = Provider<int>((ref) => 10);

final reportsSnapshotProvider = Provider<AsyncValue<ReportsSnapshot>>((ref) {
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  final salesAsync = ref.watch(saleTransactionsProvider);
  final repairsAsync = ref.watch(repairTransactionsProvider);
  final dealsAsync = ref.watch(dealsProvider);
  final asOf = ref.watch(reportAsOfProvider);
  final selection = ref.watch(reportDateRangeSelectionProvider);
  final maxDepth = ref.watch(reportDealMaxDepthProvider);
  final dateRange = selection.resolve(asOf: asOf);

  return inventoryAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (inventoryItems) => salesAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      data: (sales) => repairsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        data: (repairs) => dealsAsync.when(
          loading: () => const AsyncValue.loading(),
          error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
          data: (deals) => AsyncValue.data(
            ReportsSnapshot.calculate(
              inventoryItems: inventoryItems,
              sales: sales,
              repairs: repairs,
              deals: deals,
              asOf: asOf,
              dateRange: dateRange,
              dealMaxDepth: maxDepth,
            ),
          ),
        ),
      ),
    ),
  );
});
