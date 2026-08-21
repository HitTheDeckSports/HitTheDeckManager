import '../../domain/models/inventory_enums.dart';
import '../../domain/models/inventory_item.dart';

class InventoryFilterCriteria {
  const InventoryFilterCriteria({
    this.category,
    this.brand,
    this.condition,
    this.status,
    this.purchaseDateFrom,
    this.purchaseDateTo,
    this.minimumAcquisitionValueCents,
    this.maximumAcquisitionValueCents,
    this.minimumAskingPriceCents,
    this.maximumAskingPriceCents,
    this.minimumDaysInInventory,
    this.maximumDaysInInventory,
  });

  final InventoryCategory? category;
  final String? brand;
  final InventoryCondition? condition;
  final InventoryStatus? status;
  final DateTime? purchaseDateFrom;
  final DateTime? purchaseDateTo;
  final int? minimumAcquisitionValueCents;
  final int? maximumAcquisitionValueCents;
  final int? minimumAskingPriceCents;
  final int? maximumAskingPriceCents;
  final int? minimumDaysInInventory;
  final int? maximumDaysInInventory;

  bool get isActive =>
      category != null ||
      (brand != null && brand!.trim().isNotEmpty) ||
      condition != null ||
      status != null ||
      purchaseDateFrom != null ||
      purchaseDateTo != null ||
      minimumAcquisitionValueCents != null ||
      maximumAcquisitionValueCents != null ||
      minimumAskingPriceCents != null ||
      maximumAskingPriceCents != null ||
      minimumDaysInInventory != null ||
      maximumDaysInInventory != null;

  int get activeCount => [
    category,
    brand?.trim().isEmpty == false ? brand : null,
    condition,
    status,
    purchaseDateFrom,
    purchaseDateTo,
    minimumAcquisitionValueCents,
    maximumAcquisitionValueCents,
    minimumAskingPriceCents,
    maximumAskingPriceCents,
    minimumDaysInInventory,
    maximumDaysInInventory,
  ].where((value) => value != null).length;

  InventoryFilterCriteria copyWith({
    Object? category = _unset,
    Object? brand = _unset,
    Object? condition = _unset,
    Object? status = _unset,
    Object? purchaseDateFrom = _unset,
    Object? purchaseDateTo = _unset,
    Object? minimumAcquisitionValueCents = _unset,
    Object? maximumAcquisitionValueCents = _unset,
    Object? minimumAskingPriceCents = _unset,
    Object? maximumAskingPriceCents = _unset,
    Object? minimumDaysInInventory = _unset,
    Object? maximumDaysInInventory = _unset,
  }) {
    return InventoryFilterCriteria(
      category: identical(category, _unset)
          ? this.category
          : category as InventoryCategory?,
      brand: identical(brand, _unset) ? this.brand : brand as String?,
      condition: identical(condition, _unset)
          ? this.condition
          : condition as InventoryCondition?,
      status: identical(status, _unset)
          ? this.status
          : status as InventoryStatus?,
      purchaseDateFrom: identical(purchaseDateFrom, _unset)
          ? this.purchaseDateFrom
          : purchaseDateFrom as DateTime?,
      purchaseDateTo: identical(purchaseDateTo, _unset)
          ? this.purchaseDateTo
          : purchaseDateTo as DateTime?,
      minimumAcquisitionValueCents:
          identical(minimumAcquisitionValueCents, _unset)
          ? this.minimumAcquisitionValueCents
          : minimumAcquisitionValueCents as int?,
      maximumAcquisitionValueCents:
          identical(maximumAcquisitionValueCents, _unset)
          ? this.maximumAcquisitionValueCents
          : maximumAcquisitionValueCents as int?,
      minimumAskingPriceCents: identical(minimumAskingPriceCents, _unset)
          ? this.minimumAskingPriceCents
          : minimumAskingPriceCents as int?,
      maximumAskingPriceCents: identical(maximumAskingPriceCents, _unset)
          ? this.maximumAskingPriceCents
          : maximumAskingPriceCents as int?,
      minimumDaysInInventory: identical(minimumDaysInInventory, _unset)
          ? this.minimumDaysInInventory
          : minimumDaysInInventory as int?,
      maximumDaysInInventory: identical(maximumDaysInInventory, _unset)
          ? this.maximumDaysInInventory
          : maximumDaysInInventory as int?,
    );
  }
}

final class InventoryFilter {
  const InventoryFilter._();

  static List<InventoryItem> apply(
    Iterable<InventoryItem> items,
    InventoryFilterCriteria criteria, {
    DateTime? asOf,
  }) {
    if (!criteria.isActive) {
      return List<InventoryItem>.unmodifiable(items);
    }

    final referenceDate = _dateOnly(asOf ?? DateTime.now());

    return List<InventoryItem>.unmodifiable(
      items.where((item) {
        if (criteria.category != null && item.category != criteria.category) {
          return false;
        }

        final brand = criteria.brand?.trim();
        if (brand != null &&
            brand.isNotEmpty &&
            item.brand.trim().toLowerCase() != brand.toLowerCase()) {
          return false;
        }

        if (criteria.condition != null &&
            item.condition != criteria.condition) {
          return false;
        }

        if (criteria.status != null && item.status != criteria.status) {
          return false;
        }

        final purchaseDate = item.purchaseDate == null
            ? null
            : _dateOnly(item.purchaseDate!);

        if (criteria.purchaseDateFrom != null &&
            (purchaseDate == null ||
                purchaseDate.isBefore(_dateOnly(criteria.purchaseDateFrom!)))) {
          return false;
        }

        if (criteria.purchaseDateTo != null &&
            (purchaseDate == null ||
                purchaseDate.isAfter(_dateOnly(criteria.purchaseDateTo!)))) {
          return false;
        }

        if (criteria.minimumAcquisitionValueCents != null &&
            item.acquisitionValueCents <
                criteria.minimumAcquisitionValueCents!) {
          return false;
        }

        if (criteria.maximumAcquisitionValueCents != null &&
            item.acquisitionValueCents >
                criteria.maximumAcquisitionValueCents!) {
          return false;
        }

        if (criteria.minimumAskingPriceCents != null &&
            (item.askingPriceCents == null ||
                item.askingPriceCents! < criteria.minimumAskingPriceCents!)) {
          return false;
        }

        if (criteria.maximumAskingPriceCents != null &&
            (item.askingPriceCents == null ||
                item.askingPriceCents! > criteria.maximumAskingPriceCents!)) {
          return false;
        }

        if (criteria.minimumDaysInInventory != null ||
            criteria.maximumDaysInInventory != null) {
          if (purchaseDate == null) {
            return false;
          }

          final days = referenceDate.difference(purchaseDate).inDays;

          if (criteria.minimumDaysInInventory != null &&
              days < criteria.minimumDaysInInventory!) {
            return false;
          }

          if (criteria.maximumDaysInInventory != null &&
              days > criteria.maximumDaysInInventory!) {
            return false;
          }
        }

        return true;
      }),
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

const _unset = Object();
