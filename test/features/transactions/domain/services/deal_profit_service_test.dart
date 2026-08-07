import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_status.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/services/deal_profit_service.dart';

void main() {
  final parentSale = SaleTransaction(
    id: 'sale-a',
    inventoryItemId: 'bat-a',
    salePriceCents: 20000,
    tradeInCreditCents: 10000,
    saleDate: DateTime(2026, 8, 6),
    paymentMethod: PaymentMethod.cash,
    acquisitionValueCents: 15000,
  );

  const childItem = InventoryItem(
    id: 'bat-b',
    inventoryNumber: 'BAT-2608-0002',
    category: InventoryCategory.bat,
    brand: 'Sample',
    acquisitionType: AcquisitionType.traded,
    acquisitionValueCents: 10000,
    askingPriceCents: 20000,
    status: InventoryStatus.available,
  );

  const deal = Deal(
    id: 'deal-a',
    parentSaleTransactionId: 'sale-a',
    childInventoryItemIds: ['bat-b'],
  );

  test('open Deal reports parent profit and projected child profit', () {
    final summary = DealProfitService.calculate(
      deal: deal,
      parentSale: parentSale,
      childInventoryItems: const [childItem],
      childSales: const [],
    );

    expect(summary.status, DealStatus.open);
    expect(summary.parentTransactionProfitCents, 5000);
    expect(summary.realizedChildProfitCents, 0);
    expect(summary.projectedChildProfitCents, 10000);
    expect(summary.realizedDealProfitCents, 5000);
    expect(summary.projectedDealProfitCents, 15000);
  });

  test('completed Deal rolls child sale profit into parent Deal', () {
    final childSale = SaleTransaction(
      id: 'sale-b',
      inventoryItemId: 'bat-b',
      salePriceCents: 20000,
      saleDate: DateTime(2026, 8, 10),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 10000,
    );

    final summary = DealProfitService.calculate(
      deal: deal,
      parentSale: parentSale,
      childInventoryItems: const [childItem],
      childSales: [childSale],
    );

    expect(summary.status, DealStatus.completed);
    expect(summary.parentTransactionProfitCents, 5000);
    expect(summary.realizedChildProfitCents, 10000);
    expect(summary.realizedDealProfitCents, 15000);
    expect(summary.projectedDealProfitCents, 15000);
  });

  test('mixed child results produce partially realized status', () {
    const secondChild = InventoryItem(
      id: 'bat-c',
      category: InventoryCategory.bat,
      brand: 'Sample Two',
      acquisitionType: AcquisitionType.traded,
      acquisitionValueCents: 8000,
      askingPriceCents: 12000,
      status: InventoryStatus.available,
    );

    const multiChildDeal = Deal(
      id: 'deal-multi',
      parentSaleTransactionId: 'sale-a',
      childInventoryItemIds: ['bat-b', 'bat-c'],
    );

    final childSale = SaleTransaction(
      id: 'sale-b',
      inventoryItemId: 'bat-b',
      salePriceCents: 20000,
      saleDate: DateTime(2026, 8, 10),
      paymentMethod: PaymentMethod.cash,
      acquisitionValueCents: 10000,
    );

    final summary = DealProfitService.calculate(
      deal: multiChildDeal,
      parentSale: parentSale,
      childInventoryItems: const [childItem, secondChild],
      childSales: [childSale],
    );

    expect(summary.status, DealStatus.partiallyRealized);
    expect(summary.realizedDealProfitCents, 15000);
    expect(summary.projectedChildProfitCents, 4000);
    expect(summary.projectedDealProfitCents, 19000);
  });
}
