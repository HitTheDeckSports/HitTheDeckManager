import '../models/consignment_transaction.dart';
import '../models/disposal_transaction.dart';
import '../models/repair_transaction.dart';
import '../models/sale_transaction.dart';
import '../models/trade_transaction.dart';

abstract interface class TransactionRepository {
  /// Returns all recorded sale transactions.
  Future<List<SaleTransaction>> getSales();

  /// Watches sale transactions and emits a new list whenever sales change.
  Stream<List<SaleTransaction>> watchSales();

  /// Returns one sale transaction, or null when the ID does not exist.
  Future<SaleTransaction?> getSale(String id);

  /// Returns the sale transaction associated with an inventory item.
  ///
  /// Version 1.0 allows an inventory item to have no more than one completed
  /// sale transaction.
  Future<SaleTransaction?> getSaleForInventoryItem(String inventoryItemId);

  /// Creates a sale transaction and returns the saved record.
  ///
  /// The returned transaction should contain its assigned ID.
  Future<SaleTransaction> createSale(SaleTransaction transaction);

  /// Saves changes to an existing sale transaction.
  Future<SaleTransaction> updateSale(SaleTransaction transaction);

  /// Permanently removes a sale transaction.
  ///
  /// Normal sale corrections should generally update the transaction rather
  /// than deleting it.
  Future<void> deleteSale(String id);

  /// Returns all recorded repair transactions.
  Future<List<RepairTransaction>> getRepairs();

  /// Watches repair transactions and emits a new list whenever repairs change.
  Stream<List<RepairTransaction>> watchRepairs();

  /// Returns one repair transaction, or null when the ID does not exist.
  Future<RepairTransaction?> getRepair(String id);

  /// Returns every repair recorded for an inventory item.
  ///
  /// An inventory item may have multiple repair transactions.
  Future<List<RepairTransaction>> getRepairsForInventoryItem(
    String inventoryItemId,
  );

  /// Creates a repair transaction and returns the saved record.
  ///
  /// The returned transaction should contain its assigned ID.
  Future<RepairTransaction> createRepair(RepairTransaction transaction);

  /// Saves changes to an existing repair transaction.
  Future<RepairTransaction> updateRepair(RepairTransaction transaction);

  /// Permanently removes a repair transaction.
  Future<void> deleteRepair(String id);

  /// Returns all recorded consignment transactions.
  Future<List<ConsignmentTransaction>> getConsignments();

  /// Watches consignment transactions and emits when records change.
  Stream<List<ConsignmentTransaction>> watchConsignments();

  /// Returns one consignment transaction, or null when the ID does not exist.
  Future<ConsignmentTransaction?> getConsignment(String id);

  /// Returns the consignment transaction for an inventory item.
  ///
  /// Version 1.0 allows one consignment agreement per inventory item.
  Future<ConsignmentTransaction?> getConsignmentForInventoryItem(
    String inventoryItemId,
  );

  /// Creates a consignment transaction and returns the saved record.
  Future<ConsignmentTransaction> createConsignment(
    ConsignmentTransaction transaction,
  );

  /// Saves changes to an existing consignment transaction.
  Future<ConsignmentTransaction> updateConsignment(
    ConsignmentTransaction transaction,
  );

  /// Permanently removes a consignment transaction.
  Future<void> deleteConsignment(String id);

  /// Returns all recorded disposal transactions.
  Future<List<DisposalTransaction>> getDisposals();

  Stream<List<DisposalTransaction>> watchDisposals();

  Future<DisposalTransaction?> getDisposal(String id);

  Future<List<DisposalTransaction>> getDisposalsForInventoryItem(
    String inventoryItemId,
  );

  Future<DisposalTransaction> createDisposal(DisposalTransaction transaction);

  Future<DisposalTransaction> updateDisposal(DisposalTransaction transaction);

  Future<void> deleteDisposal(String id);

  /// Returns all recorded trade transactions.
  Future<List<TradeTransaction>> getTrades();

  /// Watches trade transactions and emits a new list whenever trades change.
  Stream<List<TradeTransaction>> watchTrades();

  /// Returns one trade transaction, or null when the ID does not exist.
  Future<TradeTransaction?> getTrade(String id);

  /// Returns every trade containing an inventory item.
  Future<List<TradeTransaction>> getTradesForInventoryItem(
    String inventoryItemId,
  );

  /// Creates a trade transaction and returns the saved record.
  Future<TradeTransaction> createTrade(TradeTransaction transaction);

  /// Saves changes to an existing trade transaction.
  Future<TradeTransaction> updateTrade(TradeTransaction transaction);

  /// Permanently removes a trade transaction.
  Future<void> deleteTrade(String id);
}
