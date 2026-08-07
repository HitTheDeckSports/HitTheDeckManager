import 'disposal_reason.dart';

class DisposalTransaction {
  const DisposalTransaction({
    required this.inventoryItemId,
    required this.disposalDate,
    required this.reason,
    this.id,
    this.notes,
    this.replacementInventoryItemId,
  });

  final String? id;
  final String inventoryItemId;
  final DateTime disposalDate;
  final DisposalReason reason;
  final String? notes;
  final String? replacementInventoryItemId;

  bool get requiresReplacementDeal => reason.requiresReplacementDeal;

  bool get isValid {
    if (inventoryItemId.trim().isEmpty) {
      return false;
    }
    if (replacementInventoryItemId != null &&
        replacementInventoryItemId!.trim().isEmpty) {
      return false;
    }
    return true;
  }

  DisposalTransaction copyWith({
    Object? id = _unset,
    String? inventoryItemId,
    DateTime? disposalDate,
    DisposalReason? reason,
    Object? notes = _unset,
    Object? replacementInventoryItemId = _unset,
  }) {
    return DisposalTransaction(
      id: identical(id, _unset) ? this.id : id as String?,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      disposalDate: disposalDate ?? this.disposalDate,
      reason: reason ?? this.reason,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      replacementInventoryItemId: identical(replacementInventoryItemId, _unset)
          ? this.replacementInventoryItemId
          : replacementInventoryItemId as String?,
    );
  }
}

const _unset = Object();
