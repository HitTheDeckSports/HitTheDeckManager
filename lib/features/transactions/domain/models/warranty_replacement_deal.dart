class WarrantyReplacementDeal {
  const WarrantyReplacementDeal({
    required this.disposalTransactionId,
    required this.disposedInventoryItemId,
    required this.replacementInventoryItemId,
    required this.replacementDate,
    this.id,
    this.notes,
  });

  final String? id;
  final String disposalTransactionId;
  final String disposedInventoryItemId;
  final String replacementInventoryItemId;
  final DateTime replacementDate;
  final String? notes;

  bool get isValid {
    final disposalId = disposalTransactionId.trim();
    final disposedId = disposedInventoryItemId.trim();
    final replacementId = replacementInventoryItemId.trim();

    return disposalId.isNotEmpty &&
        disposedId.isNotEmpty &&
        replacementId.isNotEmpty &&
        disposedId != replacementId;
  }

  WarrantyReplacementDeal copyWith({
    Object? id = _unset,
    String? disposalTransactionId,
    String? disposedInventoryItemId,
    String? replacementInventoryItemId,
    DateTime? replacementDate,
    Object? notes = _unset,
  }) {
    return WarrantyReplacementDeal(
      id: identical(id, _unset) ? this.id : id as String?,
      disposalTransactionId:
          disposalTransactionId ?? this.disposalTransactionId,
      disposedInventoryItemId:
          disposedInventoryItemId ?? this.disposedInventoryItemId,
      replacementInventoryItemId:
          replacementInventoryItemId ?? this.replacementInventoryItemId,
      replacementDate: replacementDate ?? this.replacementDate,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }
}

const _unset = Object();
