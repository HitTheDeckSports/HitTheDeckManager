import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/contact.dart';
import '../../domain/repositories/contact_repository.dart';

class InMemoryContactRepository implements ContactRepository {
  InMemoryContactRepository({
    List<Contact> initialContacts = const [],
    Uuid? uuid,
  }) : _contacts = [...initialContacts],
       _uuid = uuid ?? const Uuid() {
    _sortContacts();
  }

  final List<Contact> _contacts;
  final Uuid _uuid;

  final StreamController<List<Contact>> _contactsController =
      StreamController<List<Contact>>.broadcast();

  @override
  Future<List<Contact>> getContacts() async {
    return List.unmodifiable(_contacts);
  }

  @override
  Stream<List<Contact>> watchContacts() async* {
    yield List.unmodifiable(_contacts);
    yield* _contactsController.stream;
  }

  @override
  Future<Contact?> getContact(String id) async {
    for (final contact in _contacts) {
      if (contact.id == id) {
        return contact;
      }
    }

    return null;
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    if (!contact.isValid) {
      throw ValidationException(contact.validationErrors.join(' '));
    }

    final contactId = contact.id ?? _uuid.v4();

    if (_contacts.any((existingContact) => existingContact.id == contactId)) {
      throw DuplicateException('A contact with ID $contactId already exists.');
    }

    final savedContact = contact.copyWith(
      id: contactId,
      name: contact.name.trim(),
      phone: _emptyToNull(contact.phone),
      email: _emptyToNull(contact.email),
      address: _emptyToNull(contact.address),
      notes: _emptyToNull(contact.notes),
      photoUrl: _emptyToNull(contact.photoUrl),
    );

    _contacts.add(savedContact);
    _sortContacts();
    _notifyContactsChanged();

    return savedContact;
  }

  @override
  Future<Contact> updateContact(Contact contact) async {
    final contactId = contact.id;

    if (contactId == null || contactId.trim().isEmpty) {
      throw const ValidationException(
        'A contact must have an ID before it can be updated.',
      );
    }

    if (!contact.isValid) {
      throw ValidationException(contact.validationErrors.join(' '));
    }

    final index = _contacts.indexWhere(
      (existingContact) => existingContact.id == contactId,
    );

    if (index == -1) {
      throw NotFoundException('No contact exists with ID $contactId.');
    }

    final updatedContact = contact.copyWith(
      name: contact.name.trim(),
      phone: _emptyToNull(contact.phone),
      email: _emptyToNull(contact.email),
      address: _emptyToNull(contact.address),
      notes: _emptyToNull(contact.notes),
      photoUrl: _emptyToNull(contact.photoUrl),
    );

    _contacts[index] = updatedContact;
    _sortContacts();
    _notifyContactsChanged();

    return updatedContact;
  }

  @override
  Future<void> deleteContact(String id) async {
    final originalLength = _contacts.length;

    _contacts.removeWhere((contact) => contact.id == id);

    if (_contacts.length == originalLength) {
      throw NotFoundException('No contact exists with ID $id.');
    }

    _notifyContactsChanged();
  }

  void _sortContacts() {
    _contacts.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
  }

  void _notifyContactsChanged() {
    _contactsController.add(List.unmodifiable(_contacts));
  }

  Future<void> dispose() async {
    await _contactsController.close();
  }
}

String? _emptyToNull(String? value) {
  final trimmedValue = value?.trim() ?? '';

  return trimmedValue.isEmpty ? null : trimmedValue;
}
