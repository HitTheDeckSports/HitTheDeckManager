import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/consignment_transaction.dart';
import '../../domain/models/disposal_transaction.dart';
import '../../domain/models/repair_transaction.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/models/trade_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({
    List<SaleTransaction> initialSales = const [],
    List<RepairTransaction> initialRepairs = const [],
    List<TradeTransaction> initialTrades = const [],
    List<DisposalTransaction> initialDisposals = const [],
    List<ConsignmentTransaction> initialConsignments = const [],
    Uuid? uuid,
  }) : _sales = [...initialSales],
       _repairs = [...initialRepairs],
       _trades = [...initialTrades],
       _disposals = [...initialDisposals],
       _consignments = [...initialConsignments],
       _uuid = uuid ?? const Uuid();

  final List<SaleTransaction> _sales;
  final List<RepairTransaction> _repairs;
  final List<TradeTransaction> _trades;
  final List<DisposalTransaction> _disposals;
  final List<ConsignmentTransaction> _consignments;
  final Uuid _uuid;

  final StreamController<List<SaleTransaction>> _salesController =
      StreamController<List<SaleTransaction>>.broadcast();
  final StreamController<List<RepairTransaction>> _repairsController =
      StreamController<List<RepairTransaction>>.broadcast();
  final StreamController<List<TradeTransaction>> _tradesController =
      StreamController<List<TradeTransaction>>.broadcast();
  final StreamController<List<DisposalTransaction>> _disposalsController =
      StreamController<List<DisposalTransaction>>.broadcast();
  final StreamController<List<ConsignmentTransaction>> _consignmentsController =
      StreamController<List<ConsignmentTransaction>>.broadcast();

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

  @override
  Future<List<RepairTransaction>> getRepairs() async {
    return List.unmodifiable(_repairs);
  }

  @override
  Stream<List<RepairTransaction>> watchRepairs() {
    return Stream<List<RepairTransaction>>.multi((controller) {
      final subscription = _repairsController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );

      controller.add(List.unmodifiable(_repairs));

      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<RepairTransaction?> getRepair(String id) async {
    for (final repair in _repairs) {
      if (repair.id == id) {
        return repair;
      }
    }

    return null;
  }

  @override
  Future<List<RepairTransaction>> getRepairsForInventoryItem(
    String inventoryItemId,
  ) async {
    final repairs = _repairs
        .where((repair) => repair.inventoryItemId == inventoryItemId)
        .toList();

    repairs.sort(
      (first, second) => second.repairDate.compareTo(first.repairDate),
    );

    return List.unmodifiable(repairs);
  }

  @override
  Future<RepairTransaction> createRepair(RepairTransaction transaction) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The repair transaction contains invalid information.',
      );
    }

    final transactionId = transaction.id ?? _uuid.v4();

    if (_repairs.any((repair) => repair.id == transactionId)) {
      throw DuplicateException(
        'A repair transaction with ID $transactionId already exists.',
      );
    }

    final savedTransaction = transaction.copyWith(id: transactionId);

    _repairs.add(savedTransaction);
    _notifyRepairsChanged();

    return savedTransaction;
  }

  @override
  Future<RepairTransaction> updateRepair(RepairTransaction transaction) async {
    if (transaction.id == null) {
      throw const ValidationException(
        'A repair transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The repair transaction contains invalid information.',
      );
    }

    final index = _repairs.indexWhere((repair) => repair.id == transaction.id);

    if (index == -1) {
      throw NotFoundException(
        'No repair transaction exists with ID ${transaction.id}.',
      );
    }

    _repairs[index] = transaction;
    _notifyRepairsChanged();

    return transaction;
  }

  @override
  Future<void> deleteRepair(String id) async {
    final originalLength = _repairs.length;

    _repairs.removeWhere((repair) => repair.id == id);

    if (_repairs.length == originalLength) {
      throw NotFoundException('No repair transaction exists with ID $id.');
    }

    _notifyRepairsChanged();
  }

  @override
  Future<List<ConsignmentTransaction>> getConsignments() async {
    final consignments = [..._consignments]
      ..sort(
        (first, second) =>
            second.consignmentDate.compareTo(first.consignmentDate),
      );

    return List.unmodifiable(consignments);
  }

  @override
  Stream<List<ConsignmentTransaction>> watchConsignments() {
    return Stream<List<ConsignmentTransaction>>.multi((controller) {
      final subscription = _consignmentsController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );

      getConsignments().then(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<ConsignmentTransaction?> getConsignment(String id) async {
    for (final consignment in _consignments) {
      if (consignment.id == id) {
        return consignment;
      }
    }

    return null;
  }

  @override
  Future<ConsignmentTransaction?> getConsignmentForInventoryItem(
    String inventoryItemId,
  ) async {
    for (final consignment in _consignments) {
      if (consignment.inventoryItemId == inventoryItemId) {
        return consignment;
      }
    }

    return null;
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

    final transactionId = transaction.id ?? _uuid.v4();

    if (_consignments.any((consignment) => consignment.id == transactionId)) {
      throw DuplicateException(
        'A consignment transaction with ID $transactionId already exists.',
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

    final saved = transaction.copyWith(id: transactionId);
    _consignments.add(saved);
    _notifyConsignmentsChanged();

    return saved;
  }

  @override
  Future<ConsignmentTransaction> updateConsignment(
    ConsignmentTransaction transaction,
  ) async {
    final transactionId = transaction.id;

    if (transactionId == null || transactionId.trim().isEmpty) {
      throw const ValidationException(
        'A consignment transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The consignment transaction contains invalid information.',
      );
    }

    final index = _consignments.indexWhere(
      (consignment) => consignment.id == transactionId,
    );

    if (index == -1) {
      throw NotFoundException(
        'No consignment transaction exists with ID $transactionId.',
      );
    }

    final duplicateInventoryConsignment = _consignments.any(
      (consignment) =>
          consignment.id != transactionId &&
          consignment.inventoryItemId == transaction.inventoryItemId,
    );

    if (duplicateInventoryConsignment) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a consignment transaction.',
      );
    }

    _consignments[index] = transaction;
    _notifyConsignmentsChanged();

    return transaction;
  }

  @override
  Future<void> deleteConsignment(String id) async {
    final originalLength = _consignments.length;
    _consignments.removeWhere((consignment) => consignment.id == id);

    if (_consignments.length == originalLength) {
      throw NotFoundException('No consignment transaction exists with ID $id.');
    }

    _notifyConsignmentsChanged();
  }

  @override
  Future<List<DisposalTransaction>> getDisposals() async {
    final disposals = [..._disposals]
      ..sort((a, b) => b.disposalDate.compareTo(a.disposalDate));
    return List.unmodifiable(disposals);
  }

  @override
  Stream<List<DisposalTransaction>> watchDisposals() {
    return Stream<List<DisposalTransaction>>.multi((controller) {
      final subscription = _disposalsController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      getDisposals().then(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<DisposalTransaction?> getDisposal(String id) async {
    for (final disposal in _disposals) {
      if (disposal.id == id) {
        return disposal;
      }
    }
    return null;
  }

  @override
  Future<List<DisposalTransaction>> getDisposalsForInventoryItem(
    String inventoryItemId,
  ) async {
    final disposals =
        _disposals.where((d) => d.inventoryItemId == inventoryItemId).toList()
          ..sort((a, b) => b.disposalDate.compareTo(a.disposalDate));
    return List.unmodifiable(disposals);
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
    final id = transaction.id ?? _uuid.v4();
    if (_disposals.any((d) => d.id == id)) {
      throw DuplicateException(
        'A disposal transaction with ID $id already exists.',
      );
    }
    if (_disposals.any(
      (d) => d.inventoryItemId == transaction.inventoryItemId,
    )) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a disposal transaction.',
      );
    }
    final saved = transaction.copyWith(id: id);
    _disposals.add(saved);
    _notifyDisposalsChanged();
    return saved;
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
    final index = _disposals.indexWhere((d) => d.id == id);

    if (index == -1) {
      throw NotFoundException('No disposal transaction exists with ID $id.');
    }
    if (_disposals.any(
      (d) => d.id != id && d.inventoryItemId == transaction.inventoryItemId,
    )) {
      throw DuplicateException(
        'Inventory item ${transaction.inventoryItemId} already has a disposal transaction.',
      );
    }
    _disposals[index] = transaction;
    _notifyDisposalsChanged();
    return transaction;
  }

  @override
  Future<void> deleteDisposal(String id) async {
    final length = _disposals.length;

    _disposals.removeWhere((d) => d.id == id);

    if (_disposals.length == length) {
      throw NotFoundException('No disposal transaction exists with ID $id.');
    }

    _notifyDisposalsChanged();
  }

  @override
  Future<List<TradeTransaction>> getTrades() async {
    final trades = [..._trades]
      ..sort((first, second) => second.tradeDate.compareTo(first.tradeDate));

    return List.unmodifiable(trades);
  }

  @override
  Stream<List<TradeTransaction>> watchTrades() {
    return Stream<List<TradeTransaction>>.multi((controller) {
      final subscription = _tradesController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );

      getTrades().then(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<TradeTransaction?> getTrade(String id) async {
    for (final trade in _trades) {
      if (trade.id == id) {
        return trade;
      }
    }

    return null;
  }

  @override
  Future<List<TradeTransaction>> getTradesForInventoryItem(
    String inventoryItemId,
  ) async {
    final trades =
        _trades
            .where(
              (trade) =>
                  trade.outgoingInventoryItemIds.contains(inventoryItemId) ||
                  trade.incomingInventoryItemIds.contains(inventoryItemId),
            )
            .toList()
          ..sort(
            (first, second) => second.tradeDate.compareTo(first.tradeDate),
          );

    return List.unmodifiable(trades);
  }

  @override
  Future<TradeTransaction> createTrade(TradeTransaction transaction) async {
    if (!transaction.isValid) {
      throw const ValidationException(
        'The trade transaction contains invalid information.',
      );
    }

    final transactionId = transaction.id ?? _uuid.v4();

    if (_trades.any((trade) => trade.id == transactionId)) {
      throw DuplicateException(
        'A trade transaction with ID $transactionId already exists.',
      );
    }

    final savedTransaction = transaction.copyWith(id: transactionId);
    _trades.add(savedTransaction);
    _notifyTradesChanged();

    return savedTransaction;
  }

  @override
  Future<TradeTransaction> updateTrade(TradeTransaction transaction) async {
    final transactionId = transaction.id;

    if (transactionId == null || transactionId.trim().isEmpty) {
      throw const ValidationException(
        'A trade transaction must have an ID before it can be updated.',
      );
    }

    if (!transaction.isValid) {
      throw const ValidationException(
        'The trade transaction contains invalid information.',
      );
    }

    final index = _trades.indexWhere((trade) => trade.id == transactionId);

    if (index == -1) {
      throw NotFoundException(
        'No trade transaction exists with ID $transactionId.',
      );
    }

    _trades[index] = transaction;
    _notifyTradesChanged();

    return transaction;
  }

  @override
  Future<void> deleteTrade(String id) async {
    final originalLength = _trades.length;
    _trades.removeWhere((trade) => trade.id == id);

    if (_trades.length == originalLength) {
      throw NotFoundException('No trade transaction exists with ID $id.');
    }

    _notifyTradesChanged();
  }

  void _notifySalesChanged() {
    _salesController.add(List.unmodifiable(_sales));
  }

  void _notifyRepairsChanged() {
    _repairsController.add(List.unmodifiable(_repairs));
  }

  void _notifyTradesChanged() {
    getTrades().then(_tradesController.add);
  }

  void _notifyDisposalsChanged() {
    getDisposals().then(_disposalsController.add);
  }

  void _notifyConsignmentsChanged() {
    getConsignments().then(_consignmentsController.add);
  }

  Future<void> dispose() async {
    await _salesController.close();
    await _repairsController.close();
    await _tradesController.close();
    await _disposalsController.close();
    await _consignmentsController.close();
  }
}
