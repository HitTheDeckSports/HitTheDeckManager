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
    this.locationId,
    this.notes = '',
    this.lengthInches = '',
    this.weightOunces = '',
    this.drop = '',
    this.certification = '',
    this.gloveSizeInches = '',
    this.handOrientation = '',
    this.catchersGearSize = '',
    this.helmetSize = '',
    this.photoUrls = const [],
  });
  factory BuyInventoryFormState.fromInventoryItem(InventoryItem item) {
    return BuyInventoryFormState(
      category: item.category,
      brand: item.brand,
      model: item.model ?? '',
      acquisitionType: item.acquisitionType,
      acquisitionValue: _formatCentsForInput(item.acquisitionValueCents),
      condition: item.condition,
      purchaseDate: item.purchaseDate,
      newValue: _formatOptionalCentsForInput(item.newValueCents),
      askingPrice: _formatOptionalCentsForInput(item.askingPriceCents),
      minimumPrice: _formatOptionalCentsForInput(item.minimumPriceCents),
      sellerContactId: item.sellerContactId,
      locationId: item.locationId,
      notes: item.notes ?? '',
      lengthInches: _formatOptionalNumber(item.lengthInches),
      weightOunces: _formatOptionalNumber(item.weightOunces),
      drop: _formatOptionalNumber(item.drop),
      certification: item.certification ?? '',
      gloveSizeInches: _formatOptionalNumber(item.gloveSizeInches),
      handOrientation: item.handOrientation ?? '',
      catchersGearSize: item.catchersGearSize ?? '',
      helmetSize: item.helmetSize ?? '',
      photoUrls: item.photoUrls,
    );
  }
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
  final String? locationId;
  final String notes;

  final String lengthInches;
  final String weightOunces;
  final String drop;
  final String certification;

  final String gloveSizeInches;
  final String handOrientation;

  final String catchersGearSize;

  final String helmetSize;

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
      locationId: locationId,
      notes: _emptyToNull(notes),
      lengthInches: category == InventoryCategory.bat
          ? double.tryParse(lengthInches.trim())
          : null,
      weightOunces: category == InventoryCategory.bat
          ? double.tryParse(weightOunces.trim())
          : null,
      drop: category == InventoryCategory.bat
          ? double.tryParse(drop.trim())
          : null,
      certification: category == InventoryCategory.bat
          ? _emptyToNull(certification)
          : null,
      gloveSizeInches: category == InventoryCategory.glove
          ? double.tryParse(gloveSizeInches.trim())
          : null,
      handOrientation: category == InventoryCategory.glove
          ? _emptyToNull(handOrientation)
          : null,
      catchersGearSize: category == InventoryCategory.catchersGear
          ? _emptyToNull(catchersGearSize)
          : null,
      helmetSize: category == InventoryCategory.helmet
          ? _emptyToNull(helmetSize)
          : null,
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
    Object? locationId = _unset,
    String? notes,
    String? lengthInches,
    String? weightOunces,
    String? drop,
    String? certification,
    String? gloveSizeInches,
    String? handOrientation,
    String? catchersGearSize,
    String? helmetSize,
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
      locationId: identical(locationId, _unset)
          ? this.locationId
          : locationId as String?,
      notes: notes ?? this.notes,
      lengthInches: lengthInches ?? this.lengthInches,
      weightOunces: weightOunces ?? this.weightOunces,
      drop: drop ?? this.drop,
      certification: certification ?? this.certification,
      gloveSizeInches: gloveSizeInches ?? this.gloveSizeInches,
      handOrientation: handOrientation ?? this.handOrientation,
      catchersGearSize: catchersGearSize ?? this.catchersGearSize,
      helmetSize: helmetSize ?? this.helmetSize,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}

const _unset = Object();

String? _emptyToNull(String value) {
  final trimmed = value.trim();

  return trimmed.isEmpty ? null : trimmed;
}

String _formatCentsForInput(int cents) {
  return (cents / 100).toStringAsFixed(2);
}

String _formatOptionalCentsForInput(int? cents) {
  return cents == null ? '' : _formatCentsForInput(cents);
}

String _formatOptionalNumber(double? value) {
  if (value == null) {
    return '';
  }

  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
