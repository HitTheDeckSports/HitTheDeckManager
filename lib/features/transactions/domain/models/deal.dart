class Deal {
  const Deal({
    required this.parentSaleTransactionId,
    required this.childInventoryItemIds,
    this.lineageInventoryItemIds = const [],
    this.id,
    this.notes,
  });

  final String? id;

  /// The original sale that created this Deal.
  final String parentSaleTransactionId;

  /// Inventory received directly through the parent sale.
  ///
  /// Stores the direct child inventory received through this Deal.
  ///
  /// Reporting may recursively follow a child's later sale into another Deal.
  /// The stored relationship remains direct-child based so reporting depth can
  /// evolve without changing existing Deal records.
  final List<String> childInventoryItemIds;

  /// Every inventory item that belongs to this Deal lineage, including direct
  /// children and later descendants produced by trades or warranty
  /// replacements.
  ///
  /// Legacy Deal records may not contain this field. An empty stored/model
  /// value therefore falls back to [childInventoryItemIds].
  final List<String> lineageInventoryItemIds;

  List<String> get effectiveLineageInventoryItemIds =>
      lineageInventoryItemIds.isEmpty
      ? childInventoryItemIds
      : lineageInventoryItemIds;

  final String? notes;

  bool get isValid {
    final parentId = parentSaleTransactionId.trim();
    final childIds = _normalizedIds(childInventoryItemIds);
    final lineageIds = _normalizedIds(effectiveLineageInventoryItemIds);

    return parentId.isNotEmpty &&
        childIds.isNotEmpty &&
        childIds.length == childIds.toSet().length &&
        lineageIds.isNotEmpty &&
        lineageIds.length == lineageIds.toSet().length &&
        childIds.every(lineageIds.contains);
  }

  Deal copyWith({
    Object? id = _unset,
    String? parentSaleTransactionId,
    List<String>? childInventoryItemIds,
    List<String>? lineageInventoryItemIds,
    Object? notes = _unset,
  }) {
    return Deal(
      id: identical(id, _unset) ? this.id : id as String?,
      parentSaleTransactionId:
          parentSaleTransactionId ?? this.parentSaleTransactionId,
      childInventoryItemIds:
          childInventoryItemIds ?? this.childInventoryItemIds,
      lineageInventoryItemIds:
          lineageInventoryItemIds ?? this.lineageInventoryItemIds,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Deal &&
            other.id == id &&
            other.parentSaleTransactionId == parentSaleTransactionId &&
            _listsEqual(other.childInventoryItemIds, childInventoryItemIds) &&
            _listsEqual(
              other.lineageInventoryItemIds,
              lineageInventoryItemIds,
            ) &&
            other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      parentSaleTransactionId,
      Object.hashAll(childInventoryItemIds),
      Object.hashAll(lineageInventoryItemIds),
      notes,
    );
  }
}

List<String> _normalizedIds(List<String> values) {
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
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
