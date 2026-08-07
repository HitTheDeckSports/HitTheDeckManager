import '../models/warranty_replacement_deal.dart';

abstract interface class WarrantyReplacementDealRepository {
  Future<List<WarrantyReplacementDeal>> getDeals();

  Stream<List<WarrantyReplacementDeal>> watchDeals();

  Future<WarrantyReplacementDeal?> getDeal(String id);

  Future<WarrantyReplacementDeal?> getDealForDisposal(
    String disposalTransactionId,
  );

  Future<WarrantyReplacementDeal?> getDealForInventoryItem(
    String inventoryItemId,
  );

  Future<WarrantyReplacementDeal> createDeal(WarrantyReplacementDeal deal);

  Future<void> deleteDeal(String id);
}
