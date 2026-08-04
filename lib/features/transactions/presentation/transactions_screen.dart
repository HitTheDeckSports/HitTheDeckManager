import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/sale_transaction.dart';
import '../domain/models/transaction_enums.dart';
import 'providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(saleTransactionsProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

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
                  Text(
                    '${sortedSales.length} transaction'
                    '${sortedSales.length == 1 ? '' : 's'}',
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
