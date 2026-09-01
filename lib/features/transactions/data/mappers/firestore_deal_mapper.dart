import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/deal.dart';

abstract final class FirestoreDealMapper {
  static Map<String, Object?> toFirestore(
    Deal deal, {
    bool includeCreatedAt = false,
  }) {
    final normalized = normalize(deal);

    return {
      'parentSaleTransactionId': normalized.parentSaleTransactionId,
      'childInventoryItemIds': normalized.childInventoryItemIds,
      'lineageInventoryItemIds': normalized.lineageInventoryItemIds,
      'notes': normalized.notes,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Deal fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    if (data == null) {
      throw StateError('Deal document ${document.id} does not contain data.');
    }

    final childInventoryItemIds = _requiredStringList(
      data['childInventoryItemIds'],
    );
    final lineageInventoryItemIds =
        _stringListOrNull(data['lineageInventoryItemIds']) ??
        childInventoryItemIds;

    return Deal(
      id: document.id,
      parentSaleTransactionId: _requiredString(data['parentSaleTransactionId']),
      childInventoryItemIds: childInventoryItemIds,
      lineageInventoryItemIds: lineageInventoryItemIds,
      notes: _stringOrNull(data['notes']),
    );
  }

  static Deal normalize(Deal deal) {
    final childInventoryItemIds = List<String>.unmodifiable(
      deal.childInventoryItemIds
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
    final requestedLineageInventoryItemIds = List<String>.unmodifiable(
      deal.lineageInventoryItemIds
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );

    return deal.copyWith(
      parentSaleTransactionId: deal.parentSaleTransactionId.trim(),
      childInventoryItemIds: childInventoryItemIds,
      lineageInventoryItemIds: requestedLineageInventoryItemIds.isEmpty
          ? childInventoryItemIds
          : requestedLineageInventoryItemIds,
      notes: _emptyToNull(deal.notes),
    );
  }

  static String _requiredString(Object? value) {
    final result = _stringOrNull(value);

    if (result == null) {
      throw StateError('A required Deal field is missing or invalid.');
    }

    return result;
  }

  static List<String> _requiredStringList(Object? value) {
    if (value is! Iterable) {
      throw StateError('Deal child inventory IDs are missing or invalid.');
    }

    final values = value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    if (values.isEmpty) {
      throw StateError('Deal child inventory IDs are missing or invalid.');
    }

    return List<String>.unmodifiable(values);
  }

  static List<String>? _stringListOrNull(Object? value) {
    if (value is! Iterable) {
      return null;
    }

    final values = value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    return values.isEmpty ? null : List<String>.unmodifiable(values);
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
