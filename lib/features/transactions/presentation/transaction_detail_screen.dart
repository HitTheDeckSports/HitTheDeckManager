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
        showHeader: false,
        compact: true,
        child: AppLoadingState(message: 'Loading transaction...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Transaction Details',
        showHeader: false,
        compact: true,
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
            showHeader: false,
            compact: true,
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
        showHeader: false,
        compact: true,
        child: AppLoadingState(message: 'Loading inventory details...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Transaction Details',
        showHeader: false,
        compact: true,
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
    if (margin == null) return 'Not available';
    return '${(margin * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentAppPermissionsProvider);
    final acquisitionValue = transaction.acquisitionValueCents;
    final profit = transaction.profitCents;

    return AppPage(
      title: 'Sale Transaction',
      showHeader: false,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SoldItemHero(transaction: transaction, inventoryItem: inventoryItem),
          const SizedBox(height: 12),
          _SectionCard(
            key: const Key('saleTransactionDetailsSection'),
            icon: Icons.receipt_long_outlined,
            title: 'Transaction Details',
            child: Column(
              children: [
                _TransactionDetailRow(
                  label: 'Transaction Type',
                  value: TransactionType.sale.label,
                ),
                const Divider(height: 18),
                _TransactionDetailRow(
                  label: 'Sale Date',
                  value: _formatDate(transaction.saleDate),
                ),
                const Divider(height: 18),
                _TransactionDetailRow(
                  label: 'Payment Method',
                  value: transaction.paymentMethod.label,
                ),
                const Divider(height: 18),
                _InventoryLinkRow(
                  inventoryItem: inventoryItem,
                  fallbackItemId: transaction.inventoryItemId,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _BuyerInformationSection(buyerContactId: transaction.buyerContactId),
          if (transaction.id != null && transaction.id!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _TradeInInformationSection(saleTransactionId: transaction.id!),
          ],
          const SizedBox(height: 12),
          _SectionCard(
            key: const Key('saleFinancialSummarySection'),
            icon: Icons.attach_money_rounded,
            title: 'Financial Summary',
            child: Column(
              children: [
                _TransactionDetailRow(
                  label: 'Total Sale Price',
                  value: CurrencyFormatter.formatCents(
                    transaction.salePriceCents,
                  ),
                ),
                const Divider(height: 18),
                _TransactionDetailRow(
                  label: 'Trade-In Credit',
                  value: CurrencyFormatter.formatCents(
                    transaction.tradeInCreditCents,
                  ),
                ),
                const Divider(height: 18),
                _TransactionDetailRow(
                  label: 'Cash Received',
                  value: CurrencyFormatter.formatCents(
                    transaction.cashReceivedCents,
                  ),
                ),
                if (permissions.canViewFinancialData) ...[
                  const Divider(height: 18),
                  _TransactionDetailRow(
                    label: 'Total Cost',
                    value: acquisitionValue == null
                        ? 'Not available'
                        : CurrencyFormatter.formatCents(acquisitionValue),
                  ),
                  const Divider(height: 18),
                  _HighlightedFinancialRow(
                    label: 'Profit',
                    value: profit == null
                        ? 'Not available'
                        : CurrencyFormatter.formatCents(profit),
                    positive: profit != null && profit >= 0,
                  ),
                  const Divider(height: 18),
                  _TransactionDetailRow(
                    label: 'Gross Margin',
                    value: _formatMargin(transaction.grossMargin),
                    strong: true,
                  ),
                ],
              ],
            ),
          ),
          if (transaction.id != null && transaction.id!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SaleDealSection(saleTransactionId: transaction.id!),
          ],
          if (transaction.notes != null &&
              transaction.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              key: const Key('saleTransactionNotesSection'),
              icon: Icons.notes_outlined,
              title: 'Notes',
              child: Text(transaction.notes!.trim()),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoldItemHero extends StatelessWidget {
  const _SoldItemHero({required this.transaction, required this.inventoryItem});

  final SaleTransaction transaction;
  final InventoryItem? inventoryItem;

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  String _equipmentName(InventoryItem item) {
    final model = item.model?.trim() ?? '';
    return model.isEmpty ? item.brand : '${item.brand} $model';
  }

  @override
  Widget build(BuildContext context) {
    final item = inventoryItem;

    if (item == null) {
      return const Card(
        key: Key('saleTransactionItemHero'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined),
              SizedBox(width: 12),
              Expanded(child: Text('Inventory record unavailable')),
            ],
          ),
        ),
      );
    }

    final itemId = item.id;
    final inventoryNumber =
        item.inventoryNumber ?? 'Inventory number not assigned';
    final specLine = _compactItemSpecification(item);

    return Card(
      key: const Key('saleTransactionItemHero'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: itemId == null
            ? null
            : () {
                context.goNamed(
                  AppRouteNames.inventoryDetail,
                  pathParameters: {'itemId': itemId},
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  const _StatusPill(
                    text: 'Sale',
                    foreground: Color(0xFF147A3D),
                    background: Color(0xFFE3F4E8),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(transaction.saleDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5F6D7E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ItemPhoto(photoUrl: item.photoUrls.firstOrNull),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inventoryNumber,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF1174C2),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _equipmentName(item),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF082A4A),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (specLine.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            specLine,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF526174)),
                          ),
                        ],
                        if (item.condition != null) ...[
                          const SizedBox(height: 8),
                          _StatusPill(
                            text: item.condition!.label,
                            foreground: const Color(0xFF26384B),
                            background: const Color(0xFFF1F3F6),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    text: item.status.label,
                    foreground: const Color(0xFFB02027),
                    background: const Color(0xFFFFE3E5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF082A4A),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _InventoryLinkRow extends StatelessWidget {
  const _InventoryLinkRow({
    required this.inventoryItem,
    required this.fallbackItemId,
  });

  final InventoryItem? inventoryItem;
  final String fallbackItemId;

  @override
  Widget build(BuildContext context) {
    final item = inventoryItem;
    final itemId = item?.id?.trim().isNotEmpty == true
        ? item!.id!
        : fallbackItemId.trim();
    final display = item == null
        ? 'Inventory record unavailable'
        : item.inventoryNumber ?? 'Inventory number not assigned';

    return InkWell(
      key: const Key('transactionDetailInventoryLink'),
      onTap: item == null || itemId.isEmpty
          ? null
          : () {
              context.goNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': itemId},
              );
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Inventory Item',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5F6D7E),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF082A4A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (item != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ],
        ),
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
      return const _SectionCard(
        key: Key('saleBuyerSection'),
        icon: Icons.person_outline,
        title: 'Buyer',
        child: Text('No buyer linked'),
      );
    }

    final buyerAsync = ref.watch(contactProvider(contactId));

    return buyerAsync.when(
      loading: () => const _SectionCard(
        key: Key('saleBuyerSection'),
        icon: Icons.person_outline,
        title: 'Buyer',
        child: AppLoadingState(message: 'Loading buyer information...'),
      ),
      error: (error, stackTrace) => _SectionCard(
        key: const Key('saleBuyerSection'),
        icon: Icons.person_outline,
        title: 'Buyer',
        child: AppErrorState(
          message: 'Unable to load buyer information.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(contactProvider(contactId));
          },
        ),
      ),
      data: (buyer) {
        if (buyer == null) {
          return const _SectionCard(
            key: Key('saleBuyerSection'),
            icon: Icons.person_outline,
            title: 'Buyer',
            child: Text(
              'A buyer is linked to this sale, but the Contact record is unavailable.',
            ),
          );
        }

        return _SectionCard(
          key: const Key('saleBuyerSection'),
          icon: Icons.person_outline,
          title: 'Buyer',
          child: InkWell(
            key: const Key('transactionDetailViewBuyerButton'),
            onTap: () {
              context.goNamed(
                AppRouteNames.contactDetail,
                pathParameters: {'contactId': contactId},
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Color(0xFF082A4A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      buyer.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF082A4A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
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
    final permissions = ref.watch(currentAppPermissionsProvider);

    return tradesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (trades) {
        final linkedTrades = trades
            .where((trade) => trade.saleTransactionId == saleTransactionId)
            .toList();

        if (linkedTrades.isEmpty) {
          return const SizedBox.shrink();
        }

        final incomingItemIds = <String>{
          for (final trade in linkedTrades) ...trade.incomingInventoryItemIds,
        }.toList();

        return inventoryAsync.when(
          loading: () => const _SectionCard(
            key: Key('transactionTradeInInformationCard'),
            icon: Icons.swap_horiz_rounded,
            title: 'Trade-In Items',
            child: AppLoadingState(message: 'Loading trade-in inventory...'),
          ),
          error: (error, stackTrace) => const SizedBox.shrink(),
          data: (inventoryItems) {
            final inventoryById = <String, InventoryItem>{
              for (final item in inventoryItems)
                if (item.id != null) item.id!: item,
            };

            return _SectionCard(
              key: const Key('transactionTradeInInformationCard'),
              icon: Icons.swap_horiz_rounded,
              title: 'Trade-In Items (${incomingItemIds.length})',
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < incomingItemIds.length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(height: 18),
                    _TradeInInventoryEntry(
                      inventoryItemId: incomingItemIds[index],
                      item: inventoryById[incomingItemIds[index]],
                      canViewFinancialData: permissions.canViewFinancialData,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TradeInInventoryEntry extends StatelessWidget {
  const _TradeInInventoryEntry({
    required this.inventoryItemId,
    required this.item,
    required this.canViewFinancialData,
  });

  final String inventoryItemId;
  final InventoryItem? item;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final inventoryItem = item;
    if (inventoryItem == null) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Linked trade-in inventory record unavailable.'),
      );
    }

    final model = inventoryItem.model?.trim() ?? '';
    final displayName = model.isEmpty
        ? inventoryItem.brand
        : '${inventoryItem.brand} $model';
    final specLine = _compactItemSpecification(inventoryItem);

    return InkWell(
      key: ValueKey('tradeInInventoryEntry-$inventoryItemId'),
      onTap: () {
        context.goNamed(
          AppRouteNames.inventoryDetail,
          pathParameters: {'itemId': inventoryItemId},
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _ItemPhoto(photoUrl: inventoryItem.photoUrls.firstOrNull, size: 54),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF082A4A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (specLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      specLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5F6D7E),
                      ),
                    ),
                  ],
                  if (canViewFinancialData) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Trade Value: ${CurrencyFormatter.formatCents(inventoryItem.acquisitionValueCents)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4F5E70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
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

        final displayNumberAsync = ref.watch(dealDisplayNumberProvider(dealId));
        final displayNumber = displayNumberAsync.when<String?>(
          data: (value) => value,
          loading: () => null,
          error: (error, stackTrace) => null,
        );

        return _SectionCard(
          key: const Key('saleDealCard'),
          icon: Icons.link_rounded,
          title: 'Deal Information',
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECFF),
              border: Border.all(color: const Color(0xFFC79DF2)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6E23B6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayNumber == null ? 'Deal' : 'Deal #$displayNumber',
                        key: const Key('saleDealDisplayNumber'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF5B1BA3),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This sale is part of a deal.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B397A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('saleViewDealButton'),
                  onPressed: () {
                    context.goNamed(
                      AppRouteNames.dealDetail,
                      pathParameters: {'dealId': dealId},
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6E23B6),
                    side: const BorderSide(color: Color(0xFF7D3CC3)),
                  ),
                  child: const Text('View Deal'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionDetailRow extends StatelessWidget {
  const _TransactionDetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5F6D7E)),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF082A4A),
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HighlightedFinancialRow extends StatelessWidget {
  const _HighlightedFinancialRow({
    required this.label,
    required this.value,
    required this.positive,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final foreground = positive
        ? const Color(0xFF13823D)
        : const Color(0xFFC3313A);
    final background = positive
        ? const Color(0xFFEAF7EE)
        : const Color(0xFFFFECEE);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItemPhoto extends StatelessWidget {
  const _ItemPhoto({required this.photoUrl, this.size = 82});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? _photoFallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _photoFallback(),
              ),
      ),
    );
  }

  Widget _photoFallback() {
    return const ColoredBox(
      color: Color(0xFFF1F3F6),
      child: Center(
        child: Icon(Icons.inventory_2_outlined, color: Color(0xFF8793A2)),
      ),
    );
  }
}

String _compactItemSpecification(InventoryItem item) {
  switch (item.category) {
    case InventoryCategory.bat:
      final parts = <String>[];
      if (item.lengthInches != null) {
        parts.add('${_compactNumber(item.lengthInches!)}"');
      }
      if (item.weightOunces != null) {
        parts.add('${_compactNumber(item.weightOunces!)} oz');
      }
      if (item.certification != null && item.certification!.trim().isNotEmpty) {
        parts.add(item.certification!.trim());
      }
      return parts.join('  •  ');
    case InventoryCategory.glove:
      final parts = <String>[];
      if (item.gloveSizeInches != null) {
        parts.add('${_compactNumber(item.gloveSizeInches!)}"');
      }
      if (item.handOrientation != null &&
          item.handOrientation!.trim().isNotEmpty) {
        parts.add(item.handOrientation!.trim());
      }
      return parts.join('  •  ');
    case InventoryCategory.catchersGear:
      return item.catchersGearSize?.trim() ?? '';
    case InventoryCategory.helmet:
      return item.helmetSize?.trim() ?? '';
    case InventoryCategory.other:
      return '';
  }
}

String _compactNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
