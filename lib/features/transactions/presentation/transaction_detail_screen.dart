import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../contacts/presentation/providers/contact_providers.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/sale_transaction.dart';
import '../domain/models/transaction_enums.dart';
import 'providers/transaction_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(saleTransactionProvider(transactionId));

    return transactionAsync.when(
      loading: () => const AppPage(
        title: 'Transaction Details',
        child: AppLoadingState(message: 'Loading transaction...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Transaction Details',
        child: AppErrorState(
          message: 'Unable to load transaction.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(saleTransactionProvider(transactionId));
          },
        ),
      ),
      data: (transaction) {
        if (transaction == null) {
          return const AppPage(
            title: 'Transaction Details',
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Transaction not found.',
              message:
                  'The transaction may have been removed or is no longer available.',
            ),
          );
        }

        return _SaleTransactionDetailContent(transaction: transaction);
      },
    );
  }
}

class _SaleTransactionDetailContent extends ConsumerWidget {
  const _SaleTransactionDetailContent({required this.transaction});

  final SaleTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryItemAsync = ref.watch(
      inventoryItemProvider(transaction.inventoryItemId),
    );

    return inventoryItemAsync.when(
      loading: () => const AppPage(
        title: 'Transaction Details',
        child: AppLoadingState(message: 'Loading inventory details...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Transaction Details',
        child: AppErrorState(
          message: 'Unable to load inventory details.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(inventoryItemProvider(transaction.inventoryItemId));
          },
        ),
      ),
      data: (inventoryItem) {
        return _TransactionDetailView(
          transaction: transaction,
          inventoryItem: inventoryItem,
        );
      },
    );
  }
}

class _TransactionDetailView extends StatelessWidget {
  const _TransactionDetailView({
    required this.transaction,
    required this.inventoryItem,
  });

  final SaleTransaction transaction;
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
    final acquisitionValue = transaction.acquisitionValueCents;
    final profit = transaction.profitCents;

    return AppPage(
      title: 'Sale Transaction',
      subtitle: _formatDate(transaction.saleDate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _TransactionDetailRow(
                    label: 'Transaction Type',
                    value: TransactionType.sale.label,
                  ),
                  const SizedBox(height: 8),
                  _TransactionDetailRow(
                    label: 'Sale Date',
                    value: _formatDate(transaction.saleDate),
                  ),
                  const SizedBox(height: 8),
                  _TransactionDetailRow(
                    label: 'Payment Method',
                    value: transaction.paymentMethod.label,
                  ),
                  const SizedBox(height: 8),
                  _TransactionDetailRow(
                    label: 'Inventory Item',
                    value: _inventoryDisplayName(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _BuyerInformationSection(buyerContactId: transaction.buyerContactId),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _TransactionDetailRow(
                    label: 'Revenue',
                    value: CurrencyFormatter.formatCents(
                      transaction.salePriceCents,
                    ),
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
                    value: _formatMargin(transaction.grossMargin),
                  ),
                ],
              ),
            ),
          ),
          if (transaction.notes != null &&
              transaction.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(transaction.notes!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuyerInformationSection extends ConsumerWidget {
  const _BuyerInformationSection({required this.buyerContactId});

  final String? buyerContactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactId = buyerContactId?.trim() ?? '';

    if (contactId.isEmpty) {
      return const _BuyerInformationCard(
        children: [
          _TransactionDetailRow(label: 'Buyer', value: 'No buyer linked'),
        ],
      );
    }

    final buyerAsync = ref.watch(contactProvider(contactId));

    return buyerAsync.when(
      loading: () => const _BuyerInformationCard(
        children: [AppLoadingState(message: 'Loading buyer information...')],
      ),
      error: (error, stackTrace) => _BuyerInformationCard(
        children: [
          AppErrorState(
            message: 'Unable to load buyer information.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(contactProvider(contactId));
            },
          ),
        ],
      ),
      data: (buyer) {
        if (buyer == null) {
          return const _BuyerInformationCard(
            children: [
              Text(
                'A buyer is linked to this sale, but the Contact record is unavailable.',
              ),
            ],
          );
        }

        return _BuyerInformationCard(
          children: [
            _TransactionDetailRow(label: 'Buyer', value: buyer.name),
            const SizedBox(height: 8),
            _TransactionDetailRow(
              label: 'Phone',
              value: _displayOptionalContactValue(buyer.phone),
            ),
            const SizedBox(height: 8),
            _TransactionDetailRow(
              label: 'Email',
              value: _displayOptionalContactValue(buyer.email),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('transactionDetailViewBuyerButton'),
                onPressed: () {
                  context.goNamed(
                    AppRouteNames.contactDetail,
                    pathParameters: {'contactId': contactId},
                  );
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('View Buyer'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BuyerInformationCard extends StatelessWidget {
  const _BuyerInformationCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Buyer Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

String _displayOptionalContactValue(String? value) {
  final trimmedValue = value?.trim() ?? '';

  return trimmedValue.isEmpty ? 'Not specified' : trimmedValue;
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
