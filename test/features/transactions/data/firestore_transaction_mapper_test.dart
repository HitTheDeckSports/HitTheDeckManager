import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/data/mappers/firestore_transaction_mapper.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/consignment_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/trade_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';

void main() {
  group('FirestoreTransactionMapper', () {
    test('serializes sale transaction', () {
      final transaction = SaleTransaction(
        inventoryItemId: 'inventory-1',
        salePriceCents: 32500,
        saleDate: DateTime.utc(2026, 8, 11),
        paymentMethod: PaymentMethod.venmo,
        buyerContactId: 'contact-1',
        notes: 'Sale note',
        acquisitionValueCents: 20000,
        tradeInCreditCents: 5000,
      );

      final data = FirestoreTransactionMapper.saleToFirestore(transaction);

      expect(data['inventoryItemId'], 'inventory-1');
      expect(data['salePriceCents'], 32500);
      expect(data['saleDate'], isA<Timestamp>());
      expect(data['paymentMethod'], 'venmo');
      expect(data['buyerContactId'], 'contact-1');
      expect(data['acquisitionValueCents'], 20000);
      expect(data['tradeInCreditCents'], 5000);
    });

    test('serializes repair transaction', () {
      final transaction = RepairTransaction(
        inventoryItemId: 'inventory-1',
        repairDate: DateTime.utc(2026, 8, 10),
        costCents: 2500,
        description: '  Replace grip  ',
        notes: 'Repair note',
      );

      final data = FirestoreTransactionMapper.repairToFirestore(transaction);

      expect(data['inventoryItemId'], 'inventory-1');
      expect(data['costCents'], 2500);
      expect(data['description'], 'Replace grip');
      expect(data['repairDate'], isA<Timestamp>());
    });

    test('serializes consignment transaction', () {
      final transaction = ConsignmentTransaction(
        inventoryItemId: 'inventory-2',
        consignmentDate: DateTime.utc(2026, 8, 9),
        commissionCents: 5000,
        consignorContactId: 'contact-2',
        notes: 'Consignment note',
      );

      final data = FirestoreTransactionMapper.consignmentToFirestore(
        transaction,
      );

      expect(data['inventoryItemId'], 'inventory-2');
      expect(data['commissionCents'], 5000);
      expect(data['consignorContactId'], 'contact-2');
      expect(data['consignmentDate'], isA<Timestamp>());
    });

    test('serializes disposal transaction', () {
      final transaction = DisposalTransaction(
        inventoryItemId: 'inventory-3',
        disposalDate: DateTime.utc(2026, 8, 8),
        reason: DisposalReason.warrantyReplacement,
        replacementInventoryItemId: 'inventory-4',
        notes: 'Warranty replacement',
      );

      final data = FirestoreTransactionMapper.disposalToFirestore(transaction);

      expect(data['inventoryItemId'], 'inventory-3');
      expect(data['reason'], 'warrantyReplacement');
      expect(data['replacementInventoryItemId'], 'inventory-4');
      expect(data['disposalDate'], isA<Timestamp>());
    });

    test('serializes trade transaction', () {
      final transaction = TradeTransaction(
        outgoingInventoryItemIds: const ['inventory-5'],
        incomingInventoryItemIds: const ['inventory-6', 'inventory-7'],
        tradeDate: DateTime.utc(2026, 8, 7),
        contactId: 'contact-3',
        cashReceivedCents: 10000,
        paymentMethod: PaymentMethod.cash,
        notes: 'Trade note',
      );

      final data = FirestoreTransactionMapper.tradeToFirestore(transaction);

      expect(data['outgoingInventoryItemIds'], const ['inventory-5']);
      expect(data['incomingInventoryItemIds'], const [
        'inventory-6',
        'inventory-7',
      ]);
      expect(data['cashPaidCents'], 0);
      expect(data['cashReceivedCents'], 10000);
      expect(data['paymentMethod'], 'cash');
      expect(data['tradeDate'], isA<Timestamp>());
    });

    test('converts blank optional strings to null', () {
      final transaction = SaleTransaction(
        inventoryItemId: 'inventory-1',
        salePriceCents: 10000,
        saleDate: DateTime.utc(2026, 8, 11),
        paymentMethod: PaymentMethod.cash,
        buyerContactId: '   ',
        notes: '',
        acquisitionValueCents: 5000,
      );

      final data = FirestoreTransactionMapper.saleToFirestore(transaction);

      expect(data['buyerContactId'], isNull);
      expect(data['notes'], isNull);
    });
  });
}
