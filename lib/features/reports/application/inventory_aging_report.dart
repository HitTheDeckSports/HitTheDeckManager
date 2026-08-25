import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/repair_transaction.dart';

enum InventoryAgingBucket {
  days0To30,
  days31To60,
  days61To90,
  days91To180,
  days181Plus,
}

extension InventoryAgingBucketLabel on InventoryAgingBucket {
  String get label => switch (this) {
    InventoryAgingBucket.days0To30 => '0-30 days',
    InventoryAgingBucket.days31To60 => '31-60 days',
    InventoryAgingBucket.days61To90 => '61-90 days',
    InventoryAgingBucket.days91To180 => '91-180 days',
    InventoryAgingBucket.days181Plus => '181+ days',
  };
}

class InventoryAgingRow {
  const InventoryAgingRow({
    required this.bucket,
    required this.itemCount,
    required this.inventoryCostCents,
    required this.askingValueCents,
    required this.potentialProfitCents,
    required this.inventoryItemIds,
  });

  final InventoryAgingBucket bucket;
  final int itemCount;
  final int inventoryCostCents;
  final int askingValueCents;
  final int potentialProfitCents;
  final List<String> inventoryItemIds;
}

class InventoryAgingReport {
  const InventoryAgingReport({
    required this.rows,
    required this.unclassifiedItemIds,
  });

  final List<InventoryAgingRow> rows;
  final List<String> unclassifiedItemIds;

  factory InventoryAgingReport.calculate({
    required List<InventoryItem> inventoryItems,
    required List<RepairTransaction> repairs,
    required DateTime asOf,
  }) {
    final repairCostByItemId = <String, int>{};
    for (final repair in repairs) {
      repairCostByItemId.update(
        repair.inventoryItemId,
        (value) => value + repair.costCents,
        ifAbsent: () => repair.costCents,
      );
    }

    final rows = <InventoryAgingBucket, _MutableAgingRow>{
      for (final bucket in InventoryAgingBucket.values)
        bucket: _MutableAgingRow(),
    };
    final unclassified = <String>[];
    final asOfDate = DateTime(asOf.year, asOf.month, asOf.day);

    for (final item in inventoryItems) {
      if (!_isOpen(item.status)) continue;
      final itemId = item.id;
      final purchaseDate = item.purchaseDate;
      if (purchaseDate == null) {
        if (itemId != null) unclassified.add(itemId);
        continue;
      }

      final purchaseDateOnly = DateTime(
        purchaseDate.year,
        purchaseDate.month,
        purchaseDate.day,
      );
      final rawDays = asOfDate.difference(purchaseDateOnly).inDays;
      final days = rawDays < 0 ? 0 : rawDays;
      final bucket = _bucketFor(days);
      final row = rows[bucket]!;
      final repairCost = itemId == null ? 0 : repairCostByItemId[itemId] ?? 0;
      final trueCost = item.acquisitionValueCents + repairCost;
      final asking = item.askingPriceCents ?? 0;
      row.itemCount += 1;
      row.inventoryCostCents += trueCost;
      row.askingValueCents += asking;
      row.potentialProfitCents += asking - trueCost;
      if (itemId != null) row.inventoryItemIds.add(itemId);
    }

    return InventoryAgingReport(
      rows: [
        for (final bucket in InventoryAgingBucket.values)
          InventoryAgingRow(
            bucket: bucket,
            itemCount: rows[bucket]!.itemCount,
            inventoryCostCents: rows[bucket]!.inventoryCostCents,
            askingValueCents: rows[bucket]!.askingValueCents,
            potentialProfitCents: rows[bucket]!.potentialProfitCents,
            inventoryItemIds: List.unmodifiable(rows[bucket]!.inventoryItemIds),
          ),
      ],
      unclassifiedItemIds: List.unmodifiable(unclassified),
    );
  }

  static bool _isOpen(InventoryStatus status) => switch (status) {
    InventoryStatus.available => true,
    InventoryStatus.inactive => true,
    InventoryStatus.broken => true,
    InventoryStatus.sold => false,
    InventoryStatus.disposed => false,
  };

  static InventoryAgingBucket _bucketFor(int days) {
    if (days <= 30) return InventoryAgingBucket.days0To30;
    if (days <= 60) return InventoryAgingBucket.days31To60;
    if (days <= 90) return InventoryAgingBucket.days61To90;
    if (days <= 180) return InventoryAgingBucket.days91To180;
    return InventoryAgingBucket.days181Plus;
  }
}

class _MutableAgingRow {
  int itemCount = 0;
  int inventoryCostCents = 0;
  int askingValueCents = 0;
  int potentialProfitCents = 0;
  final inventoryItemIds = <String>[];
}
