import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_item.dart';
import '../../domain/models/transaction_enums.dart';
import '../../domain/services/sale_completion_result.dart';
import '../providers/sale_completion_controller.dart';
import 'sell_inventory_form_state.dart';

final sellInventoryFormControllerProvider =
    NotifierProvider<SellInventoryFormController, SellInventoryFormState>(
      SellInventoryFormController.new,
    );

class SellInventoryFormController extends Notifier<SellInventoryFormState> {
  @override
  SellInventoryFormState build() {
    return SellInventoryFormState(saleDate: DateTime.now());
  }

  void setSelectedItem(InventoryItem? item) {
    state = state.copyWith(
      selectedItem: item,
      salePrice: item?.askingPriceCents == null
          ? ''
          : _formatCentsForInput(item!.askingPriceCents!),
    );
  }

  void setSalePrice(String salePrice) {
    state = state.copyWith(salePrice: salePrice);
  }

  void setSaleDate(DateTime? saleDate) {
    state = state.copyWith(saleDate: saleDate);
  }

  void setPaymentMethod(PaymentMethod paymentMethod) {
    state = state.copyWith(paymentMethod: paymentMethod);
  }

  void setBuyerContactId(String? buyerContactId) {
    state = state.copyWith(buyerContactId: buyerContactId);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<SaleCompletionResult?> submit() async {
    final item = state.selectedItem;
    final transaction = state.toSaleTransaction();

    if (item == null || transaction == null) {
      return null;
    }

    final result = await ref
        .read(saleCompletionControllerProvider.notifier)
        .completeSale(item: item, sale: transaction);

    state = SellInventoryFormState(saleDate: DateTime.now());

    return result;
  }

  void reset() {
    state = SellInventoryFormState(saleDate: DateTime.now());
  }
}

String _formatCentsForInput(int cents) {
  return (cents / 100).toStringAsFixed(2);
}
