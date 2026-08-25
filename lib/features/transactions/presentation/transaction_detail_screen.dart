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
import '../../contacts/presentation/providers/contact_providers.dart';
import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/sale_transaction.dart';
import '../domain/models/transaction_enums.dart';
import 'providers/deal_providers.dart';
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

class _TransactionDetailView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentAppPermissionsProvider);
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
          if (transaction.id != null && transaction.id!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _TradeInInformationSection(saleTransactionId: transaction.id!),
            const SizedBox(height: 16),
            _SaleDealSection(saleTransactionId: transaction.id!),
          ],
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
                    label: 'Total Sale Price',
                    value: CurrencyFormatter.formatCents(
                      transaction.salePriceCents,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TransactionDetailRow(
                    label: 'Trade-In Credit',
                    value: CurrencyFormatter.formatCents(
                      transaction.tradeInCreditCents,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TransactionDetailRow(
                    label: 'Cash Received',
                    value: CurrencyFormatter.formatCents(
                      transaction.cashReceivedCents,
                    ),
                  ),
                  if (permissions.canViewFinancialData) ...[
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

class _SaleDealSection extends ConsumerWidget {
  const _SaleDealSection({required this.saleTransactionId});

  final String saleTransactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealForParentSaleProvider(saleTransactionId));

    return dealAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (deal) {
        final dealId = deal?.id;

        if (dealId == null || dealId.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          key: const Key('saleDealCard'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'This sale is the parent transaction for a Deal.',
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  key: const Key('saleViewDealButton'),
                  onPressed: () {
                    context.goNamed(
                      AppRouteNames.dealDetail,
                      pathParameters: {'dealId': dealId},
                    );
                  },
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('View Deal'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TradeInInformationSection extends ConsumerWidget {
  const _TradeInInformationSection({required this.saleTransactionId});

  final String saleTransactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tradeTransactionsProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return tradesAsync.when(
      loading: () => const _TradeInInformationCard(
        children: [AppLoadingState(message: 'Loading trade-in information...')],
      ),
      error: (error, stackTrace) => _TradeInInformationCard(
        children: [
          AppErrorState(
            message: 'Unable to load trade-in information.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(tradeTransactionsProvider);
            },
          ),
        ],
      ),
      data: (trades) {
        final linkedTrades = trades
            .where((trade) => trade.saleTransactionId == saleTransactionId)
            .toList();

        if (linkedTrades.isEmpty) {
          return const _TradeInInformationCard(
            children: [Text('No trade-in items were included with this sale.')],
          );
        }

        final incomingItemIds = <String>{
          for (final trade in linkedTrades) ...trade.incomingInventoryItemIds,
        }.toList();

        return inventoryAsync.when(
          loading: () => const _TradeInInformationCard(
            children: [
              AppLoadingState(message: 'Loading trade-in inventory...'),
            ],
          ),
          error: (error, stackTrace) => _TradeInInformationCard(
            children: [
              AppErrorState(
                message: 'Unable to load trade-in inventory.',
                details: error.toString(),
                onRetry: () {
                  ref.invalidate(inventoryItemsProvider);
                },
              ),
            ],
          ),
          data: (inventoryItems) {
            final inventoryById = <String, InventoryItem>{
              for (final item in inventoryItems)
                if (item.id != null) item.id!: item,
            };

            return _TradeInInformationCard(
              children: [
                _TransactionDetailRow(
                  label: 'Trade-In Items',
                  value: incomingItemIds.length.toString(),
                ),
                const SizedBox(height: 12),
                for (
                  var index = 0;
                  index < incomingItemIds.length;
                  index++
                ) ...[
                  if (index > 0) const Divider(height: 32),
                  _TradeInInventoryEntry(
                    inventoryItemId: incomingItemIds[index],
                    item: inventoryById[incomingItemIds[index]],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _TradeInInformationCard extends StatelessWidget {
  const _TradeInInformationCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('transactionTradeInInformationCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trade-In Information',
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

class _TradeInInventoryEntry extends ConsumerWidget {
  const _TradeInInventoryEntry({
    required this.inventoryItemId,
    required this.item,
  });

  final String inventoryItemId;
  final InventoryItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentAppPermissionsProvider);
    final inventoryItem = item;

    if (inventoryItem == null) {
      return Column(
        key: ValueKey('tradeInInventoryEntry-$inventoryItemId'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text('The linked trade-in inventory record is unavailable.'),
        ],
      );
    }

    final model = inventoryItem.model?.trim();
    final displayName = model == null || model.isEmpty
        ? inventoryItem.brand
        : '${inventoryItem.brand} $model';

    return Column(
      key: ValueKey('tradeInInventoryEntry-$inventoryItemId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TransactionDetailRow(
          label: 'Inventory Item',
          value:
              '${inventoryItem.inventoryNumber ?? 'Not assigned'} — $displayName',
        ),
        const SizedBox(height: 8),
        _TransactionDetailRow(
          label: 'Condition',
          value: inventoryItem.condition?.label ?? 'Not specified',
        ),
        const SizedBox(height: 8),
        if (permissions.canViewFinancialData)
          _TransactionDetailRow(
            label: 'Acquisition Value',
            value: CurrencyFormatter.formatCents(
              inventoryItem.acquisitionValueCents,
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: ValueKey(
              'transactionTradeInViewInventoryButton-$inventoryItemId',
            ),
            onPressed: () {
              context.goNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': inventoryItemId},
              );
            },
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('View Inventory Item'),
          ),
        ),
      ],
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
