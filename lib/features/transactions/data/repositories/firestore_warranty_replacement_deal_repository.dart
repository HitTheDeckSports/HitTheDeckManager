import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/warranty_replacement_deal.dart';
import '../../domain/repositories/warranty_replacement_deal_repository.dart';
import '../mappers/firestore_warranty_replacement_deal_mapper.dart';

class FirestoreWarrantyReplacementDealRepository
    implements WarrantyReplacementDealRepository {
  FirestoreWarrantyReplacementDealRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'warranty_replacement_deals';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _deals =>
      _firestore.collection(collectionName);

  @override
  Future<List<WarrantyReplacementDeal>> getDeals() async {
    try {
      final snapshot = await _deals.get();

      return List<WarrantyReplacementDeal>.unmodifiable(
        snapshot.docs.map(FirestoreWarrantyReplacementDealMapper.fromFirestore),
      );
    } catch (error) {
      throw _mapError(error, 'Unable to load warranty replacement Deals.');
    }
  }

  @override
  Stream<List<WarrantyReplacementDeal>> watchDeals() {
    return _deals
        .snapshots()
        .map((snapshot) {
          return List<WarrantyReplacementDeal>.unmodifiable(
            snapshot.docs.map(
              FirestoreWarrantyReplacementDealMapper.fromFirestore,
            ),
          );
        })
        .handleError((Object error) {
          throw _mapError(error, 'Unable to watch warranty replacement Deals.');
        });
  }

  @override
  Future<WarrantyReplacementDeal?> getDeal(String id) async {
    _validateId(id, 'Warranty replacement Deal');

    try {
      final document = await _deals.doc(id).get();

      if (!document.exists) {
        return null;
      }

      return FirestoreWarrantyReplacementDealMapper.fromFirestore(document);
    } catch (error) {
      throw _mapError(error, 'Unable to load the warranty replacement Deal.');
    }
  }

  @override
  Future<WarrantyReplacementDeal?> getDealForDisposal(
    String disposalTransactionId,
  ) async {
    final normalizedId = disposalTransactionId.trim();

    if (normalizedId.isEmpty) {
      throw const ValidationException('A disposal transaction ID is required.');
    }

    try {
      final snapshot = await _deals
          .where('disposalTransactionId', isEqualTo: normalizedId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FirestoreWarrantyReplacementDealMapper.fromFirestore(
        snapshot.docs.first,
      );
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load the warranty replacement Deal for this disposal.',
      );
    }
  }

  @override
  Future<WarrantyReplacementDeal?> getDealForInventoryItem(
    String inventoryItemId,
  ) async {
    final normalizedId = inventoryItemId.trim();

    if (normalizedId.isEmpty) {
      throw const ValidationException('An inventory item ID is required.');
    }

    try {
      final disposedSnapshot = await _deals
          .where('disposedInventoryItemId', isEqualTo: normalizedId)
          .limit(1)
          .get();

      if (disposedSnapshot.docs.isNotEmpty) {
        return FirestoreWarrantyReplacementDealMapper.fromFirestore(
          disposedSnapshot.docs.first,
        );
      }

      final replacementSnapshot = await _deals
          .where('replacementInventoryItemId', isEqualTo: normalizedId)
          .limit(1)
          .get();

      if (replacementSnapshot.docs.isEmpty) {
        return null;
      }

      return FirestoreWarrantyReplacementDealMapper.fromFirestore(
        replacementSnapshot.docs.first,
      );
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load the warranty replacement Deal for this inventory item.',
      );
    }
  }

  @override
  Future<WarrantyReplacementDeal> createDeal(
    WarrantyReplacementDeal deal,
  ) async {
    final normalized = FirestoreWarrantyReplacementDealMapper.normalize(deal);

    if (!normalized.isValid) {
      throw const ValidationException(
        'The warranty replacement Deal contains invalid information.',
      );
    }

    if (normalized.id != null) {
      throw const ValidationException(
        'New warranty replacement Deals must not already have an ID.',
      );
    }

    final existing = await getDealForDisposal(normalized.disposalTransactionId);

    if (existing != null) {
      throw DuplicateException(
        'Disposal ${normalized.disposalTransactionId} already has a warranty replacement Deal.',
      );
    }

    try {
      final reference = _deals.doc();

      await reference.set(
        FirestoreWarrantyReplacementDealMapper.toFirestore(
          normalized,
          includeCreatedAt: true,
        ),
      );

      return normalized.copyWith(id: reference.id);
    } catch (error) {
      throw _mapError(error, 'Unable to create the warranty replacement Deal.');
    }
  }

  @override
  Future<void> deleteDeal(String id) async {
    _validateId(id, 'Warranty replacement Deal');

    throw const PermissionException(
      'Permanent warranty replacement Deal deletion is disabled.',
    );
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
          'You do not have permission to access warranty replacement Deals.',
          cause: error,
        ),
        'unavailable' => NetworkException(
          'Unable to reach Firebase. Check your internet connection.',
          cause: error,
        ),
        'not-found' => NotFoundException(
          'The requested warranty replacement Deal could not be found.',
          cause: error,
        ),
        'already-exists' => DuplicateException(
          'The warranty replacement Deal already exists.',
          cause: error,
        ),
        _ => UnexpectedException(fallbackMessage, cause: error),
      };
    }

    return UnexpectedException(fallbackMessage, cause: error);
  }
}
