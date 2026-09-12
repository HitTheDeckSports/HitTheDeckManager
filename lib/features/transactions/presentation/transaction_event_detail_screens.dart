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
import '../domain/models/trade_transaction.dart';
import 'providers/deal_providers.dart';
import 'providers/transaction_providers.dart';

class TradeDetailScreen extends ConsumerWidget {
  const TradeDetailScreen({required this.tradeId, super.key});
  final String tradeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tradeTransactionProvider(tradeId));
    return async.when(
      loading: () => const _Loading(message: 'Loading trade...'),
      error: (e, st) => _Error(
        message: 'Unable to load trade.',
        details: e.toString(),
        retry: () => ref.invalidate(tradeTransactionProvider(tradeId)),
      ),
      data: (trade) => trade == null
          ? const _Missing(
              icon: Icons.swap_horiz_rounded,
              title: 'Trade not found.',
            )
          : _TradeBody(trade: trade),
    );
  }
}

class _TradeBody extends ConsumerWidget {
  const _TradeBody({required this.trade});
  final TradeTransaction trade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);

    return itemsAsync.when(
      loading: () => const _Loading(message: 'Loading trade inventory...'),
      error: (e, st) => _Error(
        message: 'Unable to load trade inventory.',
        details: e.toString(),
        retry: () => ref.invalidate(inventoryItemsProvider),
      ),
      data: (items) {
        final byId = <String, InventoryItem>{
          for (final item in items)
            if (item.id != null) item.id!: item,
        };

        return AppPage(
          title: 'Trade Detail',
          showHeader: false,
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                icon: Icons.swap_horiz_rounded,
                title: 'Trade Details',
                children: [
                  _Row(label: 'Trade Date', value: _date(trade.tradeDate)),
                  if (trade.includesCash) ...[
                    const Divider(),
                    _Row(
                      label: trade.cashReceivedCents > 0
                          ? 'Cash Received'
                          : 'Cash Paid',
                      value: CurrencyFormatter.formatCents(
                        trade.cashReceivedCents > 0
                            ? trade.cashReceivedCents
                            : trade.cashPaidCents,
                      ),
                    ),
                  ],
                  if (trade.paymentMethod != null) ...[
                    const Divider(),
                    _Row(
                      label: 'Payment Method',
                      value: _paymentMethod(trade.paymentMethod!.name),
                    ),
                  ],
                  if ((trade.notes ?? '').trim().isNotEmpty) ...[
                    const Divider(),
                    _Row(label: 'Notes', value: trade.notes!.trim()),
                  ],
                ],
              ),
              if (trade.outgoingInventoryItemIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InventoryGroup(
                  title: 'Items Given',
                  icon: Icons.arrow_upward_rounded,
                  ids: trade.outgoingInventoryItemIds,
                  byId: byId,
                  showValue: permissions.canViewFinancialData,
                ),
              ],
              if (trade.incomingInventoryItemIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InventoryGroup(
                  title: 'Items Received',
                  icon: Icons.arrow_downward_rounded,
                  ids: trade.incomingInventoryItemIds,
                  byId: byId,
                  showValue: permissions.canViewFinancialData,
                ),
              ],
              if ((trade.saleTransactionId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DealForSale(saleId: trade.saleTransactionId!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class DisposalDetailScreen extends ConsumerWidget {
  const DisposalDetailScreen({required this.disposalId, super.key});
  final String disposalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(disposalTransactionProvider(disposalId));
    return async.when(
      loading: () => const _Loading(message: 'Loading disposal...'),
      error: (e, st) => _Error(
        message: 'Unable to load disposal.',
        details: e.toString(),
        retry: () => ref.invalidate(disposalTransactionProvider(disposalId)),
      ),
      data: (d) => d == null
          ? const _Missing(
              icon: Icons.delete_outline_rounded,
              title: 'Disposal not found.',
            )
          : _DisposalBody(disposal: d),
    );
  }
}

class _DisposalBody extends ConsumerWidget {
  const _DisposalBody({required this.disposal});
  final DisposalTransaction disposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(
      inventoryItemProvider(disposal.inventoryItemId),
    );
    final replacementId = disposal.replacementInventoryItemId;

    return AppPage(
      title: 'Disposal Detail',
      showHeader: false,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          itemAsync.when(
            loading: () => const _LoadingCard(),
            error: (e, st) => const SizedBox.shrink(),
            data: (item) => item == null
                ? const SizedBox.shrink()
                : _ItemHero(item: item, label: 'Disposed'),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.delete_outline_rounded,
            title: 'Disposal Details',
            children: [
              _Row(label: 'Disposal Date', value: _date(disposal.disposalDate)),
              const Divider(),
              _Row(label: 'Reason', value: disposal.reason.label),
              if ((disposal.notes ?? '').trim().isNotEmpty) ...[
                const Divider(),
                _Row(label: 'Notes', value: disposal.notes!.trim()),
              ],
            ],
          ),
          if (replacementId != null) ...[
            const SizedBox(height: 12),
            _ReplacementSection(itemId: replacementId),
          ],
          const SizedBox(height: 12),
          _DealForInventory(inventoryItemId: disposal.inventoryItemId),
        ],
      ),
    );
  }
}

class ConsignmentDetailScreen extends ConsumerWidget {
  const ConsignmentDetailScreen({required this.consignmentId, super.key});
  final String consignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(consignmentTransactionProvider(consignmentId));
    return async.when(
      loading: () => const _Loading(message: 'Loading consignment...'),
      error: (e, st) => _Error(
        message: 'Unable to load consignment.',
        details: e.toString(),
        retry: () =>
            ref.invalidate(consignmentTransactionProvider(consignmentId)),
      ),
      data: (c) => c == null
          ? const _Missing(
              icon: Icons.assignment_outlined,
              title: 'Consignment not found.',
            )
          : _ConsignmentBody(consignment: c),
    );
  }
}

