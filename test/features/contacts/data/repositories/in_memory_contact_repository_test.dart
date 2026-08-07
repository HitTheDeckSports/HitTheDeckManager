import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/errors/app_exception.dart';
import 'package:hit_the_deck_manager/features/contacts/data/repositories/in_memory_contact_repository.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';

void main() {
  group('InMemoryContactRepository', () {
    test('starts with the supplied contacts sorted by name', () async {
      const jordan = Contact(id: 'contact-2', name: 'Jordan Smith');

      const alex = Contact(id: 'contact-1', name: 'Alex Johnson');

      final repository = InMemoryContactRepository(
        initialContacts: const [jordan, alex],
      );

      addTearDown(repository.dispose);

      final contacts = await repository.getContacts();

      expect(contacts, hasLength(2));
      expect(contacts.first, alex);
      expect(contacts.last, jordan);
    });

    test('creates a contact and normalizes text fields', () async {
      final repository = InMemoryContactRepository();

      addTearDown(repository.dispose);

      const contact = Contact(
        name: '  Taylor Morgan  ',
        phone: '  555-123-4567  ',
        email: '  taylor@example.com  ',
        address: '  100 Main Street  ',
        notes: '  Repeat customer.  ',
        photoUrl: '  contact-photo.jpg  ',
      );

      final savedContact = await repository.createContact(contact);

      expect(savedContact.id, isNotNull);
      expect(savedContact.name, 'Taylor Morgan');
      expect(savedContact.phone, '555-123-4567');
      expect(savedContact.email, 'taylor@example.com');
      expect(savedContact.address, '100 Main Street');
      expect(savedContact.notes, 'Repeat customer.');
      expect(savedContact.photoUrl, 'contact-photo.jpg');

      final contacts = await repository.getContacts();

      expect(contacts, contains(savedContact));
      expect(contacts, hasLength(1));
    });

    test('converts blank optional fields to null', () async {
      final repository = InMemoryContactRepository();

      addTearDown(repository.dispose);

      const contact = Contact(
        name: 'Taylor Morgan',
        phone: '   ',
        email: '',
        address: '  ',
        notes: '',
        photoUrl: '   ',
      );

      final savedContact = await repository.createContact(contact);

      expect(savedContact.phone, isNull);
      expect(savedContact.email, isNull);
      expect(savedContact.address, isNull);
      expect(savedContact.notes, isNull);
      expect(savedContact.photoUrl, isNull);
    });

    test('keeps contacts sorted alphabetically after creation', () async {
      final repository = InMemoryContactRepository();

      addTearDown(repository.dispose);

      await repository.createContact(
        const Contact(id: 'contact-2', name: 'Jordan Smith'),
      );

      await repository.createContact(
        const Contact(id: 'contact-1', name: 'Alex Johnson'),
      );

      final contacts = await repository.getContacts();

      expect(contacts.map((contact) => contact.name), [
        'Alex Johnson',
        'Jordan Smith',
      ]);
    });

    test('returns one contact by ID', () async {
      const contact = Contact(id: 'contact-1', name: 'Taylor Morgan');

      final repository = InMemoryContactRepository(
        initialContacts: const [contact],
      );

      addTearDown(repository.dispose);

      final result = await repository.getContact('contact-1');

      expect(result, contact);
      expect(await repository.getContact('missing-contact'), isNull);
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

      addTearDown(repository.dispose);

      final updated = original.copyWith(
        name: '  Taylor A. Morgan  ',
        phone: '  555-222-2222  ',
        email: '  taylor@example.com  ',
      );

      final result = await repository.updateContact(updated);

      expect(result.id, 'contact-1');
      expect(result.name, 'Taylor A. Morgan');
      expect(result.phone, '555-222-2222');
      expect(result.email, 'taylor@example.com');

      final storedContact = await repository.getContact('contact-1');

      expect(storedContact, result);
    });

    test('deletes an existing contact', () async {
      const contact = Contact(id: 'contact-1', name: 'Taylor Morgan');

      final repository = InMemoryContactRepository(
        initialContacts: const [contact],
      );

      addTearDown(repository.dispose);

      await repository.deleteContact('contact-1');

      expect(await repository.getContact('contact-1'), isNull);

      expect(await repository.getContacts(), isEmpty);
    });

    test('rejects an invalid contact', () async {
      final repository = InMemoryContactRepository();

      addTearDown(repository.dispose);

      const contact = Contact(name: '', email: 'invalid-email');

      await expectLater(
        () => repository.createContact(contact),
        throwsA(isA<ValidationException>()),
      );

      expect(await repository.getContacts(), isEmpty);
    });

    test('rejects a duplicate contact ID', () async {
      const existing = Contact(id: 'contact-1', name: 'Taylor Morgan');

      final repository = InMemoryContactRepository(
        initialContacts: const [existing],
      );

      addTearDown(repository.dispose);

      await expectLater(
        () => repository.createContact(
          const Contact(id: 'contact-1', name: 'Jordan Smith'),
        ),
        throwsA(isA<DuplicateException>()),
      );
    });

    test('rejects update without an ID', () async {
      final repository = InMemoryContactRepository();

      addTearDown(repository.dispose);

      await expectLater(
        () => repository.updateContact(const Contact(name: 'Taylor Morgan')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects update for a missing contact', () async {
      final repository = InMemoryContactRepository();

      addTearDown(repository.dispose);

      await expectLater(
        () => repository.updateContact(
          const Contact(id: 'missing-contact', name: 'Taylor Morgan'),
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('rejects deletion for a missing contact', () async {
      final repository = InMemoryContactRepository();

      addTearDown(repository.dispose);

      await expectLater(
        () => repository.deleteContact('missing-contact'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test(
      'watchContacts emits changes after create update and delete',
      () async {
        const original = Contact(id: 'contact-1', name: 'Taylor Morgan');

        final repository = InMemoryContactRepository(
          initialContacts: const [original],
        );

        addTearDown(repository.dispose);

        final emissions = <List<Contact>>[];

        final subscription = repository.watchContacts().listen(emissions.add);

        addTearDown(subscription.cancel);

        await Future<void>.delayed(Duration.zero);

        final created = await repository.createContact(
          const Contact(id: 'contact-2', name: 'Alex Johnson'),
        );

        await repository.updateContact(created.copyWith(phone: '555-123-4567'));

        await repository.deleteContact('contact-1');

        await Future<void>.delayed(Duration.zero);

        expect(emissions, hasLength(4));

        expect(emissions[0].map((contact) => contact.id), ['contact-1']);

        expect(emissions[1].map((contact) => contact.id), [
          'contact-2',
          'contact-1',
        ]);

        expect(
          emissions[2].firstWhere((contact) => contact.id == 'contact-2').phone,
          '555-123-4567',
        );

        expect(emissions[3].map((contact) => contact.id), ['contact-2']);
      },
    );
  });
}
