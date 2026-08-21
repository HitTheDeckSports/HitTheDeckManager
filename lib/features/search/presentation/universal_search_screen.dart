import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../contacts/presentation/providers/contact_providers.dart';
import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../../transactions/domain/models/deal.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import '../../transactions/presentation/providers/deal_providers.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../application/universal_search.dart';

final universalSearchEntriesProvider =
    Provider<AsyncValue<List<UniversalSearchEntry>>>((ref) {
      final inventoryAsync = ref.watch(inventoryItemsProvider);
      final contactsAsync = ref.watch(contactsProvider);
      final salesAsync = ref.watch(saleTransactionsProvider);
      final dealsAsync = ref.watch(dealsProvider);

      final values = [inventoryAsync, contactsAsync, salesAsync, dealsAsync];

      for (final value in values) {
        if (value.hasError) {
          return AsyncValue.error(
            value.error!,
            value.stackTrace ?? StackTrace.current,
          );
        }
      }

      if (values.any((value) => value.isLoading)) {
        return const AsyncValue.loading();
      }

      final inventoryItems = inventoryAsync.requireValue;
      final contacts = contactsAsync.requireValue;
      final sales = salesAsync.requireValue;
      final deals = dealsAsync.requireValue;

      final inventoryById = <String, InventoryItem>{
        for (final item in inventoryItems)
          if (item.id != null && item.id!.trim().isNotEmpty) item.id!: item,
      };

      final contactNameById = <String, String>{
        for (final contact in contacts)
          if (contact.id != null && contact.id!.trim().isNotEmpty)
            contact.id!: contact.name,
      };

      return AsyncValue.data([
        for (final item in inventoryItems)
          if (item.id != null && item.id!.trim().isNotEmpty)
            _inventoryEntry(item),
        for (final contact in contacts)
          if (contact.id != null && contact.id!.trim().isNotEmpty)
            UniversalSearchEntry(
              type: UniversalSearchResultType.contact,
              id: contact.id!,
              title: contact.name,
              subtitle: contact.email ?? contact.phone,
              searchText: [
                contact.name,
                contact.phone,
                contact.email,
                contact.address,
                contact.notes,
              ].whereType<String>().join(' '),
            ),
        for (final sale in sales)
          if (sale.id != null && sale.id!.trim().isNotEmpty)
            _saleEntry(
              sale,
              item: inventoryById[sale.inventoryItemId],
              buyerName: sale.buyerContactId == null
                  ? null
                  : contactNameById[sale.buyerContactId!],
            ),
        for (final deal in deals)
          if (deal.id != null && deal.id!.trim().isNotEmpty)
            _dealEntry(deal, inventoryById: inventoryById),
      ]);
    });

UniversalSearchEntry _inventoryEntry(InventoryItem item) {
  final model = item.model?.trim();
  final title = model == null || model.isEmpty
      ? item.brand
      : '${item.brand} $model';

  return UniversalSearchEntry(
    type: UniversalSearchResultType.inventory,
    id: item.id!,
    title: title,
    subtitle: item.inventoryNumber ?? item.category.label,
    searchText: [
      item.inventoryNumber,
      item.brand,
      item.model,
      item.category.label,
      item.status.label,
      item.condition?.label,
      item.certification,
      item.notes,
    ].whereType<String>().join(' '),
  );
}

UniversalSearchEntry _saleEntry(
  SaleTransaction sale, {
  required InventoryItem? item,
  required String? buyerName,
}) {
  final inventoryNumber = item?.inventoryNumber ?? sale.inventoryItemId;
  final itemName = item == null
      ? null
      : (item.model == null || item.model!.trim().isEmpty
            ? item.brand
            : '${item.brand} ${item.model}');

  return UniversalSearchEntry(
    type: UniversalSearchResultType.transaction,
    id: sale.id!,
    title: 'Sale $inventoryNumber',
    subtitle: buyerName ?? itemName,
    searchText: [
      'sale',
      inventoryNumber,
      itemName,
      buyerName,
      sale.buyerContactId,
      sale.paymentMethod.name,
      sale.notes,
      sale.saleDate.toIso8601String(),
    ].whereType<String>().join(' '),
  );
}

UniversalSearchEntry _dealEntry(
  Deal deal, {
  required Map<String, InventoryItem> inventoryById,
}) {
  final childText = [
    for (final childId in deal.childInventoryItemIds) ...[
      childId,
      inventoryById[childId]?.inventoryNumber,
      inventoryById[childId]?.brand,
      inventoryById[childId]?.model,
    ],
  ].whereType<String>().join(' ');

  return UniversalSearchEntry(
    type: UniversalSearchResultType.deal,
    id: deal.id!,
    title: 'Deal',
    subtitle: 'Parent sale ${deal.parentSaleTransactionId}',
    searchText: [
      'deal',
      deal.parentSaleTransactionId,
      childText,
      deal.notes,
    ].whereType<String>().join(' '),
  );
}