class _ConsignmentBody extends ConsumerWidget {
  const _ConsignmentBody({required this.consignment});
  final ConsignmentTransaction consignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(
      inventoryItemProvider(consignment.inventoryItemId),
    );
    final permissions = ref.watch(currentAppPermissionsProvider);

    return AppPage(
      title: 'Consignment Detail',
      showHeader: false,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          itemAsync.when(
            loading: () => const _LoadingCard(),
            error: (e, st) => const SizedBox.shrink(),
            data: (item) => item == null
                ? const SizedBox.shrink()
                : _ItemHero(
                    item: item,
                    label: consignment.isCompleted
                        ? 'Completed'
                        : 'Consignment',
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.assignment_outlined,
            title: 'Consignment Details',
            children: [
              _Row(
                label: 'Consignment Date',
                value: _date(consignment.consignmentDate),
              ),
              const Divider(),
              _Row(
                label: 'Status',
                value: consignment.isCompleted
                    ? 'Sold / Completed'
                    : 'Awaiting Sale',
              ),
              if (permissions.canViewFinancialData) ...[
                const Divider(),
                _Row(
                  label: 'Commission',
                  value: CurrencyFormatter.formatCents(
                    consignment.commissionCents,
                  ),
                ),
              ],
              if ((consignment.notes ?? '').trim().isNotEmpty) ...[
                const Divider(),
                _Row(label: 'Notes', value: consignment.notes!.trim()),
              ],
            ],
          ),
          if ((consignment.saleTransactionId ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              icon: Icons.receipt_long_outlined,
              title: 'Completed Sale',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('View Sale Transaction'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.goNamed(
                    AppRouteNames.transactionDetail,
                    pathParameters: {
                      'transactionId': consignment.saleTransactionId!,
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplacementSection extends ConsumerWidget {
  const _ReplacementSection({required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryItemProvider(itemId));
    return async.when(
      loading: () => const _LoadingCard(),
      error: (e, st) => const SizedBox.shrink(),
      data: (item) => item == null
          ? const SizedBox.shrink()
          : _Section(
              icon: Icons.autorenew_rounded,
              title: 'Warranty Replacement',
              children: [_InventoryLink(item: item)],
            ),
    );
  }
}

class _DealForSale extends ConsumerWidget {
  const _DealForSale({required this.saleId});
  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dealForParentSaleProvider(saleId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (deal) => deal?.id == null
          ? const SizedBox.shrink()
          : _DealLink(dealId: deal!.id!),
    );
  }
}

class _DealForInventory extends ConsumerWidget {
  const _DealForInventory({required this.inventoryItemId});
  final String inventoryItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      dealForLineageInventoryItemProvider(inventoryItemId),
    );
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (deal) => deal?.id == null
          ? const SizedBox.shrink()
          : _DealLink(dealId: deal!.id!),
    );
  }
}

class _DealLink extends ConsumerWidget {
  const _DealLink({required this.dealId});
  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numberAsync = ref.watch(dealDisplayNumberProvider(dealId));
    final display = numberAsync.when<String?>(
      data: (value) => value,
      loading: () => null,
      error: (error, stackTrace) => null,
    );
    return _Section(
      icon: Icons.link_rounded,
      title: 'Deal Information',
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5ECFF),
            border: Border.all(color: const Color(0xFFC79DF2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              display == null ? 'Deal' : 'Deal #$display',
              style: const TextStyle(
                color: Color(0xFF5B1BA3),
                fontWeight: FontWeight.w800,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF6E23B6),
            ),
            onTap: () => context.goNamed(
              AppRouteNames.dealDetail,
              pathParameters: {'dealId': dealId},
            ),
          ),
        ),
      ],
    );
  }
}

