import '../../../inventory/domain/models/inventory_enums.dart';

class IncomingTradeItemDraft {
  const IncomingTradeItemDraft({
    this.category = InventoryCategory.bat,
    this.brand = '',
    this.model,
    this.condition,
    this.acquisitionValueCents = 0,
  });

  final InventoryCategory category;
  final String brand;
  final String? model;
  final InventoryCondition? condition;
  final int acquisitionValueCents;

  bool get isValid {
    return brand.trim().isNotEmpty && acquisitionValueCents >= 0;
  }

  IncomingTradeItemDraft copyWith({
    InventoryCategory? category,
    String? brand,
    Object? model = _unset,
    Object? condition = _unset,
    int? acquisitionValueCents,
  }) {
    return IncomingTradeItemDraft(
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: identical(model, _unset) ? this.model : model as String?,
      condition: identical(condition, _unset)
          ? this.condition
          : condition as InventoryCondition?,
      acquisitionValueCents:
          acquisitionValueCents ?? this.acquisitionValueCents,
    );
  }
}

const _unset = Object();
