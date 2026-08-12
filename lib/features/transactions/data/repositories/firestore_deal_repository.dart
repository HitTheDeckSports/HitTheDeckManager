import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/deal.dart';
import '../../domain/repositories/deal_repository.dart';
import '../mappers/firestore_deal_mapper.dart';

class FirestoreDealRepository implements DealRepository {
  FirestoreDealRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'deals';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _deals =>
      _firestore.collection(collectionName);

  @override
  Future<List<Deal>> getDeals() async {
    try {
      final snapshot = await _deals.get();

      return List<Deal>.unmodifiable(
        snapshot.docs.map(FirestoreDealMapper.fromFirestore),
      );
    } catch (error) {
      throw _mapError(error, 'Unable to load Deals.');
    }
  }

  @override
  Stream<List<Deal>> watchDeals() {
    return _deals
        .snapshots()
        .map((snapshot) {
          return List<Deal>.unmodifiable(
            snapshot.docs.map(FirestoreDealMapper.fromFirestore),
          );
        })
        .handleError((Object error) {
          throw _mapError(error, 'Unable to watch Deal changes.');
        });
  }

  @override
  Future<Deal?> getDeal(String id) async {
    _validateId(id, 'Deal');

    try {
      final document = await _deals.doc(id).get();

      if (!document.exists) {
        return null;
      }

      return FirestoreDealMapper.fromFirestore(document);
    } catch (error) {
      throw _mapError(error, 'Unable to load the Deal.');
    }
  }

  @override
  Future<Deal?> getDealForParentSale(String saleTransactionId) async {
    final normalizedId = saleTransactionId.trim();

    if (normalizedId.isEmpty) {
      throw const ValidationException(
        'A parent sale transaction ID is required.',
      );
    }

    try {
      final snapshot = await _deals
          .where('parentSaleTransactionId', isEqualTo: normalizedId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FirestoreDealMapper.fromFirestore(snapshot.docs.first);
    } catch (error) {
      throw _mapError(error, 'Unable to load the Deal for this parent sale.');
    }
  }

  @override
  Future<Deal?> getDealForChildInventoryItem(String inventoryItemId) async {
    final normalizedId = inventoryItemId.trim();

    if (normalizedId.isEmpty) {
      throw const ValidationException('A child inventory item ID is required.');
    }

    try {
      final snapshot = await _deals
          .where('childInventoryItemIds', arrayContains: normalizedId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FirestoreDealMapper.fromFirestore(snapshot.docs.first);
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load the Deal for this inventory item.',
      );
    }
  }

  @override
  Future<Deal> createDeal(Deal deal) async {
    final normalized = FirestoreDealMapper.normalize(deal);

    if (!normalized.isValid) {
      throw const ValidationException(
        'The Deal contains invalid relationship information.',
      );
    }

    if (normalized.id != null) {
      throw const ValidationException('New Deals must not already have an ID.');
    }

    final existingParent = await getDealForParentSale(
      normalized.parentSaleTransactionId,
    );

    if (existingParent != null) {
      throw DuplicateException(
        'Sale ${normalized.parentSaleTransactionId} already has a Deal.',
      );
    }

    for (final childId in normalized.childInventoryItemIds) {
      final existingChild = await getDealForChildInventoryItem(childId);

      if (existingChild != null) {
        throw DuplicateException(
          'Inventory item $childId already belongs to another Deal.',
        );
      }
    }

    try {
      final reference = _deals.doc();

      await reference.set(
        FirestoreDealMapper.toFirestore(normalized, includeCreatedAt: true),
      );

      return normalized.copyWith(id: reference.id);
    } catch (error) {
      throw _mapError(error, 'Unable to create the Deal.');
    }
  }

  @override
  Future<Deal> updateDeal(Deal deal) async {
    final normalized = FirestoreDealMapper.normalize(deal);
    final id = normalized.id;

    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A Deal must have an ID before it can be updated.',
      );
    }

    if (!normalized.isValid) {
      throw const ValidationException(
        'The Deal contains invalid relationship information.',
      );
    }

    await _ensureDealExists(id);

    final parentMatches = await _deals
        .where(
          'parentSaleTransactionId',
          isEqualTo: normalized.parentSaleTransactionId,
        )
        .get();

    if (parentMatches.docs.any((document) => document.id != id)) {
      throw DuplicateException(
        'Sale ${normalized.parentSaleTransactionId} already has a Deal.',
      );
    }

    for (final childId in normalized.childInventoryItemIds) {
      final childMatches = await _deals
          .where('childInventoryItemIds', arrayContains: childId)
          .get();

      if (childMatches.docs.any((document) => document.id != id)) {
        throw DuplicateException(
          'Inventory item $childId already belongs to another Deal.',
        );
      }
    }

    try {
      await _deals
          .doc(id)
          .set(
            FirestoreDealMapper.toFirestore(normalized),
            SetOptions(merge: true),
          );

      return normalized;
    } catch (error) {
      throw _mapError(error, 'Unable to update the Deal.');
    }
  }

  @override
  Future<void> deleteDeal(String id) async {
    _validateId(id, 'Deal');

    throw const PermissionException(
      'Permanent Deal deletion is disabled because Deals reference '
      'historical sales and inventory records.',
    );
  }

  Future<void> _ensureDealExists(String id) async {
    try {
      final document = await _deals.doc(id).get();

      if (!document.exists) {
        throw NotFoundException('No Deal exists with ID $id.');
      }
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw _mapError(error, 'Unable to verify the Deal.');
    }
  }

  void _validateId(String id, String label) {
    if (id.trim().isEmpty) {
      throw ValidationException('$label ID is required.');
    }
  }

  AppException _mapError(Object error, String fallbackMessage) {
    if (error is AppException) {
      return error;
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => PermissionException(
          'You do not have permission to access Deals.',
          cause: error,
        ),
        'unavailable' => NetworkException(
          'Unable to reach Firebase. Check your internet connection.',
          cause: error,
        ),
        'not-found' => NotFoundException(
          'The requested Deal could not be found.',
          cause: error,
        ),
        'already-exists' => DuplicateException(
          'The Deal already exists.',
          cause: error,
        ),
        _ => UnexpectedException(fallbackMessage, cause: error),
      };
    }

    return UnexpectedException(fallbackMessage, cause: error);
  }
}