class _InventoryGroup extends StatelessWidget {
  const _InventoryGroup({
    required this.title,
    required this.icon,
    required this.ids,
    required this.byId,
    required this.showValue,
  });
  final String title;
  final IconData icon;
  final List<String> ids;
  final Map<String, InventoryItem> byId;
  final bool showValue;

  @override
  Widget build(BuildContext context) => _Section(
    icon: icon,
    title: '$title (${ids.length})',
    children: [
      for (var i = 0; i < ids.length; i++) ...[
        if (i > 0) const Divider(),
        if (byId[ids[i]] == null)
          const Text('Inventory record unavailable.')
        else
          _InventoryLink(item: byId[ids[i]]!, showValue: showValue),
      ],
    ],
  );
}

class _InventoryLink extends StatelessWidget {
  const _InventoryLink({required this.item, this.showValue = false});
  final InventoryItem item;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final model = item.model?.trim() ?? '';
    final name = model.isEmpty ? item.brand : '${item.brand} $model';
    final subtitle = showValue
        ? '$name\nValue: ${CurrencyFormatter.formatCents(item.acquisitionValueCents)}'
        : name;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.inventoryNumber ?? 'Inventory number not assigned',
        style: const TextStyle(
          color: Color(0xFF1174C2),
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: item.id == null
          ? null
          : () => context.goNamed(
              AppRouteNames.inventoryDetail,
              pathParameters: {'itemId': item.id!},
            ),
    );
  }
}

class _ItemHero extends StatelessWidget {
  const _ItemHero({required this.item, required this.label});
  final InventoryItem item;
  final String label;

  @override
  Widget build(BuildContext context) {
    final model = item.model?.trim() ?? '';
    final name = model.isEmpty ? item.brand : '${item.brand} $model';
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: item.id == null
            ? null
            : () => context.goNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': item.id!},
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 34,
                color: Color(0xFF082A4A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.inventoryNumber ?? 'Inventory number not assigned',
                      style: const TextStyle(
                        color: Color(0xFF1174C2),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF082A4A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
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
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: Color(0xFF5F6D7E))),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: Color(0xFF082A4A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Details',
    showHeader: false,
    compact: true,
    child: AppLoadingState(message: message),
  );
}

class _Error extends StatelessWidget {
  const _Error({
    required this.message,
    required this.details,
    required this.retry,
  });
  final String message;
  final String details;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Details',
    showHeader: false,
    compact: true,
    child: AppErrorState(message: message, details: details, onRetry: retry),
  );
}

class _Missing extends StatelessWidget {
  const _Missing({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Details',
    showHeader: false,
    compact: true,
    child: AppEmptyState(
      icon: icon,
      title: title,
      message: 'The record may have been removed or is unavailable.',
    ),
  );
}

String _date(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

String _paymentMethod(String name) => switch (name) {
  'cash' => 'Cash',
  'card' => 'Card',
  'venmo' => 'Venmo',
  'paypal' => 'PayPal',
  'zelle' => 'Zelle',
  _ => name,
};
