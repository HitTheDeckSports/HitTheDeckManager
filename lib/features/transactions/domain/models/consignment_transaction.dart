class ConsignmentTransaction {
  const ConsignmentTransaction({
    required this.inventoryItemId,
    required this.consignmentDate,
    required this.commissionCents,
    this.id,
    this.consignorContactId,
    this.saleTransactionId,
    this.notes,
  });

  final String? id;
  final String inventoryItemId;
  final DateTime consignmentDate;

  /// Hit the Deck's agreed earnings when this consigned item is sold.
  final int commissionCents;

  /// Optional contact representing the owner/consignor.
  final String? consignorContactId;

  /// Populated later when the consigned inventory item is sold.
  final String? saleTransactionId;

  final String? notes;

  bool get isCompleted {
    return saleTransactionId != null && saleTransactionId!.trim().isNotEmpty;
  }

  int consignorPayoutCentsForSale(int salePriceCents) {
    if (salePriceCents < 0) {
      throw ArgumentError.value(
        salePriceCents,
        'salePriceCents',
        'Sale price cannot be negative.',
      );
    }

    if (commissionCents > salePriceCents) {
      throw StateError('Consignment commission cannot exceed the sale price.');
    }

    return salePriceCents - commissionCents;
  }

  bool get isValid {
    if (inventoryItemId.trim().isEmpty) {
      return false;
    }

    if (commissionCents < 0) {
      return false;
    }

    if (consignorContactId != null && consignorContactId!.trim().isEmpty) {
      return false;
    }

    if (saleTransactionId != null && saleTransactionId!.trim().isEmpty) {
      return false;
    }

    return true;
  }

  ConsignmentTransaction copyWith({
    Object? id = _unset,
    String? inventoryItemId,
    DateTime? consignmentDate,
    int? commissionCents,
    Object? consignorContactId = _unset,
    Object? saleTransactionId = _unset,
    Object? notes = _unset,
  }) {
    return ConsignmentTransaction(
      id: identical(id, _unset) ? this.id : id as String?,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      consignmentDate: consignmentDate ?? this.consignmentDate,
      commissionCents: commissionCents ?? this.commissionCents,
      consignorContactId: identical(consignorContactId, _unset)
          ? this.consignorContactId
          : consignorContactId as String?,
      saleTransactionId: identical(saleTransactionId, _unset)
          ? this.saleTransactionId
          : saleTransactionId as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }
}

const _unset = Object();
