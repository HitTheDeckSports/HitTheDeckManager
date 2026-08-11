import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../mappers/firestore_inventory_mapper.dart';
import '../services/firestore_inventory_number_generator.dart';

class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository({
    FirebaseFirestore? firestore,
    FirestoreInventoryNumberGenerator? inventoryNumberGenerator,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _inventoryNumberGenerator =
           inventoryNumberGenerator ??
           const FirestoreInventoryNumberGenerator();

  static const String collectionName = 'inventory';

  final FirebaseFirestore _firestore;
  final FirestoreInventoryNumberGenerator _inventoryNumberGenerator;

  CollectionReference<Map<String, dynamic>> get _inventoryCollection =>
      _firestore.collection(collectionName);

  @override
  Future<List<InventoryItem>> getInventory() async {
    try {
      final snapshot = await _inventoryCollection
          .orderBy('inventoryNumber')
          .get();

      return List<InventoryItem>.unmodifiable(
        snapshot.docs.map(FirestoreInventoryMapper.fromFirestore),
      );
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to load inventory.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while loading inventory.',
        cause: error,
      );
    }
  }

  @override
  Stream<List<InventoryItem>> watchInventory() {
    return _inventoryCollection
        .orderBy('inventoryNumber')
        .snapshots()
        .map(
          (snapshot) => List<InventoryItem>.unmodifiable(
            snapshot.docs.map(FirestoreInventoryMapper.fromFirestore),
          ),
        )
        .handleError((Object error, StackTrace stackTrace) {
          if (error is FirebaseException) {
            throw _mapFirebaseException(
              error,
              fallbackMessage: 'Unable to watch inventory changes.',
            );
          }

          throw UnexpectedException(
            'An unexpected error occurred while watching inventory.',
            cause: error,
          );
        });
  }

  @override
  Future<InventoryItem?> getInventoryItem(String id) async {
    if (id.trim().isEmpty) {
      throw const ValidationException('An inventory item ID is required.');
    }

    try {
      final document = await _inventoryCollection.doc(id).get();

      if (!document.exists) {
        return null;
      }

      return FirestoreInventoryMapper.fromFirestore(document);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to load the inventory item.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while loading the inventory item.',
        cause: error,
      );
    }
  }

  @override
  Future<InventoryItem> createInventoryItem(InventoryItem item) async {
    if (!item.isValid) {
      throw ValidationException(item.validationErrors.join(' '));
    }

    if (item.id != null || item.inventoryNumber != null) {
      throw const ValidationException(
        'New inventory items must not already have an ID or inventory number.',
      );
    }

    final documentReference = _inventoryCollection.doc();
    final numberDate = item.purchaseDate ?? DateTime.now();

    try {
      final savedItem = await _firestore.runTransaction<InventoryItem>((
        transaction,
      ) async {
        final inventoryNumber = await _inventoryNumberGenerator
            .generateInTransaction(
              firestore: _firestore,
              transaction: transaction,
              category: item.category,
              date: numberDate,
            );

        final itemWithIdentifiers = item.copyWith(
          id: documentReference.id,
          inventoryNumber: inventoryNumber,
        );

        transaction.set(
          documentReference,
          FirestoreInventoryMapper.toFirestore(
            itemWithIdentifiers,
            includeCreatedAt: true,
          ),
        );

        return itemWithIdentifiers;
      });

      return savedItem;
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to create the inventory item.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while creating the inventory item.',
        cause: error,
      );
    }
  }

  @override
  Future<InventoryItem> updateInventoryItem(InventoryItem item) async {
    final id = item.id;

    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'An inventory item must have an ID before it can be updated.',
      );
    }

    if (!item.isValid) {
      throw ValidationException(item.validationErrors.join(' '));
    }

    try {
      final reference = _inventoryCollection.doc(id);
      final existing = await reference.get();

      if (!existing.exists) {
        throw NotFoundException('No inventory item exists with ID $id.');
      }

      await reference.set(
        FirestoreInventoryMapper.toFirestore(item),
        SetOptions(merge: true),
      );

      return item;
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(
        error,
        fallbackMessage: 'Unable to update the inventory item.',
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected error occurred while updating the inventory item.',
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    throw const PermissionException(
      'Permanent inventory deletion is disabled. '
      'Use the inventory status workflow instead.',
    );
  }

  AppException _mapFirebaseException(
    FirebaseException error, {
    required String fallbackMessage,
  }) {
    return switch (error.code) {
      'permission-denied' => PermissionException(
        'You do not have permission to access inventory.',
        cause: error,
      ),
      'unavailable' => NetworkException(
        'Unable to reach Firebase. Check your internet connection.',
        cause: error,
      ),
      'not-found' => NotFoundException(
        'The requested inventory record could not be found.',
        cause: error,
      ),
      'already-exists' => DuplicateException(
        'The inventory record already exists.',
        cause: error,
      ),
      _ => UnexpectedException(fallbackMessage, cause: error),
    };
  }
}
