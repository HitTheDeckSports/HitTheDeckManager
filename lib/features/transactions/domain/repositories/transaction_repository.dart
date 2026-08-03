import '../models/sale_transaction.dart';

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
}
