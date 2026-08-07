import '../../../inventory/domain/models/inventory_item.dart';
import '../models/sale_transaction.dart';

class SaleCompletionResult {
  const SaleCompletionResult({required this.sale, required this.soldItem});

  final SaleTransaction sale;
  final InventoryItem soldItem;
}
