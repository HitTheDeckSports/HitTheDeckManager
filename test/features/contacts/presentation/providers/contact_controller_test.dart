import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_controller.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  group('ContactController', () {
    test('creates a contact and updates the contact stream', () async {
      final repository = InMemoryContactRepository();

      final container = ProviderContainer(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
      );

      final emissions = <List<Contact>>[];

      final subscription = container.listen(contactsProvider, (previous, next) {
        next.whenData(emissions.add);
      }, fireImmediately: true);

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      await Future<void>.delayed(Duration.zero);

      const contact = Contact(name: 'Taylor Morgan', phone: '555-123-4567');

      final savedContact = await container
          .read(contactControllerProvider.notifier)
          .createContact(contact);

      await Future<void>.delayed(Duration.zero);

      expect(savedContact.id, isNotNull);
      expect(savedContact.name, 'Taylor Morgan');
      expect(savedContact.phone, '555-123-4567');

      expect(emissions.first, isEmpty);
      expect(emissions.last, contains(savedContact));

      expect(
        container.read(contactControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('updates an existing contact', () async {
      const original = Contact(
        id: 'contact-1',
        name: 'Taylor Morgan',
        phone: '555-111-1111',
      );

      final repository = InMemoryContactRepository(
        initialContacts: const [original],
      );

      final container = ProviderContainer(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final updated = original.copyWith(
        name: 'Taylor A. Morgan',
        phone: '555-222-2222',
        email: 'taylor@example.com',
      );

      final result = await container
          .read(contactControllerProvider.notifier)
          .updateContact(updated);

      final storedContact = await repository.getContact('contact-1');

      expect(result, updated);
      expect(storedContact, updated);
      expect(storedContact?.name, 'Taylor A. Morgan');
      expect(storedContact?.phone, '555-222-2222');
      expect(storedContact?.email, 'taylor@example.com');

      expect(
        container.read(contactControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('deletes an existing contact', () async {
      const contact = Contact(id: 'contact-1', name: 'Taylor Morgan');

      final repository = InMemoryContactRepository(
        initialContacts: const [contact],
      );

      final container = ProviderContainer(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      await container
          .read(contactControllerProvider.notifier)
          .deleteContact('contact-1');

      expect(await repository.getContact('contact-1'), isNull);

      expect(
        container.read(contactControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('exposes repository errors through controller state', () async {
      final repository = InMemoryContactRepository();

      final container = ProviderContainer(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      const invalidContact = Contact(name: '', email: 'invalid-email');

      await expectLater(
        () => container
            .read(contactControllerProvider.notifier)
            .createContact(invalidContact),
        throwsA(isA<ValidationException>()),
      );

      expect(container.read(contactControllerProvider).hasError, isTrue);
    });
  });
}
