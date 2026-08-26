import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/contacts/application/contact_relationship.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  test(
    'builds confirmed totals without counting consignments as sold to us',
    () {
      final relationship = buildContactRelationship(
        contactId: 'contact-1',
        inventory: [
          _item('purchase', AcquisitionType.purchased, DateTime(2026, 1, 1)),
          _item('trade', AcquisitionType.traded, DateTime(2026, 2, 1)),
          _item(
            'consignment',
            AcquisitionType.consignment,
            DateTime(2026, 3, 1),
          ),
        ],
        sales: [
          SaleTransaction(
            id: 'sale-1',
            inventoryItemId: 'purchase',
            salePriceCents: 10000,
            acquisitionValueCents: 5000,
            saleDate: DateTime(2026, 4, 1),
            paymentMethod: PaymentMethod.cash,
            buyerContactId: 'contact-1',
          ),
        ],
        trades: [
          TradeTransaction(
            id: 'trade-1',
            outgoingInventoryItemIds: const ['purchase'],
            incomingInventoryItemIds: const ['trade'],
            tradeDate: DateTime(2026, 2, 1),
            contactId: 'contact-1',
          ),
        ],
        consignments: [
          ConsignmentTransaction(
            id: 'consignment-1',
            inventoryItemId: 'consignment',
            consignmentDate: DateTime(2026, 3, 1),
            commissionCents: 2500,
            consignorContactId: 'contact-1',
          ),
        ],
      );

      expect(relationship.boughtFromUsCount, 1);
      expect(relationship.soldToUsCount, 2);
      expect(relationship.consignmentCount, 1);
      expect(relationship.history.map((entry) => entry.type), [
        ContactHistoryType.sale,
        ContactHistoryType.consignment,
        ContactHistoryType.trade,
        ContactHistoryType.purchase,
      ]);
    },
  );

  test(
    'does not duplicate traded or consigned inventory as acquisition events',
    () {
      final relationship = buildContactRelationship(
        contactId: 'contact-1',
        inventory: [
          _item('trade', AcquisitionType.traded, DateTime(2026, 2, 1)),
          _item(
            'consignment',
            AcquisitionType.consignment,
            DateTime(2026, 3, 1),
          ),
        ],
        sales: const [],
        trades: [
          TradeTransaction(
            id: 'trade-1',
            outgoingInventoryItemIds: const [],
            incomingInventoryItemIds: const ['trade'],
            tradeDate: DateTime(2026, 2, 1),
            contactId: 'contact-1',
          ),
        ],
        consignments: [
          ConsignmentTransaction(
            id: 'consignment-1',
            inventoryItemId: 'consignment',
            consignmentDate: DateTime(2026, 3, 1),
            commissionCents: 2500,
            consignorContactId: 'contact-1',
          ),
        ],
      );

      expect(relationship.history, hasLength(2));
      expect(relationship.history.map((entry) => entry.type).toSet(), {
        ContactHistoryType.trade,
        ContactHistoryType.consignment,
      });
    },
  );

  test('places undated purchases after dated history', () {
    final relationship = buildContactRelationship(
      contactId: 'contact-1',
      inventory: [_item('purchase', AcquisitionType.purchased, null)],
      sales: [
        SaleTransaction(
          inventoryItemId: 'other',
          salePriceCents: 10000,
          acquisitionValueCents: 5000,
          saleDate: DateTime(2026, 4, 1),
          paymentMethod: PaymentMethod.cash,
          buyerContactId: 'contact-1',
        ),
      ],
      trades: const [],
      consignments: const [],
    );

    expect(relationship.history.first.type, ContactHistoryType.sale);
    expect(relationship.history.last.date, isNull);
  });
}

InventoryItem _item(String id, AcquisitionType type, DateTime? date) {
  return InventoryItem(
    id: id,
    inventoryNumber: id.toUpperCase(),
    category: InventoryCategory.bat,
    brand: 'Test Brand',
    model: id,
    acquisitionType: type,
    acquisitionValueCents: 5000,
    purchaseDate: date,
    sellerContactId: 'contact-1',
  );
}
