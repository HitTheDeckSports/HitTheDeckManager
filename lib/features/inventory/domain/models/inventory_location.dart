class InventoryLocation {
  const InventoryLocation({
    required this.id,
    required this.name,
    this.active = true,
  });

  final String id;
  final String name;
  final bool active;

  bool get isValid => id.trim().isNotEmpty && name.trim().isNotEmpty;

  InventoryLocation copyWith({String? id, String? name, bool? active}) {
    return InventoryLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
    );
  }
}
