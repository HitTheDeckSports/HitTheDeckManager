import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/reports/application/report_date_range.dart';
import 'package:hit_the_deck_manager/features/reports/application/sales_analysis_report.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  test('sales analysis groups category brand and model', () {
    final inventory = [
      const InventoryItem(
        id: 'item-1',
        category: InventoryCategory.bat,
        brand: 'Easton',
        model: 'Hype Fire',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 10000,
      ),
      const InventoryItem(
        id: 'item-2',
        category: InventoryCategory.bat,
        brand: 'Easton',
        model: 'Icon',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 12000,
      ),
    ];
    final sales = [
      SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 20000,
        saleDate: DateTime(2026, 8, 20),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 10000,
      ),
      SaleTransaction(
        inventoryItemId: 'item-2',
        salePriceCents: 25000,
        saleDate: DateTime(2026, 8, 21),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 12000,
      ),
    ];
    final range = ReportDateRange.forPreset(
      ReportDateRangePreset.monthToDate,
      asOf: DateTime(2026, 8, 24),
    );

    final byCategory = SalesAnalysisReport.calculate(
      dimension: SalesAnalysisDimension.category,
      inventoryItems: inventory,
      sales: sales,
      dateRange: range,
    );
    final byBrand = SalesAnalysisReport.calculate(
      dimension: SalesAnalysisDimension.brand,
      inventoryItems: inventory,
      sales: sales,
      dateRange: range,
    );
    final byModel = SalesAnalysisReport.calculate(
      dimension: SalesAnalysisDimension.model,
      inventoryItems: inventory,
      sales: sales,
      dateRange: range,
    );

    expect(byCategory.rows.single.label, 'Bat');
    expect(byCategory.rows.single.units, 2);
    expect(byBrand.rows.single.revenueCents, 45000);
    expect(byModel.rows, hasLength(2));
  });
}
