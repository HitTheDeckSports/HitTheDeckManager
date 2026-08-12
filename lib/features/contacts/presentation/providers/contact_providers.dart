import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_contact_repository.dart';
import '../../domain/models/contact.dart';
import '../../domain/repositories/contact_repository.dart';

/// Provides the Firestore-backed contact repository.
///
/// Tests can override this provider with an in-memory or fake repository.
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return FirestoreContactRepository();
});

final contactsProvider = StreamProvider<List<Contact>>((ref) {
  final repository = ref.watch(contactRepositoryProvider);

  return repository.watchContacts();
});

final contactProvider = FutureProvider.family<Contact?, String>((
  ref,
  contactId,
) {
  final repository = ref.watch(contactRepositoryProvider);

  return repository.getContact(contactId);
});
