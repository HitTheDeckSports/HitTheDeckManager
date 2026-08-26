import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../transactions/domain/models/consignment_transaction.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import '../../transactions/domain/models/trade_transaction.dart';

enum ContactHistoryType { sale, purchase, trade, consignment }

class ContactHistoryEntry {
  const ContactHistoryEntry({
    required this.type,
    required this.title,
    required this.description,
    this.date,
    this.inventoryItemId,
    this.transactionId,
  });

  final ContactHistoryType type;
  final String title;
  final String description;
  final DateTime? date;
  final String? inventoryItemId;
  final String? transactionId;
}

class ContactRelationship {
  const ContactRelationship({
    required this.boughtFromUsCount,
    required this.soldToUsCount,
    required this.consignmentCount,
    required this.history,
  });

  const ContactRelationship.empty()
    : boughtFromUsCount = 0,
      soldToUsCount = 0,
      consignmentCount = 0,
      history = const [];

  final int boughtFromUsCount;
  final int soldToUsCount;
  final int consignmentCount;
  final List<ContactHistoryEntry> history;
}

ContactRelationship buildContactRelationship({
  required String contactId,
  required List<InventoryItem> inventory,
  required List<SaleTransaction> sales,
  required List<TradeTransaction> trades,
  required List<ConsignmentTransaction> consignments,
}) {
  final normalizedContactId = contactId.trim();
  if (normalizedContactId.isEmpty) return const ContactRelationship.empty();

  final inventoryById = <String, InventoryItem>{};
  for (final item in inventory) {
    final id = _normalizedId(item.id);
    if (id != null) inventoryById[id] = item;
  }
  final linkedInventory = inventory
      .where(
        (item) => _normalizedId(item.sellerContactId) == normalizedContactId,
      )
      .toList(growable: false);
  final linkedSales = sales
      .where(
        (sale) => _normalizedId(sale.buyerContactId) == normalizedContactId,
      )
      .toList(growable: false);
  final linkedTrades = trades
      .where((trade) => _normalizedId(trade.contactId) == normalizedContactId)
      .toList(growable: false);
  final linkedConsignments = consignments
      .where(
        (consignment) =>
            _normalizedId(consignment.consignorContactId) ==
            normalizedContactId,
      )
      .toList(growable: false);

  final soldToUsCount = linkedInventory
      .where((item) => item.acquisitionType != AcquisitionType.consignment)
      .length;

  final history = <ContactHistoryEntry>[
    for (final sale in linkedSales)
      ContactHistoryEntry(
        type: ContactHistoryType.sale,
        title: 'Bought From Us',
        description: _inventoryDisplayName(inventoryById[sale.inventoryItemId]),
        date: sale.saleDate,
        inventoryItemId: sale.inventoryItemId,
        transactionId: sale.id,
      ),
    for (final item in linkedInventory)
      if (item.acquisitionType == AcquisitionType.purchased)
        ContactHistoryEntry(
          type: ContactHistoryType.purchase,
          title: 'Sold To Us',
          description: _inventoryDisplayName(item),
          date: item.purchaseDate,
          inventoryItemId: item.id,
        ),
    for (final trade in linkedTrades)
      ContactHistoryEntry(
        type: ContactHistoryType.trade,
        title: _normalizedId(trade.saleTransactionId) == null
            ? 'Trade-In'
            : 'Trade-In With Sale',
        description: _tradeDescription(trade, inventoryById),
        date: trade.tradeDate,
        transactionId: trade.id,
      ),
    for (final consignment in linkedConsignments)
      ContactHistoryEntry(
        type: ContactHistoryType.consignment,
        title: 'Consignment',
        description: _inventoryDisplayName(
          inventoryById[consignment.inventoryItemId],
        ),
        date: consignment.consignmentDate,
        inventoryItemId: consignment.inventoryItemId,
        transactionId: consignment.id,
      ),
  ]..sort(_compareHistoryEntries);

  return ContactRelationship(
    boughtFromUsCount: linkedSales.length,
    soldToUsCount: soldToUsCount,
    consignmentCount: linkedConsignments.length,
    history: List.unmodifiable(history),
  );
}

int _compareHistoryEntries(
  ContactHistoryEntry first,
  ContactHistoryEntry second,
) {
  final firstDate = first.date;
  final secondDate = second.date;
  if (firstDate == null && secondDate == null) {
    return first.title.compareTo(second.title);
  }
  if (firstDate == null) return 1;
  if (secondDate == null) return -1;
  final dateComparison = secondDate.compareTo(firstDate);
  return dateComparison != 0
      ? dateComparison
      : first.title.compareTo(second.title);
}

String _tradeDescription(
  TradeTransaction trade,
  Map<String, InventoryItem> inventoryById,
) {
  final incoming = trade.incomingInventoryItemIds
      .map((id) => _inventoryDisplayName(inventoryById[id]))
      .join(', ');
  final outgoing = trade.outgoingInventoryItemIds
      .map((id) => _inventoryDisplayName(inventoryById[id]))
      .join(', ');
  if (incoming.isNotEmpty && outgoing.isNotEmpty) {
    return 'Received: $incoming; Provided: $outgoing';
  }
  if (incoming.isNotEmpty) return 'Received: $incoming';
  if (outgoing.isNotEmpty) return 'Provided: $outgoing';
  return 'Inventory details unavailable';
}

String _inventoryDisplayName(InventoryItem? item) {
  if (item == null) return 'Inventory record unavailable';
  final model = item.model?.trim();
  final name = model == null || model.isEmpty
      ? item.brand
      : '${item.brand} $model';
  final number = item.inventoryNumber?.trim();
  return number == null || number.isEmpty ? name : '$number - $name';
}

String? _normalizedId(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
