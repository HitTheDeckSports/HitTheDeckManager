import '../../../inventory/domain/models/inventory_enums.dart';
import '../../../inventory/domain/models/inventory_item.dart';

class WarrantyReplacementInventoryDraft {
  const WarrantyReplacementInventoryDraft({
    required this.category,
    required this.brand,
    this.model,
    this.condition,
    this.newValueCents,
    this.askingPriceCents,
    this.minimumPriceCents,
    this.locationId,
    this.notes,
    this.lengthInches,
    this.weightOunces,
    this.drop,
    this.certification,
    this.gloveSizeInches,
    this.handOrientation,
    this.catchersGearSize,
    this.helmetSize,
    this.photoUrls = const [],
  });

  final InventoryCategory category;
  final String brand;
  final String? model;
  final InventoryCondition? condition;
  final int? newValueCents;
  final int? askingPriceCents;
  final int? minimumPriceCents;
  final String? locationId;
  final String? notes;

  final double? lengthInches;
  final double? weightOunces;
  final double? drop;
  final String? certification;

  final double? gloveSizeInches;
  final String? handOrientation;
  final String? catchersGearSize;
  final String? helmetSize;

  /// These must be newly selected/uploaded replacement photos. The old item's
  /// photos are never supplied automatically by this data contract.
  final List<String> photoUrls;

  bool get isValid => validationErrors.isEmpty;

  List<String> get validationErrors {
    final errors = <String>[];

    if (brand.trim().isEmpty) {
      errors.add('Brand is required.');
    }

    if (newValueCents != null && newValueCents! < 0) {
      errors.add('New value cannot be negative.');
    }

    if (askingPriceCents != null && askingPriceCents! < 0) {
      errors.add('Asking price cannot be negative.');
    }

    if (minimumPriceCents != null && minimumPriceCents! < 0) {
      errors.add('Minimum price cannot be negative.');
    }

    if (askingPriceCents != null &&
        minimumPriceCents != null &&
        minimumPriceCents! > askingPriceCents!) {
      errors.add('Minimum price cannot exceed asking price.');
    }

    if (photoUrls.length > 10) {
      errors.add('A replacement item cannot have more than 10 photos.');
    }

    return List<String>.unmodifiable(errors);
  }

  InventoryItem toInventoryItem({
    required AcquisitionType carriedAcquisitionType,
    required int carriedAcquisitionValueCents,
    required DateTime replacementDate,
  }) {
    if (!isValid) {
      throw StateError(validationErrors.join(' '));
    }

    return InventoryItem(
      category: category,
      brand: brand.trim(),
      model: _optionalText(model),
      acquisitionType: carriedAcquisitionType,
      acquisitionValueCents: carriedAcquisitionValueCents,
      condition: condition,
      status: InventoryStatus.available,
      purchaseDate: replacementDate,
      newValueCents: newValueCents,
      askingPriceCents: askingPriceCents,
      minimumPriceCents: minimumPriceCents,
      locationId: _optionalText(locationId),
      notes: _optionalText(notes),
      lengthInches: lengthInches,
      weightOunces: weightOunces,
      drop: drop,
      certification: _optionalText(certification),
      gloveSizeInches: gloveSizeInches,
      handOrientation: _optionalText(handOrientation),
      catchersGearSize: _optionalText(catchersGearSize),
      helmetSize: _optionalText(helmetSize),
      photoUrls: List<String>.unmodifiable(photoUrls),
    );
  }
}

String? _optionalText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
