import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/inventory_location.dart';
import '../../domain/repositories/inventory_location_repository.dart';

class FirestoreInventoryLocationRepository
    implements InventoryLocationRepository {
  FirestoreInventoryLocationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const collectionPath = 'inventory_locations';
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection(collectionPath);

  @override
  Stream<List<InventoryLocation>> watchLocations() {
    return _locations.snapshots().map((snapshot) {
      final locations =
          snapshot.docs
              .map(_fromDocument)
              .where((location) => location.isValid)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      return List<InventoryLocation>.unmodifiable(locations);
    });
  }

  @override
  Future<InventoryLocation> createLocation(String name) async {
    final trimmedName = _validatedName(name);
    await _ensureUniqueName(trimmedName);
    final reference = _locations.doc();
    final location = InventoryLocation(id: reference.id, name: trimmedName);
    await reference.set({
      'name': trimmedName,
      'normalizedName': _normalizeName(trimmedName),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return location;
  }

  @override
  Future<InventoryLocation> renameLocation(String id, String name) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Location ID is required.');
    }
    final trimmedName = _validatedName(name);
    await _ensureUniqueName(trimmedName, excludingId: trimmedId);
    final reference = _locations.doc(trimmedId);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      throw StateError('Inventory location $trimmedId was not found.');
    }
    final active = snapshot.data()?['active'] != false;
    await reference.update({
      'name': trimmedName,
      'normalizedName': _normalizeName(trimmedName),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return InventoryLocation(id: trimmedId, name: trimmedName, active: active);
  }

  @override
  Future<InventoryLocation> setLocationActive(String id, bool active) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Location ID is required.');
    }
    final reference = _locations.doc(trimmedId);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      throw StateError('Inventory location $trimmedId was not found.');
    }
    final data = snapshot.data();
    final rawName = data?['name'];
    if (rawName is! String || rawName.trim().isEmpty) {
      throw StateError(
        'Inventory location $trimmedId does not contain a valid name.',
      );
    }
    await reference.update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return InventoryLocation(
      id: trimmedId,
      name: rawName.trim(),
      active: active,
    );
  }

  Future<void> _ensureUniqueName(String name, {String? excludingId}) async {
    final snapshot = await _locations
        .where('normalizedName', isEqualTo: _normalizeName(name))
        .limit(2)
        .get();
    if (snapshot.docs.any((document) => document.id != excludingId)) {
      throw StateError('An inventory location named "$name" already exists.');
    }
  }

  InventoryLocation _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawName = data['name'];
    return InventoryLocation(
      id: document.id,
      name: rawName is String ? rawName.trim() : '',
      active: data['active'] != false,
    );
  }

  String _validatedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Location name is required.');
    }
    return trimmed;
  }

  String _normalizeName(String name) => name.trim().toLowerCase();
}
