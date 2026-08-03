import 'inventory_enums.dart';

const _unset = Object();

class InventoryItem {
  const InventoryItem({
    required this.category,
    required this.brand,
    required this.acquisitionType,
    required this.acquisitionValueCents,
    this.id,
    this.inventoryNumber,
    this.model,
    this.condition,
    this.status = InventoryStatus.available,
    this.purchaseDate,
    this.newValueCents,
    this.askingPriceCents,
    this.minimumPriceCents,
    this.sellerContactId,
    this.notes,
    this.lengthInches,
    this.weightOunces,
    this.drop,
    this.certification,
    this.gloveSizeInches,
    this.handOrientation,
    this.catchersGearSize,
    this.photoUrls = const [],
  });

  /// Database identifier assigned after the item is saved.
  final String? id;

  /// Human-readable identifier generated after the item is saved.
  ///
  /// Example: BAT-2607-0001
  final String? inventoryNumber;

  final InventoryCategory category;
  final String brand;
  final String? model;
  final AcquisitionType acquisitionType;
  final InventoryCondition? condition;
  final InventoryStatus status;

  /// The value assigned to the item when it enters inventory.
  final int acquisitionValueCents;

  final DateTime? purchaseDate;
  final int? newValueCents;
  final int? askingPriceCents;
  final int? minimumPriceCents;

  /// Identifier of the contact who sold, traded, or consigned the item.
  final String? sellerContactId;

  final String? notes;

  // Bat-specific fields.
  final double? lengthInches;
  final double? weightOunces;

  /// Bat drop, calculated as weight in ounces minus length in inches.
  ///
  /// Example: a 32-inch, 29-ounce bat has a drop of -3.
  final double? drop;

  final String? certification;

  // Glove-specific fields.
  final double? gloveSizeInches;
  final String? handOrientation;

  // Catcher's gear-specific fields.
  final String? catchersGearSize;

  /// References to item photos. The application supports up to 10 photos.
  final List<String> photoUrls;

  bool get isAvailable => status == InventoryStatus.available;

  bool get isSold => status == InventoryStatus.sold;

  bool get hasAskingPrice => askingPriceCents != null;

  int? get potentialProfitCents {
    final askingPrice = askingPriceCents;

    if (askingPrice == null) {
      return null;
    }

    return askingPrice - acquisitionValueCents;
  }

  bool get isValid => validationErrors.isEmpty;

  List<String> get validationErrors {
    final errors = <String>[];

    if (brand.trim().isEmpty) {
      errors.add('Brand is required.');
    }

    if (acquisitionValueCents < 0) {
      errors.add('Acquisition value cannot be negative.');
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
      errors.add('An inventory item cannot have more than 10 photos.');
    }

    return List.unmodifiable(errors);
  }

  InventoryItem copyWith({
    Object? id = _unset,
    Object? inventoryNumber = _unset,
    InventoryCategory? category,
    String? brand,
    Object? model = _unset,
    AcquisitionType? acquisitionType,
    Object? condition = _unset,
    InventoryStatus? status,
    int? acquisitionValueCents,
    Object? purchaseDate = _unset,
    Object? newValueCents = _unset,
    Object? askingPriceCents = _unset,
    Object? minimumPriceCents = _unset,
    Object? sellerContactId = _unset,
    Object? notes = _unset,
    Object? lengthInches = _unset,
    Object? weightOunces = _unset,
    Object? drop = _unset,
    Object? certification = _unset,
    Object? gloveSizeInches = _unset,
    Object? handOrientation = _unset,
    Object? catchersGearSize = _unset,
    List<String>? photoUrls,
  }) {
    return InventoryItem(
      id: identical(id, _unset) ? this.id : id as String?,
      inventoryNumber: identical(inventoryNumber, _unset)
          ? this.inventoryNumber
          : inventoryNumber as String?,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: identical(model, _unset) ? this.model : model as String?,
      acquisitionType: acquisitionType ?? this.acquisitionType,
      condition: identical(condition, _unset)
          ? this.condition
          : condition as InventoryCondition?,
      status: status ?? this.status,
      acquisitionValueCents:
          acquisitionValueCents ?? this.acquisitionValueCents,
      purchaseDate: identical(purchaseDate, _unset)
          ? this.purchaseDate
          : purchaseDate as DateTime?,
      newValueCents: identical(newValueCents, _unset)
          ? this.newValueCents
          : newValueCents as int?,
      askingPriceCents: identical(askingPriceCents, _unset)
          ? this.askingPriceCents
          : askingPriceCents as int?,
      minimumPriceCents: identical(minimumPriceCents, _unset)
          ? this.minimumPriceCents
          : minimumPriceCents as int?,
      sellerContactId: identical(sellerContactId, _unset)
          ? this.sellerContactId
          : sellerContactId as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      lengthInches: identical(lengthInches, _unset)
          ? this.lengthInches
          : lengthInches as double?,
      weightOunces: identical(weightOunces, _unset)
          ? this.weightOunces
          : weightOunces as double?,
      drop: identical(drop, _unset) ? this.drop : drop as double?,
      certification: identical(certification, _unset)
          ? this.certification
          : certification as String?,
      gloveSizeInches: identical(gloveSizeInches, _unset)
          ? this.gloveSizeInches
          : gloveSizeInches as double?,
      handOrientation: identical(handOrientation, _unset)
          ? this.handOrientation
          : handOrientation as String?,
      catchersGearSize: identical(catchersGearSize, _unset)
          ? this.catchersGearSize
          : catchersGearSize as String?,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! InventoryItem) {
      return false;
    }

    if (id == null || other.id == null) {
      return false;
    }

    return id == other.id;
  }

  @override
  int get hashCode => id?.hashCode ?? identityHashCode(this);
}
