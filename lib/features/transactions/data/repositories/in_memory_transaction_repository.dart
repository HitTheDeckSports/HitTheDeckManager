import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({
    List<SaleTransaction> initialSales = const [],
    Uuid? uuid,
  }) : _sales = [...initialSales],
       _uuid = uuid ?? const Uuid();

  final List<SaleTransaction> _sales;
  final Uuid _uuid;

  final StreamController<List<SaleTransaction>> _salesController =
      StreamController<List<SaleTransaction>>.broadcast();

  @override
  Future<List<SaleTransaction>> getSales() async {
    return List.unmodifiable(_sales);
  }

  @override
  Stream<List<SaleTransaction>> watchSales() async* {
    yield List.unmodifiable(_sales);
    yield* _salesController.stream;
  }

  @override
  Future<SaleTransaction?> getSale(String id) async {
    for (final sale in _sales) {
      if (sale.id == id) {
        return sale;
      }
    }

    return null;
  }

  @override
  Future<SaleTransaction?> getSaleForInventoryItem(
    String inventoryItemId,
  ) async {
    for (final sale in _sales) {
      if (sale.inventoryItemId == inventoryItemId) {
        return sale;
      }
    }

    return null;
  }

  @override
  Future<SaleTransaction> createSale(SaleTransaction transaction) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The sale transaction contains invalid information.',
      );
    }

    final transactionId = transaction.id ?? _uuid.v4();

    if (_sales.any((sale) => sale.id == transactionId)) {
      throw DuplicateException(
        'A sale transaction with ID $transactionId already exists.',
      );
    }

    final existingSale = await getSaleForInventoryItem(
      transaction.inventoryItemId,
    );

    if (existingSale != null) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a sale transaction.',
      );
    }

    final savedTransaction = transaction.copyWith(id: transactionId);

    _sales.add(savedTransaction);
    _notifySalesChanged();

    return savedTransaction;
  }

  @override
  Future<SaleTransaction> updateSale(SaleTransaction transaction) async {
    if (transaction.id == null) {
      throw const ValidationException(
        'A sale transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The sale transaction contains invalid information.',
      );
    }

    final index = _sales.indexWhere((sale) => sale.id == transaction.id);

    if (index == -1) {
      throw NotFoundException(
        'No sale transaction exists with ID ${transaction.id}.',
      );
    }

    final duplicateInventorySale = _sales.any(
      (sale) =>
          sale.id != transaction.id &&
          sale.inventoryItemId == transaction.inventoryItemId,
    );

    if (duplicateInventorySale) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a sale transaction.',
      );
    }

    _sales[index] = transaction;
    _notifySalesChanged();

    return transaction;
  }

  @override
  Future<void> deleteSale(String id) async {
    final originalLength = _sales.length;

    _sales.removeWhere((sale) => sale.id == id);

    if (_sales.length == originalLength) {
      throw NotFoundException('No sale transaction exists with ID $id.');
    }

    _notifySalesChanged();
  }

  void _notifySalesChanged() {
    _salesController.add(List.unmodifiable(_sales));
  }

  Future<void> dispose() async {
    await _salesController.close();
  }
}
