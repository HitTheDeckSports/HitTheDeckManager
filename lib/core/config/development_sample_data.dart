import '../../features/contacts/domain/models/contact.dart';
import '../../features/inventory/domain/models/inventory_enums.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import '../../features/transactions/domain/models/deal.dart';
import '../../features/transactions/domain/models/repair_transaction.dart';
import '../../features/transactions/domain/models/sale_transaction.dart';
import '../../features/transactions/domain/models/trade_transaction.dart';
import '../../features/transactions/domain/models/transaction_enums.dart';

abstract final class DevelopmentSampleData {
  static List<Contact> createContacts() {
    return const [
      Contact(
        id: 'sample-contact-alex',
        name: 'Alex Johnson',
        phone: '555-210-1001',
        email: 'alex.johnson@example.com',
        address: '1207 Oak Ridge Drive, Houston, TX 77084',
        notes: 'Repeat customer who buys BBCOR bats.',
      ),
      Contact(
        id: 'sample-contact-taylor',
        name: 'Taylor Morgan',
        phone: '555-210-1002',
        email: 'taylor.morgan@example.com',
        address: '4450 Westfield Lane, Katy, TX 77449',
        notes: 'Bought the sample Meta and traded in a Wilson A2000.',
      ),
      Contact(
        id: 'sample-contact-jordan',
        name: 'Jordan Lee',
        phone: '555-210-1003',
        email: 'jordan.lee@example.com',
        address: '987 Pine Hollow Road, Cypress, TX 77429',
        notes: 'Consignment customer for catcherâ€™s equipment.',
      ),
      Contact(
        id: 'sample-contact-casey',
        name: 'Casey Ramirez',
        phone: '555-210-1004',
        notes: 'Sample contact with only a name and phone.',
      ),
    ];
  }

  static List<InventoryItem> createInventoryItems() {
    return [
      InventoryItem(
        id: 'sample-item-available-bat',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        condition: InventoryCondition.likeNew,
        status: InventoryStatus.available,
        purchaseDate: DateTime(2026, 8, 1),
        newValueCents: 49999,
        askingPriceCents: 32500,
        minimumPriceCents: 27500,
        sellerContactId: 'sample-contact-alex',
        notes: 'Development sample: available BBCOR bat.',
        lengthInches: 32,
        weightOunces: 29,
        drop: -3,
        certification: 'BBCOR',
      ),
      InventoryItem(
        id: 'sample-item-available-glove',
        inventoryNumber: 'GLV-2608-0001',
        category: InventoryCategory.glove,
        brand: 'Wilson',
        model: 'A2000',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 14000,
        condition: InventoryCondition.good,
        status: InventoryStatus.available,
        purchaseDate: DateTime(2026, 8, 3),
        newValueCents: 29999,
        askingPriceCents: 22500,
        minimumPriceCents: 19000,
        sellerContactId: 'sample-contact-taylor',
        notes: 'Development sample: trade-in received with the Meta sale.',
        gloveSizeInches: 11.5,
        handOrientation: 'Right Hand Throw',
      ),
      InventoryItem(
        id: 'sample-item-inactive-helmet',
        inventoryNumber: 'HLM-2608-0001',
        category: InventoryCategory.helmet,
        brand: 'Rawlings',
        model: 'Mach',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 5000,
        condition: InventoryCondition.good,
        status: InventoryStatus.inactive,
        purchaseDate: DateTime(2026, 7, 25),
        newValueCents: 7999,
        askingPriceCents: 6500,
        sellerContactId: 'sample-contact-casey',
        notes: 'Development sample: inactive helmet.',
      ),
      InventoryItem(
        id: 'sample-item-broken-bat',
        inventoryNumber: 'BAT-2607-0001',
        category: InventoryCategory.bat,
        brand: 'Easton',
        model: 'Hype Fire',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 17500,
        condition: InventoryCondition.fair,
        status: InventoryStatus.broken,
        purchaseDate: DateTime(2026, 7, 20),
        newValueCents: 34999,
        askingPriceCents: 22500,
        sellerContactId: 'sample-contact-alex',
        notes: 'Development sample: broken bat requiring review.',
        lengthInches: 31,
        weightOunces: 26,
        drop: -5,
        certification: 'USSSA',
      ),
      InventoryItem(
        id: 'sample-item-sold-bat',
        inventoryNumber: 'BAT-2607-0002',
        category: InventoryCategory.bat,
        brand: 'Louisville Slugger',
        model: 'Meta',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 21000,
        condition: InventoryCondition.likeNew,
        status: InventoryStatus.sold,
        purchaseDate: DateTime(2026, 7, 15),
        newValueCents: 49999,
        askingPriceCents: 34000,
        minimumPriceCents: 30000,
        sellerContactId: 'sample-contact-alex',
        notes: 'Development sample: sold BBCOR bat with a trade-in.',
        lengthInches: 33,
        weightOunces: 30,
        drop: -3,
        certification: 'BBCOR',
      ),
      InventoryItem(
        id: 'sample-item-sold-catchers-gear',
        inventoryNumber: 'CTG-2607-0001',
        category: InventoryCategory.catchersGear,
        brand: 'All-Star',
        model: 'System7 Axis',
        acquisitionType: AcquisitionType.consignment,
        acquisitionValueCents: 15000,
        condition: InventoryCondition.good,
        status: InventoryStatus.sold,
        purchaseDate: DateTime(2026, 7, 10),
        newValueCents: 39999,
        askingPriceCents: 26000,
        minimumPriceCents: 22500,
        sellerContactId: 'sample-contact-jordan',
        notes: 'Development sample: sold catcherâ€™s gear set.',
        catchersGearSize: 'Intermediate',
      ),
    ];
  }

