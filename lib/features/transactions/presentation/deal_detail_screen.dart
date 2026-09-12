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
import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/deal_status.dart';
import 'providers/deal_providers.dart';

class DealDetailScreen extends ConsumerWidget {
  const DealDetailScreen({required this.dealId, super.key});
  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dealSummaryProvider(dealId));
    final numberAsync = ref.watch(dealDisplayNumberProvider(dealId));
    final permissions = ref.watch(currentAppPermissionsProvider);

    return summaryAsync.when(
      loading: () => const AppPage(
        title: 'Deal Details',
        showHeader: false,
        compact: true,
        child: AppLoadingState(message: 'Loading Deal...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Deal Details',
        showHeader: false,
        compact: true,
        child: AppErrorState(
          message: 'Unable to load Deal.',
          details: error.toString(),
          onRetry: () => ref.invalidate(dealSummaryProvider(dealId)),
        ),
      ),
      data: (summary) {
        if (summary == null) {
          return const AppPage(
            title: 'Deal Details',
            showHeader: false,
            compact: true,
            child: AppEmptyState(
              icon: Icons.handshake_outlined,
              title: 'Deal not found.',
              message: 'The Deal may have been removed.',
            ),
          );
        }

        final displayNumber = numberAsync.when<String?>(
          data: (value) => value,
          loading: () => null,
          error: (error, stackTrace) => null,
        );
        return AppPage(
          title: 'Deal Details',
          showHeader: false,
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5ECFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.link_rounded,
                          color: Color(0xFF6E23B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayNumber == null
                                  ? 'Deal'
                                  : 'Deal #$displayNumber',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF082A4A),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Text(
                              summary.status.label,
                              style: const TextStyle(color: Color(0xFF5F6D7E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (permissions.canViewFinancialData) ...[
                const SizedBox(height: 12),
                _Section(
                  icon: Icons.attach_money_rounded,
                  title: 'Profit Summary',
                  children: [
                    _Row(
                      label: 'Parent Transaction Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.parentTransactionProfitCents,
                      ),
                    ),
                    const Divider(),
                    _Row(
                      label: 'Realized Child Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.realizedChildProfitCents,
                      ),
                    ),
                    const Divider(),
                    _Row(
                      label: 'Projected Child Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.projectedChildProfitCents,
                      ),
                    ),
                    const Divider(),
                    _Row(
                      label: 'Realized Deal Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.realizedDealProfitCents,
                      ),
                      strong: true,
                    ),
                    const Divider(),
                    _Row(
                      label: 'Projected Deal Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.projectedDealProfitCents,
                      ),
                      strong: true,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _Section(
                icon: Icons.timeline_rounded,
                title: 'Deal Progress',
                children: [
                  _Row(label: 'Status', value: summary.status.label),
                  const Divider(),
                  _Row(
                    label: 'Realized Child Items',
                    value: summary.realizedChildCount.toString(),
                  ),
                  const Divider(),
                  _Row(
                    label: 'Open Child Items',
                    value: summary.openChildCount.toString(),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    key: const Key('dealViewParentSaleButton'),
                    title: const Text('View Parent Sale'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.pushNamed(
                      AppRouteNames.transactionDetail,
                      pathParameters: {
                        'transactionId': summary.deal.parentSaleTransactionId,
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Children(
                ids: summary.deal.childInventoryItemIds,
                showValue: permissions.canViewFinancialData,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Children extends ConsumerWidget {
  const _Children({required this.ids, required this.showValue});
  final List<String> ids;
  final bool showValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryItemsProvider);
    return async.when(
      loading: () => const _Section(
        icon: Icons.inventory_2_outlined,
        title: 'Child Inventory',
        children: [AppLoadingState(message: 'Loading child inventory...')],
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (items) {
        final byId = <String, InventoryItem>{
          for (final item in items)
            if (item.id != null) item.id!: item,
        };
        return _Section(
          icon: Icons.inventory_2_outlined,
          title: 'Child Inventory (${ids.length})',
          children: [
            for (var i = 0; i < ids.length; i++) ...[
              if (i > 0) const Divider(),
              if (byId[ids[i]] == null)
                const Text('Child inventory record unavailable.')
              else
                _ChildItem(item: byId[ids[i]]!, showValue: showValue),
            ],
          ],
        );
      },
    );
  }
}

class _ChildItem extends StatelessWidget {
  const _ChildItem({required this.item, required this.showValue});
  final InventoryItem item;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final model = item.model?.trim() ?? '';
    final name = model.isEmpty ? item.brand : '${item.brand} $model';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.inventoryNumber ?? 'Inventory number not assigned',
        style: const TextStyle(
          color: Color(0xFF1174C2),
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        showValue
            ? '$name\n${item.status.label} • ${CurrencyFormatter.formatCents(item.acquisitionValueCents)}'
            : '$name\n${item.status.label}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: item.id == null
          ? null
          : () => context.pushNamed(
              AppRouteNames.inventoryDetail,
              pathParameters: {'itemId': item.id!},
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
  const _Row({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

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
          style: TextStyle(
            color: const Color(0xFF082A4A),
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
