import 'transaction_enums.dart';

class TradeTransaction {
  const TradeTransaction({
    this.id,
    required this.outgoingInventoryItemIds,
    required this.incomingInventoryItemIds,
    required this.tradeDate,
    this.contactId,
    this.cashPaidCents = 0,
    this.cashReceivedCents = 0,
    this.paymentMethod,
    this.notes,
  });

  final String? id;
  final List<String> outgoingInventoryItemIds;
  final List<String> incomingInventoryItemIds;
  final DateTime tradeDate;
  final String? contactId;
  final int cashPaidCents;
  final int cashReceivedCents;
  final PaymentMethod? paymentMethod;
  final String? notes;

  int get netCashCents => cashReceivedCents - cashPaidCents;

  bool get includesCash => cashPaidCents > 0 || cashReceivedCents > 0;

  bool get isValid {
    final outgoingIds = _normalizedIds(outgoingInventoryItemIds);
    final incomingIds = _normalizedIds(incomingInventoryItemIds);
    final allIds = [...outgoingIds, ...incomingIds];

    return (outgoingIds.isNotEmpty || incomingIds.isNotEmpty) &&
        allIds.toSet().length == allIds.length &&
        cashPaidCents >= 0 &&
        cashReceivedCents >= 0 &&
        (cashPaidCents == 0 || cashReceivedCents == 0) &&
        (!includesCash || paymentMethod != null);
  }

  TradeTransaction copyWith({
    Object? id = _unset,
    List<String>? outgoingInventoryItemIds,
    List<String>? incomingInventoryItemIds,
    DateTime? tradeDate,
    Object? contactId = _unset,
    int? cashPaidCents,
    int? cashReceivedCents,
    Object? paymentMethod = _unset,
    Object? notes = _unset,
  }) {
    return TradeTransaction(
      id: identical(id, _unset) ? this.id : id as String?,
      outgoingInventoryItemIds:
          outgoingInventoryItemIds ?? this.outgoingInventoryItemIds,
      incomingInventoryItemIds:
          incomingInventoryItemIds ?? this.incomingInventoryItemIds,
      tradeDate: tradeDate ?? this.tradeDate,
      contactId: identical(contactId, _unset)
          ? this.contactId
          : contactId as String?,
      cashPaidCents: cashPaidCents ?? this.cashPaidCents,
      cashReceivedCents: cashReceivedCents ?? this.cashReceivedCents,
      paymentMethod: identical(paymentMethod, _unset)
          ? this.paymentMethod
          : paymentMethod as PaymentMethod?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TradeTransaction &&
            other.id == id &&
            _listsEqual(
              other.outgoingInventoryItemIds,
              outgoingInventoryItemIds,
            ) &&
            _listsEqual(
              other.incomingInventoryItemIds,
              incomingInventoryItemIds,
            ) &&
            other.tradeDate == tradeDate &&
            other.contactId == contactId &&
            other.cashPaidCents == cashPaidCents &&
            other.cashReceivedCents == cashReceivedCents &&
            other.paymentMethod == paymentMethod &&
            other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      Object.hashAll(outgoingInventoryItemIds),
      Object.hashAll(incomingInventoryItemIds),
      tradeDate,
      contactId,
      cashPaidCents,
      cashReceivedCents,
      paymentMethod,
      notes,
    );
  }
}

List<String> _normalizedIds(List<String> values) {
  return values.map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
}

bool _listsEqual(List<String> first, List<String> second) {
  if (identical(first, second)) {
    return true;
  }

  if (first.length != second.length) {
    return false;
  }

  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }

  return true;
}

const _unset = Object();
