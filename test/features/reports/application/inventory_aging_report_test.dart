import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/reports/application/inventory_aging_report.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';

void main() {
  test('inventory aging uses approved buckets and true cost', () {
    final report = InventoryAgingReport.calculate(
      inventoryItems: [
        InventoryItem(
          id: 'item-1',
          category: InventoryCategory.bat,
          brand: 'Combat',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 20000,
          askingPriceCents: 35000,
          purchaseDate: DateTime(2026, 8, 1),
        ),
        InventoryItem(
          id: 'item-2',
          category: InventoryCategory.glove,
          brand: 'Wilson',
          acquisitionType: AcquisitionType.purchased,
          acquisitionValueCents: 15000,
          askingPriceCents: 25000,
          purchaseDate: DateTime(2026, 6, 1),
          status: InventoryStatus.inactive,
        ),
      ],
      repairs: [
        RepairTransaction(
          inventoryItemId: 'item-1',
          repairDate: DateTime(2026, 8, 10),
          costCents: 2500,
          description: 'Grip',
        ),
      ],
      asOf: DateTime(2026, 8, 24),
    );

    final first = report.rows.firstWhere(
      (row) => row.bucket == InventoryAgingBucket.days0To30,
    );
    final third = report.rows.firstWhere(
      (row) => row.bucket == InventoryAgingBucket.days61To90,
    );
    expect(first.inventoryCostCents, 22500);
    expect(first.potentialProfitCents, 12500);
    expect(third.itemCount, 1);
  });
}
