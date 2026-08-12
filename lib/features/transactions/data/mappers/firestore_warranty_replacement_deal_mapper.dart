import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/warranty_replacement_deal.dart';

abstract final class FirestoreWarrantyReplacementDealMapper {
  static Map<String, Object?> toFirestore(
    WarrantyReplacementDeal deal, {
    bool includeCreatedAt = false,
  }) {
    final normalized = normalize(deal);

    return {
      'disposalTransactionId': normalized.disposalTransactionId,
      'disposedInventoryItemId': normalized.disposedInventoryItemId,
      'replacementInventoryItemId': normalized.replacementInventoryItemId,
      'replacementDate': Timestamp.fromDate(normalized.replacementDate),
      'notes': normalized.notes,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static WarrantyReplacementDeal fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Warranty replacement Deal document ${document.id} has no data.',
      );
    }

    return WarrantyReplacementDeal(
      id: document.id,
      disposalTransactionId: _requiredString(
        data['disposalTransactionId'],
        'disposalTransactionId',
      ),
      disposedInventoryItemId: _requiredString(
        data['disposedInventoryItemId'],
        'disposedInventoryItemId',
      ),
      replacementInventoryItemId: _requiredString(
        data['replacementInventoryItemId'],
        'replacementInventoryItemId',
      ),
      replacementDate: _requiredDate(
        data['replacementDate'],
        'replacementDate',
      ),
      notes: _stringOrNull(data['notes']),
    );
  }

  static WarrantyReplacementDeal normalize(WarrantyReplacementDeal deal) {
    return deal.copyWith(
      disposalTransactionId: deal.disposalTransactionId.trim(),
      disposedInventoryItemId: deal.disposedInventoryItemId.trim(),
      replacementInventoryItemId: deal.replacementInventoryItemId.trim(),
      notes: _emptyToNull(deal.notes),
    );
  }

  static String _requiredString(Object? value, String fieldName) {
    final result = _stringOrNull(value);

    if (result == null) {
      throw StateError(
        'Warranty replacement Deal field $fieldName is missing or invalid.',
      );
    }

    return result;
  }

  static DateTime _requiredDate(Object? value, String fieldName) {
    final result = switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => null,
    };

    if (result == null) {
      throw StateError(
        'Warranty replacement Deal field $fieldName is missing or invalid.',
      );
    }

    return result;
  }

  static String? _stringOrNull(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
