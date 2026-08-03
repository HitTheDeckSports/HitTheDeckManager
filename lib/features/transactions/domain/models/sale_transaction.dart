import 'transaction_enums.dart';

class SaleTransaction {
  const SaleTransaction({
    this.id,
    required this.inventoryItemId,
    required this.salePriceCents,
    required this.saleDate,
    required this.paymentMethod,
    this.buyerContactId,
    this.notes,
    this.acquisitionValueCents,
  });

  final String? id;
  final String inventoryItemId;
  final int salePriceCents;
  final DateTime saleDate;
  final PaymentMethod paymentMethod;
  final String? buyerContactId;
  final String? notes;

  /// Snapshot of the item's acquisition value when the sale is completed.
  ///
  /// Keeping this value on the transaction preserves historical profit data
  /// even if the inventory item is edited later.
  final int? acquisitionValueCents;

  int? get profitCents {
    final acquisitionValue = acquisitionValueCents;

    if (acquisitionValue == null) {
      return null;
    }

    return salePriceCents - acquisitionValue;
  }

  double? get grossMargin {
    final profit = profitCents;

    if (profit == null || salePriceCents == 0) {
      return null;
    }

    return profit / salePriceCents;
  }

  bool get isValid {
    return inventoryItemId.trim().isNotEmpty &&
        salePriceCents >= 0 &&
        acquisitionValueCents != null &&
        acquisitionValueCents! >= 0;
  }

  SaleTransaction copyWith({
    String? id,
    String? inventoryItemId,
    int? salePriceCents,
    DateTime? saleDate,
    PaymentMethod? paymentMethod,
    Object? buyerContactId = _unset,
    Object? notes = _unset,
    Object? acquisitionValueCents = _unset,
  }) {
    return SaleTransaction(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      salePriceCents: salePriceCents ?? this.salePriceCents,
      saleDate: saleDate ?? this.saleDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      buyerContactId: identical(buyerContactId, _unset)
          ? this.buyerContactId
          : buyerContactId as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      acquisitionValueCents: identical(acquisitionValueCents, _unset)
          ? this.acquisitionValueCents
          : acquisitionValueCents as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SaleTransaction &&
            other.id == id &&
            other.inventoryItemId == inventoryItemId &&
            other.salePriceCents == salePriceCents &&
            other.saleDate == saleDate &&
            other.paymentMethod == paymentMethod &&
            other.buyerContactId == buyerContactId &&
            other.notes == notes &&
            other.acquisitionValueCents == acquisitionValueCents;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      inventoryItemId,
      salePriceCents,
      saleDate,
      paymentMethod,
      buyerContactId,
      notes,
      acquisitionValueCents,
    );
  }
}

const _unset = Object();