class UniversalSearchScreen extends ConsumerStatefulWidget {
  const UniversalSearchScreen({this.entriesOverride, super.key});

  final List<UniversalSearchEntry>? entriesOverride;

  @override
  ConsumerState<UniversalSearchScreen> createState() =>
      _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends ConsumerState<UniversalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesOverride = widget.entriesOverride;

    if (entriesOverride != null) {
      return _buildPage(context, entriesOverride);
    }

    final entriesAsync = ref.watch(universalSearchEntriesProvider);

    return entriesAsync.when(
      loading: () => const AppPage(
        title: 'Search',
        subtitle: 'Search across inventory, contacts, transactions, and deals.',
        child: AppLoadingState(message: 'Loading searchable records...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Search',
        subtitle: 'Search across inventory, contacts, transactions, and deals.',
        child: AppErrorState(
          message: 'Unable to load searchable records.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(universalSearchEntriesProvider);
          },
        ),
      ),
      data: (entries) => _buildPage(context, entries),
    );
  }

  Widget _buildPage(BuildContext context, List<UniversalSearchEntry> entries) {
    final results = UniversalSearch.filter(entries, _query);
    final grouped = UniversalSearch.group(results);
    final hasQuery = _query.trim().isNotEmpty;

    return AppPage(
      title: 'Search',
      subtitle: 'Search across inventory, contacts, transactions, and deals.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('universalSearchField'),
            controller: _controller,
            autofocus: true,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Inventory #, equipment, contact, transaction...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      key: const Key('universalSearchClearButton'),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (!hasQuery)
            const AppEmptyState(
              icon: Icons.search,
              title: 'Search Hit the Deck Manager',
              message:
                  'Enter a name, inventory number, equipment model, or other record detail.',
            )
          else if (results.isEmpty)
            const AppEmptyState(
              icon: Icons.search_off,
              title: 'No matching records.',
              message: 'Try a different search term.',
            )
          else ...[
            Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              key: const Key('universalSearchResultCount'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final type in UniversalSearchResultType.values)
              if (grouped[type]?.isNotEmpty ?? false)
                _SearchResultSection(
                  type: type,
                  entries: grouped[type]!,
                  onTap: (entry) => _openResult(context, entry),
                ),
          ],
        ],
      ),
    );
  }

  void _openResult(BuildContext context, UniversalSearchEntry entry) {
    switch (entry.type) {
      case UniversalSearchResultType.inventory:
        context.goNamed(
          AppRouteNames.inventoryDetail,
          pathParameters: {'itemId': entry.id},
        );
      case UniversalSearchResultType.contact:
        context.goNamed(
          AppRouteNames.contactDetail,
          pathParameters: {'contactId': entry.id},
        );
      case UniversalSearchResultType.transaction:
        context.goNamed(
          AppRouteNames.transactionDetail,
          pathParameters: {'transactionId': entry.id},
        );
      case UniversalSearchResultType.deal:
        context.goNamed(
          AppRouteNames.dealDetail,
          pathParameters: {'dealId': entry.id},
        );
    }
  }
}

class _SearchResultSection extends StatelessWidget {
  const _SearchResultSection({
    required this.type,
    required this.entries,
    required this.onTap,
  });

  final UniversalSearchResultType type;
  final List<UniversalSearchEntry> entries;
  final ValueChanged<UniversalSearchEntry> onTap;

  String get _title => switch (type) {
    UniversalSearchResultType.inventory => 'Inventory',
    UniversalSearchResultType.contact => 'Contacts',
    UniversalSearchResultType.transaction => 'Transactions',
    UniversalSearchResultType.deal => 'Deals',
  };

  IconData get _icon => switch (type) {
    UniversalSearchResultType.inventory => Icons.inventory_2_outlined,
    UniversalSearchResultType.contact => Icons.people_outline,
    UniversalSearchResultType.transaction => Icons.receipt_long_outlined,
    UniversalSearchResultType.deal => Icons.handshake_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final entry in entries)
            Card(
              child: ListTile(
                key: ValueKey('universalSearchResult-${type.name}-${entry.id}'),
                leading: Icon(_icon),
                title: Text(entry.title),
                subtitle: entry.subtitle == null ? null : Text(entry.subtitle!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTap(entry),
              ),
            ),
        ],
      ),
    );
  }
}
