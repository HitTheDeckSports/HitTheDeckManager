import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/reports/application/report_date_range.dart';
import 'package:hit_the_deck_manager/features/reports/application/reports_snapshot.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  test('reports snapshot builds all report areas from one source set', () {
    const item = InventoryItem(
      id: 'item-1',
      category: InventoryCategory.bat,
      brand: 'Easton',
      model: 'Hype Fire',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 10000,
      status: InventoryStatus.sold,
    );
    final sale = SaleTransaction(
      id: 'sale-1',
      inventoryItemId: 'item-1',
      salePriceCents: 20000,
      saleDate: DateTime(2026, 8, 20),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 10000,
    );
    final snapshot = ReportsSnapshot.calculate(
      inventoryItems: const [item],
      sales: [sale],
      repairs: const [],
      deals: const [],
      asOf: DateTime(2026, 8, 24),
      dateRange: ReportDateRange.forPreset(
        ReportDateRangePreset.monthToDate,
        asOf: DateTime(2026, 8, 24),
      ),
    );

    expect(snapshot.financialPerformance.revenueCents, 20000);
    expect(snapshot.salesByCategory.rows.single.label, 'Bat');
    expect(snapshot.salesByBrand.rows.single.label, 'Easton');
    expect(snapshot.salesByModel.rows.single.label, 'Hype Fire');
    expect(snapshot.deals.rows, isEmpty);
  });
}
