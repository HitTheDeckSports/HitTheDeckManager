import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/forms/contact_form_controller.dart';
import 'package:hit_the_deck_manager/features/contacts/presentation/providers/contact_providers.dart';

void main() {
  group('ContactFormController', () {
    test('starts with the default form state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(contactFormControllerProvider);

      expect(state.contactId, isNull);
      expect(state.isEditing, isFalse);
      expect(state.name, isEmpty);
      expect(state.phone, isEmpty);
      expect(state.email, isEmpty);
      expect(state.address, isEmpty);
      expect(state.notes, isEmpty);
      expect(state.photoUrl, isNull);
      expect(state.isActive, isTrue);
    });

    test('updates form fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(contactFormControllerProvider.notifier);

      controller.setName('Taylor Morgan');
      controller.setPhone('555-123-4567');
      controller.setEmail('taylor@example.com');
      controller.setAddress('100 Main Street');
      controller.setNotes('Repeat customer.');
      controller.setPhotoUrl('contact-photo.jpg');
      controller.setIsActive(false);

      final state = container.read(contactFormControllerProvider);

      expect(state.name, 'Taylor Morgan');
      expect(state.phone, '555-123-4567');
      expect(state.email, 'taylor@example.com');
      expect(state.address, '100 Main Street');
      expect(state.notes, 'Repeat customer.');
      expect(state.photoUrl, 'contact-photo.jpg');
      expect(state.isActive, isFalse);
    });

    test('loads an existing contact for editing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(contactFormControllerProvider.notifier);

      const contact = Contact(
        id: 'contact-1',
        name: 'Taylor Morgan',
        phone: '555-123-4567',
        email: 'taylor@example.com',
        address: '100 Main Street',
        notes: 'Repeat customer.',
        photoUrl: 'contact-photo.jpg',
        isActive: false,
      );

      controller.loadContact(contact);

      final state = container.read(contactFormControllerProvider);

      expect(state.contactId, 'contact-1');
      expect(state.isEditing, isTrue);
      expect(state.name, 'Taylor Morgan');
      expect(state.phone, '555-123-4567');
      expect(state.email, 'taylor@example.com');
      expect(state.address, '100 Main Street');
      expect(state.notes, 'Repeat customer.');
      expect(state.photoUrl, 'contact-photo.jpg');
      expect(state.isActive, isFalse);
    });

    test('returns null and preserves state when form is invalid', () async {
      final repository = InMemoryContactRepository();

      final container = ProviderContainer(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final controller = container.read(contactFormControllerProvider.notifier);

      controller.setName('');
      controller.setEmail('invalid-email');

      final result = await controller.submit();

      expect(result, isNull);

      final state = container.read(contactFormControllerProvider);

      expect(state.name, isEmpty);
      expect(state.email, 'invalid-email');

      expect(await repository.getContacts(), isEmpty);
    });

    test('creates a contact and resets after successful submission', () async {
      final repository = InMemoryContactRepository();

      final container = ProviderContainer(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final controller = container.read(contactFormControllerProvider.notifier);

      controller.setName('Taylor Morgan');
      controller.setPhone('555-123-4567');
      controller.setEmail('taylor@example.com');
      controller.setAddress('100 Main Street');
      controller.setNotes('Repeat customer.');

      final savedContact = await controller.submit();

      expect(savedContact, isNotNull);
      expect(savedContact?.id, isNotNull);
      expect(savedContact?.name, 'Taylor Morgan');
      expect(savedContact?.phone, '555-123-4567');
      expect(savedContact?.email, 'taylor@example.com');
      expect(savedContact?.address, '100 Main Street');
      expect(savedContact?.notes, 'Repeat customer.');

      final contacts = await repository.getContacts();

      expect(contacts, contains(savedContact));
      expect(contacts, hasLength(1));

      final resetState = container.read(contactFormControllerProvider);

      expect(resetState.contactId, isNull);
      expect(resetState.isEditing, isFalse);
      expect(resetState.name, isEmpty);
      expect(resetState.phone, isEmpty);
      expect(resetState.email, isEmpty);
      expect(resetState.address, isEmpty);
      expect(resetState.notes, isEmpty);
      expect(resetState.photoUrl, isNull);
    });

    test('updates a contact and resets after successful submission', () async {
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

      final controller = container.read(contactFormControllerProvider.notifier);

      controller.loadContact(original);
      controller.setName('Taylor A. Morgan');
      controller.setPhone('555-222-2222');
      controller.setEmail('taylor@example.com');

      final updatedContact = await controller.submit();

      expect(updatedContact, isNotNull);
      expect(updatedContact?.id, 'contact-1');
      expect(updatedContact?.name, 'Taylor A. Morgan');
      expect(updatedContact?.phone, '555-222-2222');
      expect(updatedContact?.email, 'taylor@example.com');

      final storedContact = await repository.getContact('contact-1');

      expect(storedContact, updatedContact);

      final resetState = container.read(contactFormControllerProvider);

      expect(resetState.contactId, isNull);
      expect(resetState.isEditing, isFalse);
      expect(resetState.name, isEmpty);
    });

    test('setPhotoUrl can clear an existing photo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(contactFormControllerProvider.notifier);

      controller.loadContact(
        const Contact(
          id: 'contact-1',
          name: 'Taylor Morgan',
          photoUrl: 'contact-photo.jpg',
        ),
      );

      controller.setPhotoUrl(null);

      final state = container.read(contactFormControllerProvider);

      expect(state.photoUrl, isNull);
    });

    test('reset restores the default form state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(contactFormControllerProvider.notifier);

      controller.setName('Taylor Morgan');
      controller.setPhone('555-123-4567');
      controller.setEmail('taylor@example.com');

      controller.reset();

      final state = container.read(contactFormControllerProvider);

      expect(state.contactId, isNull);
      expect(state.isEditing, isFalse);
      expect(state.name, isEmpty);
      expect(state.phone, isEmpty);
      expect(state.email, isEmpty);
      expect(state.address, isEmpty);
      expect(state.notes, isEmpty);
      expect(state.photoUrl, isNull);
    });
  });
}
