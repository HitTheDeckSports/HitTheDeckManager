import '../../../../core/formatting/currency_formatter.dart';
import '../../../inventory/domain/models/inventory_item.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/models/transaction_enums.dart';

class SellInventoryFormState {
  const SellInventoryFormState({
    this.selectedItem,
    this.salePrice = '',
    this.saleDate,
    this.paymentMethod = PaymentMethod.cash,
    this.buyerContactId,
    this.notes = '',
  });

  final InventoryItem? selectedItem;
  final String salePrice;
  final DateTime? saleDate;
  final PaymentMethod paymentMethod;
  final String? buyerContactId;
  final String notes;

  int? get salePriceCents {
    return CurrencyFormatter.tryParseToCents(salePrice);
  }

  int? get profitCents {
    final item = selectedItem;
    final parsedSalePrice = salePriceCents;

    if (item == null || parsedSalePrice == null) {
      return null;
    }

    return parsedSalePrice - item.acquisitionValueCents;
  }

  double? get grossMargin {
    final parsedSalePrice = salePriceCents;
    final profit = profitCents;

    if (parsedSalePrice == null || parsedSalePrice == 0 || profit == null) {
      return null;
    }

    return profit / parsedSalePrice;
  }

  SaleTransaction? toSaleTransaction() {
    final item = selectedItem;
    final itemId = item?.id;
    final parsedSalePrice = salePriceCents;
    final selectedSaleDate = saleDate;

    if (item == null ||
        itemId == null ||
        itemId.trim().isEmpty ||
        parsedSalePrice == null ||
        parsedSalePrice < 0 ||
        selectedSaleDate == null) {
      return null;
    }

    final transaction = SaleTransaction(
      inventoryItemId: itemId,
      salePriceCents: parsedSalePrice,
      saleDate: selectedSaleDate,
      paymentMethod: paymentMethod,
      buyerContactId: buyerContactId,
      notes: _emptyToNull(notes),
      acquisitionValueCents: item.acquisitionValueCents,
    );

    return transaction.isValid ? transaction : null;
  }

  SellInventoryFormState copyWith({
    Object? selectedItem = _unset,
    String? salePrice,
    Object? saleDate = _unset,
    PaymentMethod? paymentMethod,
    Object? buyerContactId = _unset,
    String? notes,
  }) {
    return SellInventoryFormState(
      selectedItem: identical(selectedItem, _unset)
          ? this.selectedItem
          : selectedItem as InventoryItem?,
      salePrice: salePrice ?? this.salePrice,
      saleDate: identical(saleDate, _unset)
          ? this.saleDate
          : saleDate as DateTime?,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      buyerContactId: identical(buyerContactId, _unset)
          ? this.buyerContactId
          : buyerContactId as String?,
      notes: notes ?? this.notes,
    );
  }
}

const _unset = Object();

String? _emptyToNull(String value) {
  final trimmed = value.trim();

  return trimmed.isEmpty ? null : trimmed;
}
