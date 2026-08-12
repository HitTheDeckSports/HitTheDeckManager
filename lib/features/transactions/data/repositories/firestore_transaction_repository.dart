import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/consignment_transaction.dart';
import '../../domain/models/disposal_transaction.dart';
import '../../domain/models/repair_transaction.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/models/trade_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../mappers/firestore_transaction_mapper.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String salesCollectionName = 'sales';
  static const String repairsCollectionName = 'repairs';
  static const String consignmentsCollectionName = 'consignments';
  static const String disposalsCollectionName = 'disposals';
  static const String tradesCollectionName = 'trades';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sales =>
      _firestore.collection(salesCollectionName);

  CollectionReference<Map<String, dynamic>> get _repairs =>
      _firestore.collection(repairsCollectionName);

  CollectionReference<Map<String, dynamic>> get _consignments =>
      _firestore.collection(consignmentsCollectionName);

  CollectionReference<Map<String, dynamic>> get _disposals =>
      _firestore.collection(disposalsCollectionName);

  CollectionReference<Map<String, dynamic>> get _trades =>
      _firestore.collection(tradesCollectionName);

  @override
  Future<List<SaleTransaction>> getSales() async {
    try {
      final snapshot = await _sales.get();
      final values =
          snapshot.docs
              .map(FirestoreTransactionMapper.saleFromFirestore)
              .toList()
            ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

      return List.unmodifiable(values);
    } catch (error) {
      throw _mapError(error, 'Unable to load sale transactions.');
    }
  }

  @override
  Stream<List<SaleTransaction>> watchSales() {
    return _sales
        .snapshots()
        .map((snapshot) {
          final values =
              snapshot.docs
                  .map(FirestoreTransactionMapper.saleFromFirestore)
                  .toList()
                ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
          return List<SaleTransaction>.unmodifiable(values);
        })
        .handleError((Object error) {
          throw _mapError(error, 'Unable to watch sale transactions.');
        });
  }

  @override
  Future<SaleTransaction?> getSale(String id) async {
    _validateId(id, 'sale');
    try {
      final document = await _sales.doc(id).get();
      return document.exists
          ? FirestoreTransactionMapper.saleFromFirestore(document)
          : null;
    } catch (error) {
      throw _mapError(error, 'Unable to load the sale transaction.');
    }
  }

  @override
  Future<SaleTransaction?> getSaleForInventoryItem(
    String inventoryItemId,
  ) async {
    _validateInventoryItemId(inventoryItemId);
    try {
      final snapshot = await _sales
          .where('inventoryItemId', isEqualTo: inventoryItemId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FirestoreTransactionMapper.saleFromFirestore(snapshot.docs.first);
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load the sale for this inventory item.',
      );
    }
  }

  @override
  Future<SaleTransaction> createSale(SaleTransaction transaction) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The sale transaction contains invalid information.',
      );
    }

    if (transaction.id != null) {
      throw const ValidationException(
        'New sale transactions must not already have an ID.',
      );
    }

    final existing = await getSaleForInventoryItem(transaction.inventoryItemId);
    if (existing != null) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a sale transaction.',
      );
    }

    try {
      final reference = _sales.doc();
      await reference.set(
        FirestoreTransactionMapper.saleToFirestore(
          transaction,
          includeCreatedAt: true,
        ),
      );
      return transaction.copyWith(id: reference.id);
    } catch (error) {
      throw _mapError(error, 'Unable to create the sale transaction.');
    }
  }

  @override
  Future<SaleTransaction> updateSale(SaleTransaction transaction) async {
    final id = transaction.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A sale transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The sale transaction contains invalid information.',
      );
    }

    await _ensureDocumentExists(_sales, id, 'sale transaction');

    final duplicate = await _sales
        .where('inventoryItemId', isEqualTo: transaction.inventoryItemId)
        .get();

    if (duplicate.docs.any((document) => document.id != id)) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a sale transaction.',
      );
    }

    try {
      await _sales
          .doc(id)
          .set(
            FirestoreTransactionMapper.saleToFirestore(transaction),
            SetOptions(merge: true),
          );
      return transaction;
    } catch (error) {
      throw _mapError(error, 'Unable to update the sale transaction.');
    }
  }

  @override
  Future<void> deleteSale(String id) => _blockedDelete('sale');

  @override
  Future<List<RepairTransaction>> getRepairs() async {
    try {
      final snapshot = await _repairs.get();
      final values =
          snapshot.docs
              .map(FirestoreTransactionMapper.repairFromFirestore)
              .toList()
            ..sort((a, b) => b.repairDate.compareTo(a.repairDate));
      return List.unmodifiable(values);
    } catch (error) {
      throw _mapError(error, 'Unable to load repair transactions.');
    }
  }

  @override
  Stream<List<RepairTransaction>> watchRepairs() {
    return _repairs
        .snapshots()
        .map((snapshot) {
          final values =
              snapshot.docs
                  .map(FirestoreTransactionMapper.repairFromFirestore)
                  .toList()
                ..sort((a, b) => b.repairDate.compareTo(a.repairDate));
          return List<RepairTransaction>.unmodifiable(values);
        })
        .handleError((Object error) {
          throw _mapError(error, 'Unable to watch repair transactions.');
        });
  }

  @override
  Future<RepairTransaction?> getRepair(String id) async {
    _validateId(id, 'repair');
    try {
      final document = await _repairs.doc(id).get();
      return document.exists
          ? FirestoreTransactionMapper.repairFromFirestore(document)
          : null;
    } catch (error) {
      throw _mapError(error, 'Unable to load the repair transaction.');
    }
  }

  @override
  Future<List<RepairTransaction>> getRepairsForInventoryItem(
    String inventoryItemId,
  ) async {
    _validateInventoryItemId(inventoryItemId);
    try {
      final snapshot = await _repairs
          .where('inventoryItemId', isEqualTo: inventoryItemId)
          .get();

      final values =
          snapshot.docs
              .map(FirestoreTransactionMapper.repairFromFirestore)
              .toList()
            ..sort((a, b) => b.repairDate.compareTo(a.repairDate));

      return List.unmodifiable(values);
    } catch (error) {
      throw _mapError(error, 'Unable to load repairs for this inventory item.');
    }
  }

  @override
  Future<RepairTransaction> createRepair(RepairTransaction transaction) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The repair transaction contains invalid information.',
      );
    }

    if (transaction.id != null) {
      throw const ValidationException(
        'New repair transactions must not already have an ID.',
      );
    }

    try {
      final reference = _repairs.doc();
      await reference.set(
        FirestoreTransactionMapper.repairToFirestore(
          transaction,
          includeCreatedAt: true,
        ),
      );
      return transaction.copyWith(id: reference.id);
    } catch (error) {
      throw _mapError(error, 'Unable to create the repair transaction.');
    }
  }

  @override
  Future<RepairTransaction> updateRepair(RepairTransaction transaction) async {
    final id = transaction.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A repair transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The repair transaction contains invalid information.',
      );
    }

    await _ensureDocumentExists(_repairs, id, 'repair transaction');

    try {
      await _repairs
          .doc(id)
          .set(
            FirestoreTransactionMapper.repairToFirestore(transaction),
            SetOptions(merge: true),
          );
      return transaction;
    } catch (error) {
      throw _mapError(error, 'Unable to update the repair transaction.');
    }
  }

  @override
  Future<void> deleteRepair(String id) => _blockedDelete('repair');

  @override
  Future<List<ConsignmentTransaction>> getConsignments() async {
    try {
      final snapshot = await _consignments.get();
      final values =
          snapshot.docs
              .map(FirestoreTransactionMapper.consignmentFromFirestore)
              .toList()
            ..sort((a, b) => b.consignmentDate.compareTo(a.consignmentDate));
      return List.unmodifiable(values);
    } catch (error) {
      throw _mapError(error, 'Unable to load consignment transactions.');
    }
  }

  @override
  Stream<List<ConsignmentTransaction>> watchConsignments() {
    return _consignments
        .snapshots()
        .map((snapshot) {
          final values =
              snapshot.docs
                  .map(FirestoreTransactionMapper.consignmentFromFirestore)
                  .toList()
                ..sort(
                  (a, b) => b.consignmentDate.compareTo(a.consignmentDate),
                );
          return List<ConsignmentTransaction>.unmodifiable(values);
        })
        .handleError((Object error) {
          throw _mapError(error, 'Unable to watch consignment transactions.');
        });
  }

  @override
  Future<ConsignmentTransaction?> getConsignment(String id) async {
    _validateId(id, 'consignment');
    try {
      final document = await _consignments.doc(id).get();
      return document.exists
          ? FirestoreTransactionMapper.consignmentFromFirestore(document)
          : null;
    } catch (error) {
      throw _mapError(error, 'Unable to load the consignment transaction.');
    }
  }

  @override
  Future<ConsignmentTransaction?> getConsignmentForInventoryItem(
    String inventoryItemId,
  ) async {
    _validateInventoryItemId(inventoryItemId);
    try {
      final snapshot = await _consignments
          .where('inventoryItemId', isEqualTo: inventoryItemId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FirestoreTransactionMapper.consignmentFromFirestore(
        snapshot.docs.first,
      );
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load the consignment for this inventory item.',
      );
    }
  }

  @override
  Future<ConsignmentTransaction> createConsignment(
    ConsignmentTransaction transaction,
  ) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The consignment transaction contains invalid information.',
      );
    }

    if (transaction.id != null) {
      throw const ValidationException(
        'New consignment transactions must not already have an ID.',
      );
    }

    final existing = await getConsignmentForInventoryItem(
      transaction.inventoryItemId,
    );

    if (existing != null) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a consignment transaction.',
      );
    }

    try {
      final reference = _consignments.doc();
      await reference.set(
        FirestoreTransactionMapper.consignmentToFirestore(
          transaction,
          includeCreatedAt: true,
        ),
      );
      return transaction.copyWith(id: reference.id);
    } catch (error) {
      throw _mapError(error, 'Unable to create the consignment transaction.');
    }
  }

  @override
  Future<ConsignmentTransaction> updateConsignment(
    ConsignmentTransaction transaction,
  ) async {
    final id = transaction.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A consignment transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The consignment transaction contains invalid information.',
      );
    }

    await _ensureDocumentExists(_consignments, id, 'consignment transaction');

    final duplicate = await _consignments
        .where('inventoryItemId', isEqualTo: transaction.inventoryItemId)
        .get();

    if (duplicate.docs.any((document) => document.id != id)) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a consignment transaction.',
      );
    }

    try {
      await _consignments
          .doc(id)
          .set(
            FirestoreTransactionMapper.consignmentToFirestore(transaction),
            SetOptions(merge: true),
          );
      return transaction;
    } catch (error) {
      throw _mapError(error, 'Unable to update the consignment transaction.');
    }
  }

  @override
  Future<void> deleteConsignment(String id) => _blockedDelete('consignment');

  @override
  Future<List<DisposalTransaction>> getDisposals() async {
    try {
      final snapshot = await _disposals.get();
      final values =
          snapshot.docs
              .map(FirestoreTransactionMapper.disposalFromFirestore)
              .toList()
            ..sort((a, b) => b.disposalDate.compareTo(a.disposalDate));
      return List.unmodifiable(values);
    } catch (error) {
      throw _mapError(error, 'Unable to load disposal transactions.');
    }
  }

  @override
  Stream<List<DisposalTransaction>> watchDisposals() {
    return _disposals
        .snapshots()
        .map((snapshot) {
          final values =
              snapshot.docs
                  .map(FirestoreTransactionMapper.disposalFromFirestore)
                  .toList()
                ..sort((a, b) => b.disposalDate.compareTo(a.disposalDate));
          return List<DisposalTransaction>.unmodifiable(values);
        })
        .handleError((Object error) {
          throw _mapError(error, 'Unable to watch disposal transactions.');
        });
  }

  @override
  Future<DisposalTransaction?> getDisposal(String id) async {
    _validateId(id, 'disposal');
    try {
      final document = await _disposals.doc(id).get();
      return document.exists
          ? FirestoreTransactionMapper.disposalFromFirestore(document)
          : null;
    } catch (error) {
      throw _mapError(error, 'Unable to load the disposal transaction.');
    }
  }

  @override
  Future<List<DisposalTransaction>> getDisposalsForInventoryItem(
    String inventoryItemId,
  ) async {
    _validateInventoryItemId(inventoryItemId);
    try {
      final snapshot = await _disposals
          .where('inventoryItemId', isEqualTo: inventoryItemId)
          .get();

      final values =
          snapshot.docs
              .map(FirestoreTransactionMapper.disposalFromFirestore)
              .toList()
            ..sort((a, b) => b.disposalDate.compareTo(a.disposalDate));

      return List.unmodifiable(values);
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load disposals for this inventory item.',
      );
    }
  }

  @override
  Future<DisposalTransaction> createDisposal(
    DisposalTransaction transaction,
  ) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The disposal transaction contains invalid information.',
      );
    }

    if (transaction.id != null) {
      throw const ValidationException(
        'New disposal transactions must not already have an ID.',
      );
    }

    final existing = await getDisposalsForInventoryItem(
      transaction.inventoryItemId,
    );

    if (existing.isNotEmpty) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a disposal transaction.',
      );
    }

    try {
      final reference = _disposals.doc();
      await reference.set(
        FirestoreTransactionMapper.disposalToFirestore(
          transaction,
          includeCreatedAt: true,
        ),
      );
      return transaction.copyWith(id: reference.id);
    } catch (error) {
      throw _mapError(error, 'Unable to create the disposal transaction.');
    }
  }

  @override
  Future<DisposalTransaction> updateDisposal(
    DisposalTransaction transaction,
  ) async {
    final id = transaction.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A disposal transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The disposal transaction contains invalid information.',
      );
    }

    await _ensureDocumentExists(_disposals, id, 'disposal transaction');

    final duplicate = await _disposals
        .where('inventoryItemId', isEqualTo: transaction.inventoryItemId)
        .get();

    if (duplicate.docs.any((document) => document.id != id)) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a disposal transaction.',
      );
    }

    try {
      await _disposals
          .doc(id)
          .set(
            FirestoreTransactionMapper.disposalToFirestore(transaction),
            SetOptions(merge: true),
          );
      return transaction;
    } catch (error) {
      throw _mapError(error, 'Unable to update the disposal transaction.');
    }
  }

  @override
  Future<void> deleteDisposal(String id) => _blockedDelete('disposal');

  @override
  Future<List<TradeTransaction>> getTrades() async {
    try {
      final snapshot = await _trades.get();
      final values =
          snapshot.docs
              .map(FirestoreTransactionMapper.tradeFromFirestore)
              .toList()
            ..sort((a, b) => b.tradeDate.compareTo(a.tradeDate));
      return List.unmodifiable(values);
    } catch (error) {
      throw _mapError(error, 'Unable to load trade transactions.');
    }
  }

  @override
  Stream<List<TradeTransaction>> watchTrades() {
    return _trades
        .snapshots()
        .map((snapshot) {
          final values =
              snapshot.docs
                  .map(FirestoreTransactionMapper.tradeFromFirestore)
                  .toList()
                ..sort((a, b) => b.tradeDate.compareTo(a.tradeDate));
          return List<TradeTransaction>.unmodifiable(values);
        })
        .handleError((Object error) {
          throw _mapError(error, 'Unable to watch trade transactions.');
        });
  }

  @override
  Future<TradeTransaction?> getTrade(String id) async {
    _validateId(id, 'trade');
    try {
      final document = await _trades.doc(id).get();
      return document.exists
          ? FirestoreTransactionMapper.tradeFromFirestore(document)
          : null;
    } catch (error) {
      throw _mapError(error, 'Unable to load the trade transaction.');
    }
  }

  @override
  Future<List<TradeTransaction>> getTradesForInventoryItem(
    String inventoryItemId,
  ) async {
    _validateInventoryItemId(inventoryItemId);

    final trades = await getTrades();
    return List.unmodifiable(
      trades.where(
        (trade) =>
            trade.outgoingInventoryItemIds.contains(inventoryItemId) ||
            trade.incomingInventoryItemIds.contains(inventoryItemId),
      ),
    );
  }

  @override
  Future<TradeTransaction> createTrade(TradeTransaction transaction) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The trade transaction contains invalid information.',
      );
    }

    if (transaction.id != null) {
      throw const ValidationException(
        'New trade transactions must not already have an ID.',
      );
    }

    try {
      final reference = _trades.doc();
      await reference.set(
        FirestoreTransactionMapper.tradeToFirestore(
          transaction,
          includeCreatedAt: true,
        ),
      );
      return transaction.copyWith(id: reference.id);
    } catch (error) {
      throw _mapError(error, 'Unable to create the trade transaction.');
    }
  }

  @override
  Future<TradeTransaction> updateTrade(TradeTransaction transaction) async {
    final id = transaction.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A trade transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The trade transaction contains invalid information.',
      );
    }

    await _ensureDocumentExists(_trades, id, 'trade transaction');

    try {
      await _trades
          .doc(id)
          .set(
            FirestoreTransactionMapper.tradeToFirestore(transaction),
            SetOptions(merge: true),
          );
      return transaction;
    } catch (error) {
      throw _mapError(error, 'Unable to update the trade transaction.');
    }
  }

  @override
  Future<void> deleteTrade(String id) => _blockedDelete('trade');

  Future<void> _ensureDocumentExists(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
    String label,
  ) async {
    try {
      final document = await collection.doc(id).get();
      if (!document.exists) {
        throw NotFoundException('No $label exists with ID $id.');
      }
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw _mapError(error, 'Unable to verify the $label.');
    }
  }

  void _validateId(String id, String label) {
    if (id.trim().isEmpty) {
      throw ValidationException('A $label transaction ID is required.');
    }
  }

  void _validateInventoryItemId(String inventoryItemId) {
    if (inventoryItemId.trim().isEmpty) {
      throw const ValidationException('An inventory item ID is required.');
    }
  }

  Future<void> _blockedDelete(String transactionType) async {
    throw PermissionException(
      'Permanent $transactionType transaction deletion is disabled. '
      'Use the correction workflow instead.',
    );
  }

  AppException _mapError(Object error, String fallbackMessage) {
    if (error is AppException) {
      return error;
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => PermissionException(
          'You do not have permission to access transactions.',
          cause: error,
        ),
        'unavailable' => NetworkException(
          'Unable to reach Firebase. Check your internet connection.',
          cause: error,
        ),
        'not-found' => NotFoundException(
          'The requested transaction could not be found.',
          cause: error,
        ),
        'already-exists' => DuplicateException(
          'The transaction already exists.',
          cause: error,
        ),
        _ => UnexpectedException(fallbackMessage, cause: error),
      };
    }

    return UnexpectedException(fallbackMessage, cause: error);
  }
}
