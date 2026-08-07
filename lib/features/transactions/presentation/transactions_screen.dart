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
import '../domain/models/deal.dart';
import '../domain/models/deal_status.dart';
import '../domain/models/deal_summary.dart';
import '../domain/models/sale_transaction.dart';
import '../domain/models/transaction_enums.dart';
import 'providers/deal_providers.dart';
import 'providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(saleTransactionsProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final dealsAsync = ref.watch(dealsProvider);

    return AppPage(
      title: 'Transactions',
      subtitle: 'Review purchases, sales, trades, repairs, and disposals.',
      child: salesAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading transactions...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load transactions.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(saleTransactionsProvider);
          },
        ),
        data: (sales) {
          if (sales.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet.',
              message:
                  'Completed sales and other business transactions will appear here.',
            );
          }

          return inventoryAsync.when(
            loading: () =>
                const AppLoadingState(message: 'Loading inventory details...'),
            error: (error, stackTrace) => AppErrorState(
              message: 'Unable to load inventory details.',
              details: error.toString(),
              onRetry: () {
                ref.invalidate(inventoryItemsProvider);
              },
            ),
            data: (inventoryItems) {
              final inventoryById = <String, InventoryItem>{
                for (final item in inventoryItems)
                  if (item.id != null) item.id!: item,
              };

              final sortedSales = [...sales]
                ..sort(
                  (first, second) => second.saleDate.compareTo(first.saleDate),
                );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DealsSection(dealsAsync: dealsAsync),
                  const SizedBox(height: 24),
                  Text(
                    'Sales (${sortedSales.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final sale in sortedSales) ...[
                    _SaleTransactionCard(
                      sale: sale,
                      inventoryItem: inventoryById[sale.inventoryItemId],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DealsSection extends StatelessWidget {
  const _DealsSection({required this.dealsAsync});

  final AsyncValue<List<Deal>> dealsAsync;

  @override
  Widget build(BuildContext context) {
    return dealsAsync.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(title: 'Deals'),
          SizedBox(height: 12),
          AppLoadingState(message: 'Loading Deals...'),
        ],
      ),
      error: (error, stackTrace) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(title: 'Deals'),
          const SizedBox(height: 12),
          AppErrorState(
            message: 'Unable to load Deals.',
            details: error.toString(),
          ),
        ],
      ),
      data: (deals) {
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
      },
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap to review Deal details',
                  style: Theme.of(context).textTheme.bodySmall,
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

  String _inventoryDisplayName() {
    final item = inventoryItem;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.point_of_sale_outlined, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TransactionType.sale.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(sale.saleDate),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCents(sale.salePriceCents),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _TransactionDetailRow(
                label: 'Inventory Item',
                value: _inventoryDisplayName(),
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
                const SizedBox(height: 16),
                Text('Notes', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(sale.notes!),
              ],
            ],
          ),
        ),
      ),
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
