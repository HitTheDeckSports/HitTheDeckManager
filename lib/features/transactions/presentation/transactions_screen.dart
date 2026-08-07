import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/consignment_transaction.dart';
import '../domain/models/deal.dart';
import '../domain/models/deal_status.dart';
import '../domain/models/deal_summary.dart';
import '../domain/models/disposal_transaction.dart';
import '../domain/models/repair_transaction.dart';
import '../domain/models/sale_transaction.dart';
import '../domain/models/trade_transaction.dart';
import '../domain/models/transaction_enums.dart';
import '../domain/models/disposal_reason.dart';
import 'providers/deal_providers.dart';
import 'providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(saleTransactionsProvider);
    final repairsAsync = ref.watch(repairTransactionsProvider);
    final tradesAsync = ref.watch(tradeTransactionsProvider);
    final disposalsAsync = ref.watch(disposalTransactionsProvider);
    final consignmentsAsync = ref.watch(consignmentTransactionsProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final dealsAsync = ref.watch(dealsProvider);

    final asyncValues = <AsyncValue<Object?>>[
      salesAsync,
      repairsAsync,
      tradesAsync,
      disposalsAsync,
      consignmentsAsync,
      inventoryAsync,
      dealsAsync,
    ];

    if (asyncValues.any((value) => value.isLoading)) {
      return const AppPage(
        title: 'Transactions',
        subtitle:
            'Review sales, trade-ins, repairs, disposals, consignments, and Deals.',
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
        subtitle:
            'Review sales, trade-ins, repairs, disposals, consignments, and Deals.',
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
            ref.invalidate(dealsProvider);
          },
        ),
      );
    }

    final sales = salesAsync.requireValue;
    final repairs = repairsAsync.requireValue;
    final trades = tradesAsync.requireValue;
    final disposals = disposalsAsync.requireValue;
    final consignments = consignmentsAsync.requireValue;
    final inventoryItems = inventoryAsync.requireValue;
    final deals = dealsAsync.requireValue;

    final hasAnyTransaction =
        sales.isNotEmpty ||
        repairs.isNotEmpty ||
        trades.isNotEmpty ||
        disposals.isNotEmpty ||
        consignments.isNotEmpty ||
        deals.isNotEmpty;

    if (!hasAnyTransaction) {
      return const AppPage(
        title: 'Transactions',
        subtitle:
            'Review sales, trade-ins, repairs, disposals, consignments, and Deals.',
        child: AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No transactions yet.',
          message:
              'Completed sales and other business transactions will appear here.',
        ),
      );
    }

    final inventoryById = <String, InventoryItem>{
      for (final item in inventoryItems)
        if (item.id != null) item.id!: item,
    };

    final sortedSales = [...sales]
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    final sortedRepairs = [...repairs]
      ..sort((a, b) => b.repairDate.compareTo(a.repairDate));
    final sortedTrades = [...trades]
      ..sort((a, b) => b.tradeDate.compareTo(a.tradeDate));
    final sortedDisposals = [...disposals]
      ..sort((a, b) => b.disposalDate.compareTo(a.disposalDate));
    final sortedConsignments = [...consignments]
      ..sort((a, b) => b.consignmentDate.compareTo(a.consignmentDate));

    return AppPage(
      title: 'Transactions',
      subtitle:
          'Review sales, trade-ins, repairs, disposals, consignments, and Deals.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DealsSection(deals: deals),
          const SizedBox(height: 24),
          _SalesSection(sales: sortedSales, inventoryById: inventoryById),
          const SizedBox(height: 24),
          _TradesSection(trades: sortedTrades, inventoryById: inventoryById),
          const SizedBox(height: 24),
          _RepairsSection(repairs: sortedRepairs, inventoryById: inventoryById),
          const SizedBox(height: 24),
          _DisposalsSection(
            disposals: sortedDisposals,
            inventoryById: inventoryById,
          ),
          const SizedBox(height: 24),
          _ConsignmentsSection(
            consignments: sortedConsignments,
            inventoryById: inventoryById,
          ),
        ],
      ),
    );
  }
}

