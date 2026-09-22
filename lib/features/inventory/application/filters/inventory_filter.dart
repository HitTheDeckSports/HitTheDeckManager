import '../../domain/models/inventory_enums.dart';
import '../../domain/models/inventory_item.dart';

class InventoryFilterCriteria {
  const InventoryFilterCriteria({
    this.category,
    this.brand,
    this.condition,
    this.status,
    this.selectedCategories = const <InventoryCategory>{},
    this.selectedBrands = const <String>{},
    this.selectedConditions = const <InventoryCondition>{},
    this.selectedStatuses = const <InventoryStatus>{},
    this.selectedLocationIds = const <String>{},
    this.includeUnassignedLocation = false,
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
  // Singular fields are retained for compatibility with existing callers.
  // New UI code uses selectedConditions / selectedStatuses for multi-select.
  final InventoryCondition? condition;
  final InventoryStatus? status;
  final Set<InventoryCategory> selectedCategories;
  final Set<String> selectedBrands;
  final Set<InventoryCondition> selectedConditions;
  final Set<InventoryStatus> selectedStatuses;
  final Set<String> selectedLocationIds;
  final bool includeUnassignedLocation;
  final DateTime? purchaseDateFrom;
  final DateTime? purchaseDateTo;
  final int? minimumAcquisitionValueCents;
  final int? maximumAcquisitionValueCents;
  final int? minimumAskingPriceCents;
  final int? maximumAskingPriceCents;
  final int? minimumDaysInInventory;
  final int? maximumDaysInInventory;

  bool get hasLocationFilter =>
      selectedLocationIds.isNotEmpty || includeUnassignedLocation;

  bool get isActive =>
      category != null ||
      selectedCategories.isNotEmpty ||
      (brand != null && brand!.trim().isNotEmpty) ||
      selectedBrands.isNotEmpty ||
      condition != null ||
      selectedConditions.isNotEmpty ||
      status != null ||
      selectedStatuses.isNotEmpty ||
      hasLocationFilter ||
      purchaseDateFrom != null ||
      purchaseDateTo != null ||
      minimumAcquisitionValueCents != null ||
      maximumAcquisitionValueCents != null ||
      minimumAskingPriceCents != null ||
      maximumAskingPriceCents != null ||
      minimumDaysInInventory != null ||
      maximumDaysInInventory != null;

  int get activeCount => [
    category != null || selectedCategories.isNotEmpty ? true : null,
    (brand?.trim().isEmpty == false) || selectedBrands.isNotEmpty ? true : null,
    condition != null || selectedConditions.isNotEmpty ? true : null,
    status != null || selectedStatuses.isNotEmpty ? true : null,
    hasLocationFilter ? true : null,
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
    Object? selectedCategories = _unset,
    Object? selectedBrands = _unset,
    Object? selectedConditions = _unset,
    Object? selectedStatuses = _unset,
    Object? selectedLocationIds = _unset,
    bool? includeUnassignedLocation,
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
      selectedCategories: identical(selectedCategories, _unset)
          ? this.selectedCategories
          : Set<InventoryCategory>.unmodifiable(
              selectedCategories as Set<InventoryCategory>,
            ),
      selectedBrands: identical(selectedBrands, _unset)
          ? this.selectedBrands
          : Set<String>.unmodifiable(selectedBrands as Set<String>),
      selectedConditions: identical(selectedConditions, _unset)
          ? this.selectedConditions
          : Set<InventoryCondition>.unmodifiable(
              selectedConditions as Set<InventoryCondition>,
            ),
      selectedStatuses: identical(selectedStatuses, _unset)
          ? this.selectedStatuses
          : Set<InventoryStatus>.unmodifiable(
              selectedStatuses as Set<InventoryStatus>,
            ),
      selectedLocationIds: identical(selectedLocationIds, _unset)
          ? this.selectedLocationIds
          : Set<String>.unmodifiable(selectedLocationIds as Set<String>),
      includeUnassignedLocation:
          includeUnassignedLocation ?? this.includeUnassignedLocation,
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
        if (criteria.selectedCategories.isNotEmpty) {
          if (!criteria.selectedCategories.contains(item.category)) {
            return false;
          }
        } else if (criteria.category != null &&
            item.category != criteria.category) {
          return false;
        }

        if (criteria.selectedBrands.isNotEmpty) {
          final normalizedBrands = criteria.selectedBrands
              .map((value) => value.trim().toLowerCase())
              .where((value) => value.isNotEmpty)
              .toSet();
          if (!normalizedBrands.contains(item.brand.trim().toLowerCase())) {
            return false;
          }
        } else {
          final brand = criteria.brand?.trim();
          if (brand != null &&
              brand.isNotEmpty &&
              item.brand.trim().toLowerCase() != brand.toLowerCase()) {
            return false;
          }
        }

        if (criteria.selectedConditions.isNotEmpty) {
          if (item.condition == null ||
              !criteria.selectedConditions.contains(item.condition)) {
            return false;
          }
        } else if (criteria.condition != null &&
            item.condition != criteria.condition) {
          return false;
        }

        if (criteria.selectedStatuses.isNotEmpty) {
          if (!criteria.selectedStatuses.contains(item.status)) {
            return false;
          }
        } else if (criteria.status != null && item.status != criteria.status) {
          return false;
        }

        if (criteria.hasLocationFilter) {
          final locationId = item.locationId?.trim();
          final isUnassigned = locationId == null || locationId.isEmpty;
          final locationMatches = isUnassigned
              ? criteria.includeUnassignedLocation
              : criteria.selectedLocationIds.contains(locationId);

          if (!locationMatches) {
            return false;
          }
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
