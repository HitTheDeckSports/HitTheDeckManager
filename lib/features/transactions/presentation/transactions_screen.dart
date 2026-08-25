import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/consignment_transaction.dart';
import '../domain/models/disposal_reason.dart';
import '../domain/models/disposal_transaction.dart';
import '../domain/models/repair_transaction.dart';
import '../domain/models/sale_transaction.dart';
import '../domain/models/trade_transaction.dart';
import '../domain/models/transaction_enums.dart';
import 'providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _LedgerType _typeFilter = _LedgerType.all;
  _LedgerDateFilter _dateFilter = _LedgerDateFilter.all;

  bool get _hasActiveFilters =>
      _query.trim().isNotEmpty ||
      _typeFilter != _LedgerType.all ||
      _dateFilter != _LedgerDateFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _typeFilter = _LedgerType.all;
      _dateFilter = _LedgerDateFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(saleTransactionsProvider);
    final repairsAsync = ref.watch(repairTransactionsProvider);
    final tradesAsync = ref.watch(tradeTransactionsProvider);
    final disposalsAsync = ref.watch(disposalTransactionsProvider);
    final consignmentsAsync = ref.watch(consignmentTransactionsProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);

    final asyncValues = <AsyncValue<Object?>>[
      salesAsync,
      repairsAsync,
      tradesAsync,
      disposalsAsync,
      consignmentsAsync,
      inventoryAsync,
    ];

    if (asyncValues.any((value) => value.isLoading)) {
      return const AppPage(
        title: 'Transactions',
        subtitle: 'Review the complete business-event ledger.',
        child: AppLoadingState(message: 'Loading transactions...'),
      );
    }

    final firstError = asyncValues
        .where((value) => value.hasError)
        .map((value) => value.error)
        .firstOrNull;

    if (firstError != null) {
      return AppPage(
        title: 'Transactions',
        subtitle: 'Review the complete business-event ledger.',
        child: AppErrorState(
          message: 'Unable to load transaction history.',
          details: firstError.toString(),
          onRetry: () {
            ref.invalidate(saleTransactionsProvider);
            ref.invalidate(repairTransactionsProvider);
            ref.invalidate(tradeTransactionsProvider);
            ref.invalidate(disposalTransactionsProvider);
            ref.invalidate(consignmentTransactionsProvider);
            ref.invalidate(inventoryItemsProvider);
          },
        ),
      );
    }

    final inventoryById = <String, InventoryItem>{
      for (final item in inventoryAsync.requireValue)
        if (item.id != null) item.id!: item,
    };

    final entries = _buildLedgerEntries(
      sales: salesAsync.requireValue,
      repairs: repairsAsync.requireValue,
      trades: tradesAsync.requireValue,
      disposals: disposalsAsync.requireValue,
      consignments: consignmentsAsync.requireValue,
      inventoryById: inventoryById,
    );

    if (entries.isEmpty) {
      return const AppPage(
        title: 'Transactions',
        subtitle: 'Review the complete business-event ledger.',
        child: AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No transactions yet.',
          message:
              'Completed sales and other business transactions will appear here.',
        ),
      );
    }

    final filteredEntries = entries.where(_matchesFilters).toList();

    return AppPage(
      title: 'Transactions',
      subtitle: 'Review the complete business-event ledger.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('transactionsSearchField'),
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search Transactions',
              hintText: 'Inventory number, item, type, description, reason...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.trim().isEmpty
                  ? null
                  : IconButton(
                      key: const Key('transactionsSearchClearButton'),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                key: const Key('transactionsTypeFilter'),
                width: 220,
                child: DropdownButtonFormField<_LedgerType>(
                  key: ValueKey(_typeFilter),
                  isExpanded: true,
                  initialValue: _typeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final type in _LedgerType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _typeFilter = value;
                    });
                  },
                ),
              ),
              SizedBox(
                key: const Key('transactionsDateFilter'),
                width: 220,
                child: DropdownButtonFormField<_LedgerDateFilter>(
                  key: ValueKey(_dateFilter),
                  isExpanded: true,
                  initialValue: _dateFilter,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final filter in _LedgerDateFilter.values)
                      DropdownMenuItem(
                        value: filter,
                        child: Text(filter.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _dateFilter = value;
                    });
                  },
                ),
              ),
              if (_hasActiveFilters)
                TextButton.icon(
                  key: const Key('transactionsClearFiltersButton'),
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Clear Filters'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters
                ? '${filteredEntries.length} of ${entries.length} transactions'
                : '${entries.length} transaction${entries.length == 1 ? '' : 's'}',
            key: const Key('transactionsResultCount'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (filteredEntries.isEmpty)
            const AppEmptyState(
              icon: Icons.search_off,
              title: 'No transactions match your filters.',
              message: 'Clear or adjust the search, type, or date filter.',
            )
          else
            for (final entry in filteredEntries) ...[
              _buildLedgerCard(
                entry,
                inventoryById,
                permissions.canViewFinancialData,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  bool _matchesFilters(_LedgerEntry entry) {
    if (_typeFilter != _LedgerType.all && entry.type != _typeFilter) {
      return false;
    }

    final cutoff = _dateFilter.cutoff(DateTime.now());
    if (cutoff != null && entry.date.isBefore(cutoff)) {
      return false;
    }

    final query = _query.trim().toLowerCase();
    return query.isEmpty || entry.searchableText.contains(query);
  }
}

List<_LedgerEntry> _buildLedgerEntries({
  required List<SaleTransaction> sales,
  required List<RepairTransaction> repairs,
  required List<TradeTransaction> trades,
  required List<DisposalTransaction> disposals,
  required List<ConsignmentTransaction> consignments,
  required Map<String, InventoryItem> inventoryById,
}) {
  final entries = <_LedgerEntry>[
    for (final sale in sales)
      _LedgerEntry(
        type: _LedgerType.sale,
        date: sale.saleDate,
        transaction: sale,
        searchableText: _searchableText([
          'sale',
          _formatDate(sale.saleDate),
          _inventoryDisplayName(inventoryById[sale.inventoryItemId]),
          sale.paymentMethod.label,
          sale.notes,
        ]),
      ),
    for (final trade in trades)
      _LedgerEntry(
        type: _LedgerType.trade,
        date: trade.tradeDate,
        transaction: trade,
        searchableText: _searchableText([
          'trade trade-in',
          _formatDate(trade.tradeDate),
          ...trade.outgoingInventoryItemIds.map(
            (id) => _inventoryDisplayName(inventoryById[id]),
          ),
          ...trade.incomingInventoryItemIds.map(
            (id) => _inventoryDisplayName(inventoryById[id]),
          ),
          trade.paymentMethod?.label,
          trade.notes,
        ]),
      ),
    for (final repair in repairs)
      _LedgerEntry(
        type: _LedgerType.repair,
        date: repair.repairDate,
        transaction: repair,
        searchableText: _searchableText([
          'repair',
          _formatDate(repair.repairDate),
          _inventoryDisplayName(inventoryById[repair.inventoryItemId]),
          repair.description,
          repair.notes,
        ]),
      ),
    for (final disposal in disposals)
      _LedgerEntry(
        type: _LedgerType.disposal,
        date: disposal.disposalDate,
        transaction: disposal,
        searchableText: _searchableText([
          'disposal',
          _formatDate(disposal.disposalDate),
          _inventoryDisplayName(inventoryById[disposal.inventoryItemId]),
          disposal.reason.label,
          disposal.notes,
          if (disposal.replacementInventoryItemId != null)
            'warranty replacement',
        ]),
      ),
    for (final consignment in consignments)
      _LedgerEntry(
        type: _LedgerType.consignment,
        date: consignment.consignmentDate,
        transaction: consignment,
        searchableText: _searchableText([
          'consignment',
          _formatDate(consignment.consignmentDate),
          _inventoryDisplayName(inventoryById[consignment.inventoryItemId]),
          consignment.isCompleted ? 'sold completed' : 'awaiting sale',
          consignment.notes,
        ]),
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));

  return entries;
}

Widget _buildLedgerCard(
  _LedgerEntry entry,
  Map<String, InventoryItem> inventoryById,
  bool canViewFinancialData,
) {
  final transaction = entry.transaction;

  if (transaction is SaleTransaction) {
    return _SaleTransactionCard(
      sale: transaction,
      inventoryItem: inventoryById[transaction.inventoryItemId],
      canViewFinancialData: canViewFinancialData,
    );
  }
  if (transaction is TradeTransaction) {
    return _TradeTransactionCard(
      trade: transaction,
      inventoryById: inventoryById,
    );
  }
  if (transaction is RepairTransaction) {
    return _RepairTransactionCard(
      repair: transaction,
      inventoryItem: inventoryById[transaction.inventoryItemId],
      canViewFinancialData: canViewFinancialData,
    );
  }
  if (transaction is DisposalTransaction) {
    return _DisposalTransactionCard(
      disposal: transaction,
      inventoryItem: inventoryById[transaction.inventoryItemId],
    );
  }
  if (transaction is ConsignmentTransaction) {
    return _ConsignmentTransactionCard(
      consignment: transaction,
      inventoryItem: inventoryById[transaction.inventoryItemId],
      canViewFinancialData: canViewFinancialData,
    );
  }

  throw StateError('Unsupported transaction ledger entry.');
}

enum _LedgerType {
  all('All types'),
  sale('Sale'),
  trade('Trade-In'),
  repair('Repair'),
  disposal('Disposal'),
  consignment('Consignment');

  const _LedgerType(this.label);
  final String label;
}

enum _LedgerDateFilter {
  all('All dates', null),
  last7Days('Last 7 days', 7),
  last30Days('Last 30 days', 30),
  last90Days('Last 90 days', 90);

  const _LedgerDateFilter(this.label, this.days);
  final String label;
  final int? days;

  DateTime? cutoff(DateTime now) {
    if (days == null) {
      return null;
    }

    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: days! - 1));
  }
}

class _LedgerEntry {
  const _LedgerEntry({
    required this.type,
    required this.date,
    required this.transaction,
    required this.searchableText,
  });

  final _LedgerType type;
  final DateTime date;
  final Object transaction;
  final String searchableText;
}

class _SaleTransactionCard extends StatelessWidget {
  const _SaleTransactionCard({
    required this.sale,
    required this.inventoryItem,
    required this.canViewFinancialData,
  });

  final SaleTransaction sale;
  final InventoryItem? inventoryItem;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final acquisitionValue = sale.acquisitionValueCents;
    final profit = sale.profitCents;

    return Card(
      key: ValueKey(sale.id ?? 'sale-${sale.inventoryItemId}-${sale.saleDate}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(
          sale.id == null
              ? 'transactionCardUnavailable'
              : 'transactionCard-${sale.id}',
        ),
        onTap: sale.id == null
            ? null
            : () {
                context.goNamed(
                  AppRouteNames.transactionDetail,
                  pathParameters: {'transactionId': sale.id!},
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TransactionHeader(
                icon: Icons.point_of_sale_outlined,
                title: TransactionType.sale.label,
                subtitle: _formatDate(sale.saleDate),
                trailing: CurrencyFormatter.formatCents(sale.salePriceCents),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _TransactionDetailRow(
                label: 'Inventory Item',
                value: _inventoryDisplayName(inventoryItem),
              ),
              const SizedBox(height: 8),
              _TransactionDetailRow(
                label: 'Payment Method',
                value: sale.paymentMethod.label,
              ),
              const SizedBox(height: 8),
              _TransactionDetailRow(
                label: 'Revenue',
                value: CurrencyFormatter.formatCents(sale.salePriceCents),
              ),
              if (canViewFinancialData) ...[
                const SizedBox(height: 8),
                _TransactionDetailRow(
                  label: 'Cost',
                  value: acquisitionValue == null
                      ? 'Not available'
                      : CurrencyFormatter.formatCents(acquisitionValue),
                ),
                const SizedBox(height: 8),
                _TransactionDetailRow(
                  label: 'Profit',
                  value: profit == null
                      ? 'Not available'
                      : CurrencyFormatter.formatCents(profit),
                ),
                const SizedBox(height: 8),
                _TransactionDetailRow(
                  label: 'Gross Margin',
                  value: _formatMargin(sale.grossMargin),
                ),
              ],
              if (sale.notes != null && sale.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(sale.notes!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeTransactionCard extends StatelessWidget {
  const _TradeTransactionCard({
    required this.trade,
    required this.inventoryById,
  });

  final TradeTransaction trade;
  final Map<String, InventoryItem> inventoryById;

  @override
  Widget build(BuildContext context) {
    final incomingNames = trade.incomingInventoryItemIds
        .map((id) => _inventoryDisplayName(inventoryById[id]))
        .join(', ');

    return Card(
      key: ValueKey('tradeTransactionCard-${trade.id ?? trade.tradeDate}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TransactionHeader(
              icon: Icons.swap_horiz_outlined,
              title: 'Trade-In',
              subtitle: _formatDate(trade.tradeDate),
            ),
            const SizedBox(height: 12),
            _TransactionDetailRow(
              label: 'Incoming Inventory',
              value: incomingNames.isEmpty ? 'None' : incomingNames,
            ),
            const SizedBox(height: 8),
            _TransactionDetailRow(
              label: 'Incoming Items',
              value: trade.incomingInventoryItemIds.length.toString(),
            ),
            if (trade.saleTransactionId != null) ...[
              const SizedBox(height: 8),
              const _TransactionDetailRow(
                label: 'Source',
                value: 'Recorded with sale',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RepairTransactionCard extends StatelessWidget {
  const _RepairTransactionCard({
    required this.repair,
    required this.inventoryItem,
    required this.canViewFinancialData,
  });

  final RepairTransaction repair;
  final InventoryItem? inventoryItem;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('repairTransactionCard-${repair.id ?? repair.repairDate}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: repair.id == null
            ? null
            : () {
                context.goNamed(
                  AppRouteNames.repairDetail,
                  pathParameters: {'repairId': repair.id!},
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TransactionHeader(
                icon: Icons.build_outlined,
                title: 'Repair',
                subtitle: _formatDate(repair.repairDate),
                trailing: canViewFinancialData
                    ? CurrencyFormatter.formatCents(repair.costCents)
                    : null,
              ),
              const SizedBox(height: 12),
              _TransactionDetailRow(
                label: 'Inventory Item',
                value: _inventoryDisplayName(inventoryItem),
              ),
              const SizedBox(height: 8),
              _TransactionDetailRow(
                label: 'Description',
                value: repair.description,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisposalTransactionCard extends StatelessWidget {
  const _DisposalTransactionCard({
    required this.disposal,
    required this.inventoryItem,
  });

  final DisposalTransaction disposal;
  final InventoryItem? inventoryItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(
        'disposalTransactionCard-${disposal.id ?? disposal.disposalDate}',
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TransactionHeader(
              icon: Icons.delete_outline,
              title: 'Disposal',
              subtitle: _formatDate(disposal.disposalDate),
            ),
            const SizedBox(height: 12),
            _TransactionDetailRow(
              label: 'Inventory Item',
              value: _inventoryDisplayName(inventoryItem),
            ),
            const SizedBox(height: 8),
            _TransactionDetailRow(
              label: 'Reason',
              value: disposal.reason.label,
            ),
            if (disposal.replacementInventoryItemId != null) ...[
              const SizedBox(height: 8),
              const _TransactionDetailRow(
                label: 'Warranty Replacement',
                value: 'Replacement inventory created',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConsignmentTransactionCard extends StatelessWidget {
  const _ConsignmentTransactionCard({
    required this.consignment,
    required this.inventoryItem,
    required this.canViewFinancialData,
  });

  final ConsignmentTransaction consignment;
  final InventoryItem? inventoryItem;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(
        'consignmentTransactionCard-${consignment.id ?? consignment.consignmentDate}',
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TransactionHeader(
              icon: Icons.assignment_outlined,
              title: 'Consignment',
              subtitle: _formatDate(consignment.consignmentDate),
              trailing: canViewFinancialData
                  ? CurrencyFormatter.formatCents(consignment.commissionCents)
                  : null,
            ),
            const SizedBox(height: 12),
            _TransactionDetailRow(
              label: 'Inventory Item',
              value: _inventoryDisplayName(inventoryItem),
            ),
            if (canViewFinancialData) ...[
              const SizedBox(height: 8),
              _TransactionDetailRow(
                label: 'Hit the Deck Commission',
                value: CurrencyFormatter.formatCents(
                  consignment.commissionCents,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _TransactionDetailRow(
              label: 'Status',
              value: consignment.isCompleted
                  ? 'Sold / Completed'
                  : 'Awaiting Sale',
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionHeader extends StatelessWidget {
  const _TransactionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _TransactionDetailRow extends StatelessWidget {
  const _TransactionDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

String _searchableText(Iterable<String?> values) {
  return values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .join(' ')
      .toLowerCase();
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$month/$day/${date.year}';
}

String _formatMargin(double? margin) {
  if (margin == null) {
    return 'Not available';
  }

  return '${(margin * 100).toStringAsFixed(1)}%';
}

String _inventoryDisplayName(InventoryItem? item) {
  if (item == null) {
    return 'Inventory record unavailable';
  }

  final model = item.model?.trim();
  final equipmentName = model == null || model.isEmpty
      ? item.brand
      : '${item.brand} $model';
  final inventoryNumber =
      item.inventoryNumber ?? 'Inventory number not assigned';

  return '$inventoryNumber — $equipmentName';
}
