import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/inventory_enums.dart';
import '../../domain/models/inventory_item.dart';

abstract final class FirestoreInventoryMapper {
  static Map<String, Object?> toFirestore(
    InventoryItem item, {
    bool includeCreatedAt = false,
  }) {
    return {
      'inventoryNumber': item.inventoryNumber,
      'category': item.category.name,
      'brand': item.brand.trim(),
      'model': item.model,
      'acquisitionType': item.acquisitionType.name,
      'condition': item.condition?.name,
      'status': item.status.name,
      'acquisitionValueCents': item.acquisitionValueCents,
      'purchaseDate': item.purchaseDate == null
          ? null
          : Timestamp.fromDate(item.purchaseDate!),
      'newValueCents': item.newValueCents,
      'askingPriceCents': item.askingPriceCents,
      'minimumPriceCents': item.minimumPriceCents,
      'sellerContactId': item.sellerContactId,
      'notes': item.notes,
      'lengthInches': item.lengthInches,
      'weightOunces': item.weightOunces,
      'drop': item.drop,
      'certification': item.certification,
      'gloveSizeInches': item.gloveSizeInches,
      'handOrientation': item.handOrientation,
      'catchersGearSize': item.catchersGearSize,
      'helmetSize': item.helmetSize,
      'photoUrls': item.photoUrls,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static InventoryItem fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Inventory document ${document.id} does not contain data.',
      );
    }

    return InventoryItem(
      id: document.id,
      inventoryNumber: _stringOrNull(data['inventoryNumber']),
      category: _parseEnum(
        data['category'],
        InventoryCategory.values,
        InventoryCategory.other,
      ),
      brand: _stringOrNull(data['brand']) ?? '',
      model: _stringOrNull(data['model']),
      acquisitionType: _parseEnum(
        data['acquisitionType'],
        AcquisitionType.values,
        AcquisitionType.purchased,
      ),
      condition: _parseNullableEnum(
        data['condition'],
        InventoryCondition.values,
      ),
      status: _parseEnum(
        data['status'],
        InventoryStatus.values,
        InventoryStatus.available,
      ),
      acquisitionValueCents: _intValue(data['acquisitionValueCents']) ?? 0,
      purchaseDate: _dateTimeOrNull(data['purchaseDate']),
      newValueCents: _intValue(data['newValueCents']),
      askingPriceCents: _intValue(data['askingPriceCents']),
      minimumPriceCents: _intValue(data['minimumPriceCents']),
      sellerContactId: _stringOrNull(data['sellerContactId']),
      notes: _stringOrNull(data['notes']),
      lengthInches: _doubleValue(data['lengthInches']),
      weightOunces: _doubleValue(data['weightOunces']),
      drop: _doubleValue(data['drop']),
      certification: _stringOrNull(data['certification']),
      gloveSizeInches: _doubleValue(data['gloveSizeInches']),
      handOrientation: _stringOrNull(data['handOrientation']),
      catchersGearSize: _stringOrNull(data['catchersGearSize']),
      helmetSize: _stringOrNull(data['helmetSize']),
      photoUrls: _stringList(data['photoUrls']),
    );
  }

  static T _parseEnum<T extends Enum>(
    Object? rawValue,
    List<T> values,
    T fallback,
  ) {
    final name = _stringOrNull(rawValue);

    if (name == null) {
      return fallback;
    }

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return fallback;
  }

  static T? _parseNullableEnum<T extends Enum>(
    Object? rawValue,
    List<T> values,
  ) {
    final name = _stringOrNull(rawValue);

    if (name == null) {
      return null;
    }

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return null;
  }

  static String? _stringOrNull(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _intValue(Object? value) {
    return switch (value) {
      int intValue => intValue,
      num numberValue => numberValue.toInt(),
      _ => null,
    };
  }

  static double? _doubleValue(Object? value) {
    return switch (value) {
      double doubleValue => doubleValue,
      num numberValue => numberValue.toDouble(),
      _ => null,
    };
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => null,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }

    return List<String>.unmodifiable(value.whereType<String>());
  }
}
