import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/reports/application/financial_performance_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/report_date_range.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  test('financial performance uses total cost basis and selected range', () {
    final report = FinancialPerformanceReport.calculate(
      sales: [
        SaleTransaction(
          id: 'sale-1',
          inventoryItemId: 'item-1',
          salePriceCents: 30000,
          saleDate: DateTime(2026, 8, 20),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 18000,
          repairCostCents: 2000,
        ),
        SaleTransaction(
          id: 'sale-2',
          inventoryItemId: 'item-2',
          salePriceCents: 20000,
          saleDate: DateTime(2026, 7, 31),
          paymentMethod: PaymentMethod.cash,
          acquisitionValueCents: 10000,
        ),
      ],
      dateRange: ReportDateRange.forPreset(
        ReportDateRangePreset.monthToDate,
        asOf: DateTime(2026, 8, 24),
      ),
    );

    expect(report.revenueCents, 30000);
    expect(report.costCents, 20000);
    expect(report.profitCents, 10000);
    expect(report.unitsSold, 1);
    expect(report.saleIds, ['sale-1']);
  });
}