  static List<SaleTransaction> createSales() {
    return [
      SaleTransaction(
        id: 'sample-sale-bat',
        inventoryItemId: 'sample-item-sold-bat',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 3),
        paymentMethod: PaymentMethod.venmo,
        buyerContactId: 'sample-contact-taylor',
        tradeInCreditCents: 14000,
        notes: 'Development sample sale completed at a tournament.',
        acquisitionValueCents: 21000,
      ),
      SaleTransaction(
        id: 'sample-sale-catchers-gear',
        inventoryItemId: 'sample-item-sold-catchers-gear',
        salePriceCents: 25000,
        saleDate: DateTime(2026, 8, 2),
        paymentMethod: PaymentMethod.cash,
        buyerContactId: 'sample-contact-casey',
        notes: 'Development sample sale for catcherâ€™s gear.',
        acquisitionValueCents: 15000,
      ),
    ];
  }

  static List<RepairTransaction> createRepairs() {
    return [
      RepairTransaction(
        id: 'sample-repair-broken-bat',
        inventoryItemId: 'sample-item-broken-bat',
        repairDate: DateTime(2026, 7, 28),
        costCents: 3500,
        description: 'Replaced damaged grip and inspected barrel.',
        notes: 'Bat remains broken pending a final barrel decision.',
      ),
      RepairTransaction(
        id: 'sample-repair-available-bat',
        inventoryItemId: 'sample-item-available-bat',
        repairDate: DateTime(2026, 8, 2),
        costCents: 1200,
        description: 'Installed a new premium bat grip.',
      ),
    ];
  }

  static List<Deal> createDeals() {
    return const [
      Deal(
        id: 'sample-deal-meta-sale',
        parentSaleTransactionId: 'sample-sale-bat',
        childInventoryItemIds: ['sample-item-available-glove'],
        notes:
            'Development sample Deal for the Meta and Wilson A2000 trade-in.',
      ),
    ];
  }

  static List<TradeTransaction> createTrades() {
    return [
      TradeTransaction(
        id: 'sample-trade-meta-sale',
        saleTransactionId: 'sample-sale-bat',
        outgoingInventoryItemIds: const ['sample-item-sold-bat'],
        incomingInventoryItemIds: const ['sample-item-available-glove'],
        tradeDate: DateTime(2026, 8, 3),
        contactId: 'sample-contact-taylor',
        notes: 'Wilson A2000 received as part of the Meta sale.',
      ),
    ];
  }
}
