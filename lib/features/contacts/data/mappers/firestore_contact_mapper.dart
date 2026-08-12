import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/contact.dart';

abstract final class FirestoreContactMapper {
  static Map<String, Object?> toFirestore(
    Contact contact, {
    bool includeCreatedAt = false,
  }) {
    final normalized = normalize(contact);

    return {
      'name': normalized.name,
      'nameSortKey': normalized.name.toLowerCase(),
      'phone': normalized.phone,
      'email': normalized.email,
      'address': normalized.address,
      'notes': normalized.notes,
      'photoUrl': normalized.photoUrl,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Contact fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Contact document ${document.id} does not contain data.',
      );
    }

    return Contact(
      id: document.id,
      name: _stringOrNull(data['name']) ?? '',
      phone: _stringOrNull(data['phone']),
      email: _stringOrNull(data['email']),
      address: _stringOrNull(data['address']),
      notes: _stringOrNull(data['notes']),
      photoUrl: _stringOrNull(data['photoUrl']),
    );
  }

  static Contact normalize(Contact contact) {
    return contact.copyWith(
      name: contact.name.trim(),
      phone: _emptyToNull(contact.phone),
      email: _emptyToNull(contact.email),
      address: _emptyToNull(contact.address),
      notes: _emptyToNull(contact.notes),
      photoUrl: _emptyToNull(contact.photoUrl),
    );
  }

  static String? _stringOrNull(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
