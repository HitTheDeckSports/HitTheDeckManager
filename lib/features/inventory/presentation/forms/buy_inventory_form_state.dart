import '../../../../core/formatting/currency_formatter.dart';
import '../../domain/models/inventory_enums.dart';
import '../../domain/models/inventory_item.dart';

class BuyInventoryFormState {
  const BuyInventoryFormState({
    this.category = InventoryCategory.bat,
    this.brand = '',
    this.model = '',
    this.acquisitionType = AcquisitionType.purchased,
    this.acquisitionValue = '',
    this.condition,
    this.purchaseDate,
    this.newValue = '',
    this.askingPrice = '',
    this.minimumPrice = '',
    this.sellerContactId,
    this.notes = '',
    this.lengthInches = '',
    this.weightOunces = '',
    this.certification = '',
    this.gloveSizeInches = '',
    this.handOrientation = '',
    this.catchersGearSize = '',
    this.photoUrls = const [],
  });

  final InventoryCategory category;
  final String brand;
  final String model;
  final AcquisitionType acquisitionType;
  final String acquisitionValue;
  final InventoryCondition? condition;
  final DateTime? purchaseDate;
  final String newValue;
  final String askingPrice;
  final String minimumPrice;
  final String? sellerContactId;
  final String notes;

  final String lengthInches;
  final String weightOunces;
  final String certification;

  final String gloveSizeInches;
  final String handOrientation;

  final String catchersGearSize;

  final List<String> photoUrls;

  InventoryItem? toInventoryItem() {
    final acquisitionValueCents = CurrencyFormatter.tryParseToCents(
      acquisitionValue,
    );

    if (acquisitionValueCents == null) {
      return null;
    }

    final item = InventoryItem(
      category: category,
      brand: brand.trim(),
      model: _emptyToNull(model),
      acquisitionType: acquisitionType,
      acquisitionValueCents: acquisitionValueCents,
      condition: condition,
      purchaseDate: purchaseDate,
      newValueCents: CurrencyFormatter.tryParseToCents(newValue),
      askingPriceCents: CurrencyFormatter.tryParseToCents(askingPrice),
      minimumPriceCents: CurrencyFormatter.tryParseToCents(minimumPrice),
      sellerContactId: sellerContactId,
      notes: _emptyToNull(notes),
      lengthInches: double.tryParse(lengthInches.trim()),
      weightOunces: double.tryParse(weightOunces.trim()),
      certification: _emptyToNull(certification),
      gloveSizeInches: double.tryParse(gloveSizeInches.trim()),
      handOrientation: _emptyToNull(handOrientation),
      catchersGearSize: _emptyToNull(catchersGearSize),
      photoUrls: photoUrls,
    );

    return item.isValid ? item : null;
  }

  BuyInventoryFormState copyWith({
    InventoryCategory? category,
    String? brand,
    String? model,
    AcquisitionType? acquisitionType,
    String? acquisitionValue,
    Object? condition = _unset,
    Object? purchaseDate = _unset,
    String? newValue,
    String? askingPrice,
    String? minimumPrice,
    Object? sellerContactId = _unset,
    String? notes,
    String? lengthInches,
    String? weightOunces,
    String? certification,
    String? gloveSizeInches,
    String? handOrientation,
    String? catchersGearSize,
    List<String>? photoUrls,
  }) {
    return BuyInventoryFormState(
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      acquisitionType: acquisitionType ?? this.acquisitionType,
      acquisitionValue: acquisitionValue ?? this.acquisitionValue,
      condition: identical(condition, _unset)
          ? this.condition
          : condition as InventoryCondition?,
      purchaseDate: identical(purchaseDate, _unset)
          ? this.purchaseDate
          : purchaseDate as DateTime?,
      newValue: newValue ?? this.newValue,
      askingPrice: askingPrice ?? this.askingPrice,
      minimumPrice: minimumPrice ?? this.minimumPrice,
      sellerContactId: identical(sellerContactId, _unset)
          ? this.sellerContactId
          : sellerContactId as String?,
      notes: notes ?? this.notes,
      lengthInches: lengthInches ?? this.lengthInches,
      weightOunces: weightOunces ?? this.weightOunces,
      certification: certification ?? this.certification,
      gloveSizeInches: gloveSizeInches ?? this.gloveSizeInches,
      handOrientation: handOrientation ?? this.handOrientation,
      catchersGearSize: catchersGearSize ?? this.catchersGearSize,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}

const _unset = Object();

String? _emptyToNull(String value) {
  final trimmed = value.trim();

  return trimmed.isEmpty ? null : trimmed;
}
