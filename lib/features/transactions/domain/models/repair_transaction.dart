class RepairTransaction {
  const RepairTransaction({
    this.id,
    required this.inventoryItemId,
    required this.repairDate,
    required this.costCents,
    required this.description,
    this.notes,
  });

  final String? id;
  final String inventoryItemId;
  final DateTime repairDate;
  final int costCents;
  final String description;
  final String? notes;

  bool get isValid {
    return inventoryItemId.trim().isNotEmpty &&
        costCents >= 0 &&
        description.trim().isNotEmpty;
  }

  RepairTransaction copyWith({
    String? id,
    String? inventoryItemId,
    DateTime? repairDate,
    int? costCents,
    String? description,
    Object? notes = _unset,
  }) {
    return RepairTransaction(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      repairDate: repairDate ?? this.repairDate,
      costCents: costCents ?? this.costCents,
      description: description ?? this.description,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RepairTransaction &&
            other.id == id &&
            other.inventoryItemId == inventoryItemId &&
            other.repairDate == repairDate &&
            other.costCents == costCents &&
            other.description == description &&
            other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      inventoryItemId,
      repairDate,
      costCents,
      description,
      notes,
    );
  }
}

const _unset = Object();
