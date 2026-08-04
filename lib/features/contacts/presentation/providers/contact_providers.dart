import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_contact_repository.dart';
import '../../domain/models/contact.dart';
import '../../domain/repositories/contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return InMemoryContactRepository();
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
