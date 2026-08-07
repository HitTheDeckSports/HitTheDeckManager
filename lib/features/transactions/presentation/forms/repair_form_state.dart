import '../../domain/models/repair_transaction.dart';

class RepairFormState {
  const RepairFormState({
    this.repairId,
    required this.inventoryItemId,
    required this.repairDate,
    this.costInput = '',
    this.description = '',
    this.notes = '',
  });

  factory RepairFormState.initial({
    required String inventoryItemId,
    DateTime? repairDate,
  }) {
    return RepairFormState(
      inventoryItemId: inventoryItemId,
      repairDate: repairDate ?? DateTime.now(),
    );
  }

  final String? repairId;
  final String inventoryItemId;
  final DateTime repairDate;
  final String costInput;
  final String description;
  final String notes;

  int? get costCents {
    final normalizedValue = costInput.trim().replaceAll(RegExp(r'[\$,]'), '');

    if (normalizedValue.isEmpty) {
      return null;
    }

    final parsedValue = double.tryParse(normalizedValue);

    if (parsedValue == null || !parsedValue.isFinite || parsedValue < 0) {
      return null;
    }

    return (parsedValue * 100).round();
  }

  bool get hasValidInventoryItem {
    return inventoryItemId.trim().isNotEmpty;
  }

  bool get hasValidCost {
    return costCents != null;
  }

  bool get hasValidDescription {
    return description.trim().isNotEmpty;
  }

  bool get isValid {
    return hasValidInventoryItem && hasValidCost && hasValidDescription;
  }

  String? get costError {
    if (costInput.trim().isEmpty) {
      return 'Repair cost is required.';
    }

    if (!hasValidCost) {
      return 'Enter a valid repair cost.';
    }

    return null;
  }

  String? get descriptionError {
    if (!hasValidDescription) {
      return 'Repair description is required.';
    }

    return null;
  }

  RepairTransaction toRepairTransaction() {
    final parsedCostCents = costCents;

    if (!isValid || parsedCostCents == null) {
      throw StateError('The repair form contains invalid information.');
    }

    final trimmedNotes = notes.trim();

    return RepairTransaction(
      id: repairId,
      inventoryItemId: inventoryItemId.trim(),
      repairDate: repairDate,
      costCents: parsedCostCents,
      description: description.trim(),
      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
    );
  }

  RepairFormState copyWith({
    Object? repairId = _unset,
    String? inventoryItemId,
    DateTime? repairDate,
    String? costInput,
    String? description,
    String? notes,
  }) {
    return RepairFormState(
      repairId: identical(repairId, _unset)
          ? this.repairId
          : repairId as String?,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      repairDate: repairDate ?? this.repairDate,
      costInput: costInput ?? this.costInput,
      description: description ?? this.description,
      notes: notes ?? this.notes,
    );
  }
}

const _unset = Object();
