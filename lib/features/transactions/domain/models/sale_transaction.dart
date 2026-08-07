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
    this.tradeInCreditCents = 0,
  });

  final String? id;
  final String inventoryItemId;
  final int salePriceCents;
  final DateTime saleDate;
  final PaymentMethod paymentMethod;
  final String? buyerContactId;
  final String? notes;

  /// Snapshot of the cost basis used for this completed sale.
  ///
  /// Purchased/traded inventory uses the item's acquisition value. Consigned
  /// inventory uses the consignor payout so historical profit equals the
  /// agreed Hit the Deck commission.
  final int? acquisitionValueCents;

  /// Historical value credited for all trade-in items included in the sale.
  final int tradeInCreditCents;

  /// Cash portion collected after applying trade-in credit.
  int get cashReceivedCents => salePriceCents - tradeInCreditCents;

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
        tradeInCreditCents >= 0 &&
        tradeInCreditCents <= salePriceCents &&
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
    int? tradeInCreditCents,
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
      tradeInCreditCents: tradeInCreditCents ?? this.tradeInCreditCents,
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
            other.acquisitionValueCents == acquisitionValueCents &&
            other.tradeInCreditCents == tradeInCreditCents;
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
      tradeInCreditCents,
    );
  }
}

const _unset = Object();
