import 'dart:async';

import '../../domain/models/inventory_location.dart';
import '../../domain/repositories/inventory_location_repository.dart';

class InMemoryInventoryLocationRepository
    implements InventoryLocationRepository {
  InMemoryInventoryLocationRepository({
    List<InventoryLocation> initialLocations = const [],
  }) : _locations = List<InventoryLocation>.from(initialLocations);

  final List<InventoryLocation> _locations;
  final StreamController<List<InventoryLocation>> _controller =
      StreamController<List<InventoryLocation>>.broadcast();
  int _nextId = 1;

  @override
  Stream<List<InventoryLocation>> watchLocations() async* {
    yield _snapshot();
    yield* _controller.stream;
  }

  @override
  Future<InventoryLocation> createLocation(String name) async {
    final trimmed = _validatedName(name);
    _ensureUniqueName(trimmed);
    String id;
    do {
      id = 'location-${_nextId++}';
    } while (_locations.any((location) => location.id == id));
    final location = InventoryLocation(id: id, name: trimmed);
    _locations.add(location);
    _emit();
    return location;
  }

  @override
  Future<InventoryLocation> renameLocation(String id, String name) async {
    final index = _locations.indexWhere((location) => location.id == id);
    if (index < 0) throw StateError('Inventory location $id was not found.');
    final trimmed = _validatedName(name);
    _ensureUniqueName(trimmed, excludingId: id);
    final updated = _locations[index].copyWith(name: trimmed);
    _locations[index] = updated;
    _emit();
    return updated;
  }

  @override
  Future<InventoryLocation> setLocationActive(String id, bool active) async {
    final index = _locations.indexWhere((location) => location.id == id);
    if (index < 0) throw StateError('Inventory location $id was not found.');
    final updated = _locations[index].copyWith(active: active);
    _locations[index] = updated;
    _emit();
    return updated;
  }

  Future<void> dispose() async => _controller.close();

  void _ensureUniqueName(String name, {String? excludingId}) {
    final normalized = name.toLowerCase();
    if (_locations.any(
      (location) =>
          location.id != excludingId &&
          location.name.trim().toLowerCase() == normalized,
    )) {
      throw StateError('An inventory location named "$name" already exists.');
    }
  }

  String _validatedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Location name is required.');
    }
    return trimmed;
  }

  List<InventoryLocation> _snapshot() {
    final result = List<InventoryLocation>.from(_locations)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<InventoryLocation>.unmodifiable(result);
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_snapshot());
  }
}
