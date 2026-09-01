import '../models/deal.dart';

abstract interface class DealRepository {
  Future<List<Deal>> getDeals();

  Stream<List<Deal>> watchDeals();

  Future<Deal?> getDeal(String id);

  Future<Deal?> getDealForParentSale(String saleTransactionId);

  Future<Deal?> getDealForChildInventoryItem(String inventoryItemId);

  Future<Deal?> getDealForLineageInventoryItem(String inventoryItemId);

  Future<Deal> createDeal(Deal deal);

  Future<Deal> updateDeal(Deal deal);

  Future<void> deleteDeal(String id);
}
