import '../../domain/models/contact.dart';

const _unset = Object();

class ContactFormState {
  const ContactFormState({
    this.contactId,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.photoUrl,
    this.isActive = true,
  });

  final String? contactId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String? photoUrl;
  final bool isActive;

  bool get isEditing => contactId != null;

  Contact? toContact() {
    final contact = Contact(
      id: contactId,
      name: name.trim(),
      phone: _emptyToNull(phone),
      email: _emptyToNull(email),
      address: _emptyToNull(address),
      notes: _emptyToNull(notes),
      photoUrl: _emptyToNull(photoUrl),
      isActive: isActive,
    );

    return contact.isValid ? contact : null;
  }

  ContactFormState copyWith({
    Object? contactId = _unset,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    Object? photoUrl = _unset,
    bool? isActive,
  }) {
    return ContactFormState(
      contactId: identical(contactId, _unset)
          ? this.contactId
          : contactId as String?,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      photoUrl: identical(photoUrl, _unset)
          ? this.photoUrl
          : photoUrl as String?,
      isActive: isActive ?? this.isActive,
    );
  }

  factory ContactFormState.fromContact(Contact contact) {
    return ContactFormState(
      contactId: contact.id,
      name: contact.name,
      phone: contact.phone ?? '',
      email: contact.email ?? '',
      address: contact.address ?? '',
      notes: contact.notes ?? '',
      photoUrl: contact.photoUrl,
      isActive: contact.isActive,
    );
  }
}

String? _emptyToNull(String? value) {
  final trimmedValue = value?.trim() ?? '';

  return trimmedValue.isEmpty ? null : trimmedValue;
}