class _DealsSection extends StatelessWidget {
  const _DealsSection({required this.deals});

  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('transactionsDealsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: 'Deals (${deals.length})'),
        const SizedBox(height: 12),
        if (deals.isEmpty)
          const Text(
            'No Deals yet. Deals are created automatically when a sale includes trade-in inventory.',
          )
        else
          for (final deal in deals) ...[
            _DealTransactionCard(deal: deal),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _SalesSection extends StatelessWidget {
  const _SalesSection({required this.sales, required this.inventoryById});

  final List<SaleTransaction> sales;
  final Map<String, InventoryItem> inventoryById;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('transactionsSalesSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: 'Sales (${sales.length})'),
        const SizedBox(height: 12),
        if (sales.isEmpty)
          const Text('No sales recorded.')
        else
          for (final sale in sales) ...[
            _SaleTransactionCard(
              sale: sale,
              inventoryItem: inventoryById[sale.inventoryItemId],
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _TradesSection extends StatelessWidget {
  const _TradesSection({required this.trades, required this.inventoryById});

  final List<TradeTransaction> trades;
  final Map<String, InventoryItem> inventoryById;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('transactionsTradesSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: 'Trade-Ins (${trades.length})'),
        const SizedBox(height: 12),
        if (trades.isEmpty)
          const Text('No trade-ins recorded.')
        else
          for (final trade in trades) ...[
            _TradeTransactionCard(trade: trade, inventoryById: inventoryById),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _RepairsSection extends StatelessWidget {
  const _RepairsSection({required this.repairs, required this.inventoryById});

  final List<RepairTransaction> repairs;
  final Map<String, InventoryItem> inventoryById;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('transactionsRepairsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: 'Repairs (${repairs.length})'),
        const SizedBox(height: 12),
        if (repairs.isEmpty)
          const Text('No repairs recorded.')
        else
          for (final repair in repairs) ...[
            _RepairTransactionCard(
              repair: repair,
              inventoryItem: inventoryById[repair.inventoryItemId],
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _DisposalsSection extends StatelessWidget {
  const _DisposalsSection({
    required this.disposals,
    required this.inventoryById,
  });

  final List<DisposalTransaction> disposals;
  final Map<String, InventoryItem> inventoryById;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('transactionsDisposalsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: 'Disposals (${disposals.length})'),
        const SizedBox(height: 12),
        if (disposals.isEmpty)
          const Text('No disposals recorded.')
        else
          for (final disposal in disposals) ...[
            _DisposalTransactionCard(
              disposal: disposal,
              inventoryItem: inventoryById[disposal.inventoryItemId],
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _ConsignmentsSection extends StatelessWidget {
  const _ConsignmentsSection({
    required this.consignments,
    required this.inventoryById,
  });

  final List<ConsignmentTransaction> consignments;
  final Map<String, InventoryItem> inventoryById;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('transactionsConsignmentsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: 'Consignments (${consignments.length})'),
        const SizedBox(height: 12),
        if (consignments.isEmpty)
          const Text('No consignment agreements recorded.')
        else
          for (final consignment in consignments) ...[
            _ConsignmentTransactionCard(
              consignment: consignment,
              inventoryItem: inventoryById[consignment.inventoryItemId],
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _DealTransactionCard extends ConsumerWidget {
  const _DealTransactionCard({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealId = deal.id;

    if (dealId == null || dealId.trim().isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('A Deal record is missing its ID.'),
        ),
      );
    }

    final summaryAsync = ref.watch(dealSummaryProvider(dealId));

    return summaryAsync.when(
      loading: () => Card(
        key: ValueKey('dealTransactionCard-$dealId'),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: AppLoadingState(message: 'Loading Deal summary...'),
        ),
      ),
      error: (error, stackTrace) => Card(
        key: ValueKey('dealTransactionCard-$dealId'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppErrorState(
            message: 'Unable to load Deal summary.',
            details: error.toString(),
          ),
        ),
      ),
      data: (summary) {
        if (summary == null) {
          return Card(
            key: ValueKey('dealTransactionCard-$dealId'),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Deal summary is unavailable.'),
            ),
          );
        }

        return _DealSummaryCard(summary: summary);
      },
    );
  }
}

class _DealSummaryCard extends StatelessWidget {
  const _DealSummaryCard({required this.summary});

  final DealSummary summary;

  @override
  Widget build(BuildContext context) {
    final dealId = summary.deal.id!;

    return Card(
      key: ValueKey('dealTransactionCard-$dealId'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('dealTransactionCardTap-$dealId'),
        onTap: () {
          context.goNamed(
            AppRouteNames.dealDetail,
            pathParameters: {'dealId': dealId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.handshake_outlined, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(summary.status.label),
                      ],
                    ),
                  ),
                  _DealStatusChip(status: summary.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _TransactionDetailRow(
                label: 'Child Inventory',
                value: summary.deal.childInventoryItemIds.length.toString(),
              ),
              const SizedBox(height: 8),
              _TransactionDetailRow(
                label: 'Realized Deal Profit',
                value: CurrencyFormatter.formatCents(
                  summary.realizedDealProfitCents,
                ),
              ),
              const SizedBox(height: 8),
              _TransactionDetailRow(
                label: 'Projected Deal Profit',
                value: CurrencyFormatter.formatCents(
                  summary.projectedDealProfitCents,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DealStatusChip extends StatelessWidget {
  const _DealStatusChip({required this.status});

  final DealStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      key: ValueKey('dealStatus-${status.name}'),
      label: Text(status.label),
    );
  }
}

class _SaleTransactionCard extends StatelessWidget {
  const _SaleTransactionCard({required this.sale, required this.inventoryItem});

  final SaleTransaction sale;
  final InventoryItem? inventoryItem;

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
  });

  final RepairTransaction repair;
  final InventoryItem? inventoryItem;

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
                trailing: CurrencyFormatter.formatCents(repair.costCents),
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
  });

  final ConsignmentTransaction consignment;
  final InventoryItem? inventoryItem;

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
              trailing: CurrencyFormatter.formatCents(
                consignment.commissionCents,
              ),
            ),
            const SizedBox(height: 12),
            _TransactionDetailRow(
              label: 'Inventory Item',
              value: _inventoryDisplayName(inventoryItem),
            ),
            const SizedBox(height: 8),
            _TransactionDetailRow(
              label: 'Hit the Deck Commission',
              value: CurrencyFormatter.formatCents(consignment.commissionCents),
            ),
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

  return '$inventoryNumber \u2014 $equipmentName';
}
