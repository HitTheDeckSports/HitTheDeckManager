import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/contacts/data/mappers/firestore_contact_mapper.dart';
import 'package:hit_the_deck_manager/features/contacts/domain/models/contact.dart';

void main() {
  group('FirestoreContactMapper', () {
    test('normalizes contact fields before writing', () {
      const contact = Contact(
        name: '  Eric Conn  ',
        phone: '  555-123-4567  ',
        email: '  eric@example.com  ',
        address: '  123 Main St  ',
        notes: '  Test notes  ',
        photoUrl: '  https://example.com/photo.jpg  ',
      );

      final normalized = FirestoreContactMapper.normalize(contact);

      expect(normalized.name, 'Eric Conn');
      expect(normalized.phone, '555-123-4567');
      expect(normalized.email, 'eric@example.com');
      expect(normalized.address, '123 Main St');
      expect(normalized.notes, 'Test notes');
      expect(normalized.photoUrl, 'https://example.com/photo.jpg');
    });

    test('converts blank optional fields to null', () {
      const contact = Contact(
        name: 'Test Contact',
        phone: '   ',
        email: '',
        address: ' ',
        notes: '',
        photoUrl: '   ',
      );

      final normalized = FirestoreContactMapper.normalize(contact);

      expect(normalized.phone, isNull);
      expect(normalized.email, isNull);
      expect(normalized.address, isNull);
      expect(normalized.notes, isNull);
      expect(normalized.photoUrl, isNull);
    });

    test('creates lowercase name sort key', () {
      const contact = Contact(name: 'Alex Johnson');

      final data = FirestoreContactMapper.toFirestore(contact);

      expect(data['name'], 'Alex Johnson');
      expect(data['nameSortKey'], 'alex johnson');
    });

    test('preserves optional contact values in Firestore map', () {
      const contact = Contact(
        name: 'Test Contact',
        phone: '555-555-5555',
        email: 'test@example.com',
        address: '456 Oak Ave',
        notes: 'Customer note',
        photoUrl: 'https://example.com/test.jpg',
      );

      final data = FirestoreContactMapper.toFirestore(contact);

      expect(data['phone'], '555-555-5555');
      expect(data['email'], 'test@example.com');
      expect(data['address'], '456 Oak Ave');
      expect(data['notes'], 'Customer note');
      expect(data['photoUrl'], 'https://example.com/test.jpg');
    });

    test('stores inactive status', () {
      const contact = Contact(name: 'Archived Contact', isActive: false);

      final data = FirestoreContactMapper.toFirestore(contact);

      expect(data['isActive'], isFalse);
    });
  });
}
