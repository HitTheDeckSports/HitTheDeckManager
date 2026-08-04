import '../models/contact.dart';

abstract interface class ContactRepository {
  /// Returns all contacts available to the current user.
  Future<List<Contact>> getContacts();

  /// Watches contacts and emits a new list whenever contact data changes.
  Stream<List<Contact>> watchContacts();

  /// Returns one contact, or null when the ID does not exist.
  Future<Contact?> getContact(String id);

  /// Creates a new contact and returns the saved record.
  ///
  /// The returned contact should contain its assigned database ID.
  Future<Contact> createContact(Contact contact);

  /// Saves changes to an existing contact.
  Future<Contact> updateContact(Contact contact);

  /// Permanently removes a contact.
  ///
  /// We will later prevent deletion when business records still depend on
  /// the contact.
  Future<void> deleteContact(String id);
}
