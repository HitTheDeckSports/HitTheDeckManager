import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/contact.dart';
import '../../domain/repositories/contact_repository.dart';
import '../mappers/firestore_contact_mapper.dart';

class FirestoreContactRepository implements ContactRepository {
  FirestoreContactRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'contacts';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _contactsCollection =>
      _firestore.collection(collectionName);

  @override
  Future<List<Contact>> getContacts() async {
    try {
      final snapshot = await _contactsCollection.orderBy('nameSortKey').get();

      return List<Contact>.unmodifiable(
        snapshot.docs.map(FirestoreContactMapper.fromFirestore),
      );
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to load contacts.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while loading contacts.',
        cause: error,
      );
    }
  }

  @override
  Stream<List<Contact>> watchContacts() {
    return _contactsCollection
        .orderBy('nameSortKey')
        .snapshots()
        .map(
          (snapshot) => List<Contact>.unmodifiable(
            snapshot.docs.map(FirestoreContactMapper.fromFirestore),
          ),
        )
        .handleError((Object error, StackTrace stackTrace) {
          if (error is FirebaseException) {
            throw _mapFirebaseException(
              error,
              fallbackMessage: 'Unable to watch contact changes.',
            );
          }

          throw UnexpectedException(
            'An unexpected error occurred while watching contacts.',
            cause: error,
          );
        });
  }

  @override
  Future<Contact?> getContact(String id) async {
    if (id.trim().isEmpty) {
      throw const ValidationException('A contact ID is required.');
    }

    try {
      final document = await _contactsCollection.doc(id).get();

      if (!document.exists) {
        return null;
      }

      return FirestoreContactMapper.fromFirestore(document);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to load the contact.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while loading the contact.',
        cause: error,
      );
    }
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    if (!contact.isValid) {
      throw ValidationException(contact.validationErrors.join(' '));
    }

    if (contact.id != null) {
      throw const ValidationException(
        'New contacts must not already have an ID.',
      );
    }

    final normalized = FirestoreContactMapper.normalize(contact);
    final reference = _contactsCollection.doc();

    try {
      await reference.set(
        FirestoreContactMapper.toFirestore(normalized, includeCreatedAt: true),
      );

      return normalized.copyWith(id: reference.id);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to create the contact.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while creating the contact.',
        cause: error,
      );
    }
  }

  @override
  Future<Contact> updateContact(Contact contact) async {
    final id = contact.id;

    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A contact must have an ID before it can be updated.',
      );
    }

    if (!contact.isValid) {
      throw ValidationException(contact.validationErrors.join(' '));
    }

    final normalized = FirestoreContactMapper.normalize(contact);

    try {
      final reference = _contactsCollection.doc(id);
      final existing = await reference.get();

      if (!existing.exists) {
        throw NotFoundException('No contact exists with ID $id.');
      }

      await reference.set(
        FirestoreContactMapper.toFirestore(normalized),
        SetOptions(merge: true),
      );

      return normalized;
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to update the contact.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while updating the contact.',
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    throw const PermissionException(
      'Permanent contact deletion is disabled while business records '
      'may reference contacts.',
    );
  }

  AppException _mapFirebaseException(
    FirebaseException error, {
    required String fallbackMessage,
  }) {
    return switch (error.code) {
      'permission-denied' => PermissionException(
        'You do not have permission to access contacts.',
        cause: error,
      ),
      'unavailable' => NetworkException(
        'Unable to reach Firebase. Check your internet connection.',
        cause: error,
      ),
      'not-found' => NotFoundException(
        'The requested contact could not be found.',
        cause: error,
      ),
      'already-exists' => DuplicateException(
        'The contact already exists.',
        cause: error,
      ),
      _ => UnexpectedException(fallbackMessage, cause: error),
    };
  }
}
