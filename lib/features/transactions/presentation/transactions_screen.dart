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
  Set<_LedgerType> _selectedTypes = <_LedgerType>{};
  int? _minimumAmountCents;
  int? _maximumAmountCents;

  bool get _hasAdvancedFilters =>
      _selectedTypes.isNotEmpty ||
      _minimumAmountCents != null ||
      _maximumAmountCents != null;

  bool get _hasActiveFilters => _query.trim().isNotEmpty || _hasAdvancedFilters;

  int get _advancedFilterCount {
    var count = 0;
    if (_selectedTypes.isNotEmpty) {
      count++;
    }
    if (_minimumAmountCents != null || _maximumAmountCents != null) {
      count++;
    }
    return count;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedTypes = <_LedgerType>{};
      _minimumAmountCents = null;
      _maximumAmountCents = null;
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    key: const Key('transactionsSearchField'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search transactions',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.trim().isEmpty
                          ? null
                          : IconButton(
                              key: const Key('transactionsSearchClearButton'),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.filledTonal(
                  key: const Key('transactionsFilterButton'),
                  tooltip: _hasAdvancedFilters
                      ? '$_advancedFilterCount filters active'
                      : 'Filter transactions',
                  onPressed: () => _openFilters(context),
                  icon: Badge(
                    isLabelVisible: _hasAdvancedFilters,
                    label: Text('$_advancedFilterCount'),
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _hasActiveFilters
                      ? '${filteredEntries.length} of ${entries.length} transactions'
                      : '${entries.length} transaction${entries.length == 1 ? '' : 's'}',
                  key: const Key('transactionsResultCount'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF082A4A),
                  ),
                ),
              ),
              if (_hasActiveFilters)
                TextButton(
                  key: const Key('transactionsClearFiltersButton'),
                  onPressed: _clearAllFilters,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (filteredEntries.isEmpty)
            const AppEmptyState(
              icon: Icons.search_off,
              title: 'No transactions match your filters.',
              message: 'Clear or adjust the search or transaction filters.',
            )
          else
            for (final entry in filteredEntries) ...[
              _TransactionLedgerCard(
                entry: entry,
                canViewFinancialData: permissions.canViewFinancialData,
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  bool _matchesFilters(_LedgerEntry entry) {
    if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(entry.type)) {
      return false;
    }

    if (_minimumAmountCents != null || _maximumAmountCents != null) {
      final amount = entry.filterAmountCents;
      if (amount == null) return false;
      if (_minimumAmountCents != null && amount < _minimumAmountCents!) {
        return false;
      }
      if (_maximumAmountCents != null && amount > _maximumAmountCents!) {
        return false;
      }
    }

    final query = _query.trim().toLowerCase();
    return query.isEmpty || entry.searchableText.contains(query);
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await showDialog<_TransactionFilterResult>(
      context: context,
      builder: (dialogContext) => _TransactionFilterDialog(
        initialTypes: _selectedTypes,
        initialMinimumAmountCents: _minimumAmountCents,
        initialMaximumAmountCents: _maximumAmountCents,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedTypes = result.types;
      _minimumAmountCents = result.minimumAmountCents;
      _maximumAmountCents = result.maximumAmountCents;
    });
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
        title: _inventoryDisplayName(inventoryById[sale.inventoryItemId]),
        subtitle: '${_paymentMethodLabel(sale.paymentMethod)} sale',
        displayAmountCents: sale.salePriceCents,
        filterAmountCents: sale.salePriceCents.abs(),
        amountDirection: _AmountDirection.positive,
        routeName: sale.id == null ? null : AppRouteNames.transactionDetail,
        routeId: sale.id,
        routeParameterName: 'transactionId',
        cardKey: ValueKey(
          sale.id ?? 'sale-${sale.inventoryItemId}-${sale.saleDate}',
        ),
        tapKey: ValueKey(
          sale.id == null
              ? 'transactionCardUnavailable'
              : 'transactionCard-${sale.id}',
        ),
        searchableText: _searchableText([
          'sale',
          _formatDate(sale.saleDate),
          _inventoryDisplayName(inventoryById[sale.inventoryItemId]),
          _paymentMethodLabel(sale.paymentMethod),
          sale.notes,
          CurrencyFormatter.formatCents(sale.salePriceCents),
        ]),
      ),
    for (final trade in trades)
      _LedgerEntry(
        type: _LedgerType.trade,
        date: trade.tradeDate,
        title: _tradeDisplayName(trade, inventoryById),
        subtitle: _tradeSubtitle(trade),
        displayAmountCents: trade.includesCash ? trade.netCashCents : null,
        filterAmountCents: trade.includesCash ? trade.netCashCents.abs() : null,
        amountDirection: trade.netCashCents < 0
            ? _AmountDirection.negative
            : _AmountDirection.positive,
        cardKey: ValueKey(
          'tradeTransactionCard-${trade.id ?? trade.tradeDate}',
        ),
        searchableText: _searchableText([
          'trade trade-in',
          _formatDate(trade.tradeDate),
          ...trade.outgoingInventoryItemIds.map(
            (id) => _inventoryDisplayName(inventoryById[id]),
          ),
          ...trade.incomingInventoryItemIds.map(
            (id) => _inventoryDisplayName(inventoryById[id]),
          ),
          trade.paymentMethod == null
              ? null
              : _paymentMethodLabel(trade.paymentMethod!),
          trade.notes,
        ]),
      ),
    for (final repair in repairs)
      _LedgerEntry(
        type: _LedgerType.repair,
        date: repair.repairDate,
        title: _inventoryDisplayName(inventoryById[repair.inventoryItemId]),
        subtitle: repair.description,
        displayAmountCents: repair.costCents,
        filterAmountCents: repair.costCents.abs(),
        amountDirection: _AmountDirection.negative,
        routeName: repair.id == null ? null : AppRouteNames.repairDetail,
        routeId: repair.id,
        routeParameterName: 'repairId',
        cardKey: ValueKey(
          'repairTransactionCard-${repair.id ?? repair.repairDate}',
        ),
        searchableText: _searchableText([
          'repair',
          _formatDate(repair.repairDate),
          _inventoryDisplayName(inventoryById[repair.inventoryItemId]),
          repair.description,
          repair.notes,
          CurrencyFormatter.formatCents(repair.costCents),
        ]),
      ),
    for (final disposal in disposals)
      _LedgerEntry(
        type: _LedgerType.disposal,
        date: disposal.disposalDate,
        title: _inventoryDisplayName(inventoryById[disposal.inventoryItemId]),
        subtitle: disposal.replacementInventoryItemId == null
            ? disposal.reason.label
            : '${disposal.reason.label} • Warranty replacement',
        displayAmountCents: null,
        filterAmountCents: null,
        amountDirection: _AmountDirection.neutral,
        cardKey: ValueKey(
          'disposalTransactionCard-${disposal.id ?? disposal.disposalDate}',
        ),
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
        title: _inventoryDisplayName(
          inventoryById[consignment.inventoryItemId],
        ),
        subtitle: consignment.isCompleted
            ? 'Sold / Completed'
            : 'Awaiting Sale',
        displayAmountCents: consignment.commissionCents,
        filterAmountCents: consignment.commissionCents.abs(),
        amountDirection: _AmountDirection.positive,
        cardKey: ValueKey(
          'consignmentTransactionCard-${consignment.id ?? consignment.consignmentDate}',
        ),
        searchableText: _searchableText([
          'consignment',
          _formatDate(consignment.consignmentDate),
          _inventoryDisplayName(inventoryById[consignment.inventoryItemId]),
          consignment.isCompleted ? 'sold completed' : 'awaiting sale',
          consignment.notes,
          CurrencyFormatter.formatCents(consignment.commissionCents),
        ]),
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));

  return entries;
}

enum _LedgerType {
  sale('Sale', Icons.point_of_sale_outlined),
  trade('Trade-In', Icons.swap_horiz_rounded),
  repair('Repair', Icons.build_outlined),
  disposal('Disposal', Icons.delete_outline_rounded),
  consignment('Consignment', Icons.assignment_outlined);

  const _LedgerType(this.label, this.icon);

  final String label;
  final IconData icon;

  Color get accentColor => switch (this) {
    _LedgerType.sale => const Color(0xFF18834B),
    _LedgerType.trade => const Color(0xFF1769AA),
    _LedgerType.repair => const Color(0xFFC66B00),
    _LedgerType.disposal => const Color(0xFFC43B46),
    _LedgerType.consignment => const Color(0xFF6D4AA5),
  };

  Color get softColor => switch (this) {
    _LedgerType.sale => const Color(0xFFE4F5EA),
    _LedgerType.trade => const Color(0xFFE5F0FA),
    _LedgerType.repair => const Color(0xFFFFEED9),
    _LedgerType.disposal => const Color(0xFFFFE8EA),
    _LedgerType.consignment => const Color(0xFFF0E9FA),
  };
}

enum _AmountDirection { positive, negative, neutral }

class _LedgerEntry {
  const _LedgerEntry({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.displayAmountCents,
    required this.filterAmountCents,
    required this.amountDirection,
    required this.cardKey,
    required this.searchableText,
    this.routeName,
    this.routeId,
    this.routeParameterName,
    this.tapKey,
  });

  final _LedgerType type;
  final DateTime date;
  final String title;
  final String subtitle;
  final int? displayAmountCents;
  final int? filterAmountCents;
  final _AmountDirection amountDirection;
  final Key cardKey;
  final String searchableText;
  final String? routeName;
  final String? routeId;
  final String? routeParameterName;
  final Key? tapKey;
}

class _TransactionLedgerCard extends StatelessWidget {
  const _TransactionLedgerCard({
    required this.entry,
    required this.canViewFinancialData,
  });

  final _LedgerEntry entry;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      key: entry.cardKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: entry.type.accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: entry.type.softColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        entry.type.icon,
                        color: entry.type.accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _TypePill(type: entry.type),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(entry.date),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: const Color(0xFF687586)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF082A4A),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            entry.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF667383)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _displayAmount(entry, canViewFinancialData),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: _amountColor(
                                  entry,
                                  canViewFinancialData,
                                ),
                              ),
                        ),
                        if (entry.routeName != null) ...[
                          const SizedBox(height: 5),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Color(0xFF8B96A3),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (entry.routeName == null ||
        entry.routeId == null ||
        entry.routeParameterName == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: entry.tapKey,
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.goNamed(
            entry.routeName!,
            pathParameters: {entry.routeParameterName!: entry.routeId!},
          );
        },
        child: card,
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final _LedgerType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('transactionTypePill-${type.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: type.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: type.accentColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TransactionFilterDialog extends StatefulWidget {
  const _TransactionFilterDialog({
    required this.initialTypes,
    required this.initialMinimumAmountCents,
    required this.initialMaximumAmountCents,
  });

  final Set<_LedgerType> initialTypes;
  final int? initialMinimumAmountCents;
  final int? initialMaximumAmountCents;

  @override
  State<_TransactionFilterDialog> createState() =>
      _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<_TransactionFilterDialog> {
  late Set<_LedgerType> _types;
  late final TextEditingController _minimumController;
  late final TextEditingController _maximumController;

  @override
  void initState() {
    super.initState();
    _types = Set<_LedgerType>.from(widget.initialTypes);
    _minimumController = TextEditingController(
      text: _dollars(widget.initialMinimumAmountCents),
    );
    _maximumController = TextEditingController(
      text: _dollars(widget.initialMaximumAmountCents),
    );
  }

  @override
  void dispose() {
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('transactionsFilterDialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      title: const Row(
        children: [
          Icon(Icons.tune_rounded),
          SizedBox(width: 10),
          Text('Filter Transactions'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Transaction Type',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in _LedgerType.values)
                    FilterChip(
                      key: ValueKey('transactionsTypeFilter-${type.name}'),
                      label: Text(type.label),
                      selected: _types.contains(type),
                      avatar: Icon(
                        type.icon,
                        size: 18,
                        color: _types.contains(type)
                            ? type.accentColor
                            : const Color(0xFF687586),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _types.add(type);
                          } else {
                            _types.remove(type);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Transaction Amount',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Uses the transaction value regardless of positive or negative direction.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF687586)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('transactionsMinimumAmountField'),
                      controller: _minimumController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        prefixText: r'$',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('transactionsMaximumAmountField'),
                      controller: _maximumController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        prefixText: r'$',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('transactionsFilterClearButton'),
          onPressed: () {
            Navigator.of(context).pop(
              const _TransactionFilterResult(
                types: <_LedgerType>{},
                minimumAmountCents: null,
                maximumAmountCents: null,
              ),
            );
          },
          child: const Text('Clear Filters'),
        ),
        TextButton(
          key: const Key('transactionsFilterCancelButton'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('transactionsFilterApplyButton'),
          onPressed: () {
            Navigator.of(context).pop(
              _TransactionFilterResult(
                types: Set<_LedgerType>.unmodifiable(_types),
                minimumAmountCents: _parseDollars(_minimumController.text),
                maximumAmountCents: _parseDollars(_maximumController.text),
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _TransactionFilterResult {
  const _TransactionFilterResult({
    required this.types,
    required this.minimumAmountCents,
    required this.maximumAmountCents,
  });

  final Set<_LedgerType> types;
  final int? minimumAmountCents;
  final int? maximumAmountCents;
}

String _displayAmount(_LedgerEntry entry, bool canViewFinancialData) {
  if (!canViewFinancialData || entry.displayAmountCents == null) {
    return '—';
  }

  final formatted = CurrencyFormatter.formatCents(
    entry.displayAmountCents!.abs(),
  );

  return switch (entry.amountDirection) {
    _AmountDirection.positive => '+$formatted',
    _AmountDirection.negative => '-$formatted',
    _AmountDirection.neutral => formatted,
  };
}

Color _amountColor(_LedgerEntry entry, bool canViewFinancialData) {
  if (!canViewFinancialData || entry.displayAmountCents == null) {
    return const Color(0xFF7B8794);
  }

  return switch (entry.amountDirection) {
    _AmountDirection.positive => const Color(0xFF18834B),
    _AmountDirection.negative => const Color(0xFFC43B46),
    _AmountDirection.neutral => const Color(0xFF082A4A),
  };
}

String _tradeDisplayName(
  TradeTransaction trade,
  Map<String, InventoryItem> inventoryById,
) {
  final ids = trade.incomingInventoryItemIds.isNotEmpty
      ? trade.incomingInventoryItemIds
      : trade.outgoingInventoryItemIds;

  if (ids.isEmpty) return 'Trade transaction';
  if (ids.length == 1) return _inventoryDisplayName(inventoryById[ids.single]);
  return '${ids.length} inventory items';
}

String _tradeSubtitle(TradeTransaction trade) {
  if (!trade.includesCash) {
    final count = trade.incomingInventoryItemIds.length;
    return '$count incoming item${count == 1 ? '' : 's'}';
  }
  return trade.netCashCents > 0
      ? 'Cash received with trade'
      : 'Cash paid with trade';
}

String _paymentMethodLabel(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.venmo => 'Venmo',
    PaymentMethod.paypal => 'PayPal',
    PaymentMethod.zelle => 'Zelle',
  };
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

String _inventoryDisplayName(InventoryItem? item) {
  if (item == null) return 'Inventory record unavailable';

  final model = item.model?.trim();
  final equipmentName = model == null || model.isEmpty
      ? item.brand
      : '${item.brand} $model';
  final inventoryNumber =
      item.inventoryNumber ?? 'Inventory number not assigned';

  return '$inventoryNumber — $equipmentName';
}

String _dollars(int? cents) {
  if (cents == null) return '';
  return (cents / 100).toStringAsFixed(2);
}

int? _parseDollars(String value) {
  final number = double.tryParse(value.trim());
  if (number == null || number < 0) return null;
  return (number * 100).round();
}
