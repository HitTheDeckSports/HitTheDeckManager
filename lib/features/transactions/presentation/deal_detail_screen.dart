import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../inventory/domain/models/inventory_enums.dart';
import '../domain/models/deal_status.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import 'providers/deal_providers.dart';

class DealDetailScreen extends ConsumerWidget {
  const DealDetailScreen({required this.dealId, super.key});

  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dealSummaryProvider(dealId));
    final permissions = ref.watch(currentAppPermissionsProvider);

    return summaryAsync.when(
      loading: () => const AppPage(
        title: 'Deal Details',
        child: AppLoadingState(message: 'Loading Deal...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Deal Details',
        child: AppErrorState(
          message: 'Unable to load Deal.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(dealSummaryProvider(dealId));
          },
        ),
      ),
      data: (summary) {
        if (summary == null) {
          return const AppPage(
            title: 'Deal Details',
            child: AppEmptyState(
              icon: Icons.handshake_outlined,
              title: 'Deal not found.',
              message: 'The Deal may have been removed.',
            ),
          );
        }

        return AppPage(
          title: 'Deal Details',
          subtitle: summary.status.label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (permissions.canViewFinancialData) ...[
                _Section(
                  title: 'Profit Summary',
                  children: [
                    _Row(
                      label: 'Parent Transaction Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.parentTransactionProfitCents,
                      ),
                    ),
                    _Row(
                      label: 'Realized Child Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.realizedChildProfitCents,
                      ),
                    ),
                    _Row(
                      label: 'Projected Child Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.projectedChildProfitCents,
                      ),
                    ),
                    _Row(
                      label: 'Realized Deal Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.realizedDealProfitCents,
                      ),
                    ),
                    _Row(
                      label: 'Projected Deal Profit',
                      value: CurrencyFormatter.formatCents(
                        summary.projectedDealProfitCents,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              _Section(
                title: 'Deal Progress',
                children: [
                  _Row(label: 'Status', value: summary.status.label),
                  _Row(
                    label: 'Realized Child Items',
                    value: summary.realizedChildCount.toString(),
                  ),
                  _Row(
                    label: 'Open Child Items',
                    value: summary.openChildCount.toString(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('dealViewParentSaleButton'),
                      onPressed: () {
                        context.goNamed(
                          AppRouteNames.transactionDetail,
                          pathParameters: {
                            'transactionId':
                                summary.deal.parentSaleTransactionId,
                          },
                        );
                      },
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('View Parent Sale'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DealChildrenSection(
                childInventoryItemIds: summary.deal.childInventoryItemIds,
                canViewFinancialData: permissions.canViewFinancialData,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DealChildrenSection extends ConsumerWidget {
  const _DealChildrenSection({
    required this.childInventoryItemIds,
    required this.canViewFinancialData,
  });

  final List<String> childInventoryItemIds;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return inventoryAsync.when(
      loading: () => const _Section(
        title: 'Child Inventory',
        children: [AppLoadingState(message: 'Loading child inventory...')],
      ),
      error: (error, stackTrace) => _Section(
        title: 'Child Inventory',
        children: [
          AppErrorState(
            message: 'Unable to load child inventory.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(inventoryItemsProvider);
            },
          ),
        ],
      ),
      data: (items) {
        final byId = <String, InventoryItem>{
          for (final item in items)
            if (item.id != null) item.id!: item,
        };

        return _Section(
          title: 'Child Inventory',
          children: [
            for (
              var index = 0;
              index < childInventoryItemIds.length;
              index++
            ) ...[
              if (index > 0) const Divider(height: 32),
              _ChildItem(
                itemId: childInventoryItemIds[index],
                item: byId[childInventoryItemIds[index]],
                canViewFinancialData: canViewFinancialData,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChildItem extends StatelessWidget {
  const _ChildItem({
    required this.itemId,
    required this.item,
    required this.canViewFinancialData,
  });

  final String itemId;
  final InventoryItem? item;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final child = item;

    if (child == null) {
      return const Text('The child inventory record is unavailable.');
    }

    final model = child.model?.trim();
    final name = model == null || model.isEmpty
        ? child.brand
        : '${child.brand} $model';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          label: 'Inventory Item',
          value: '${child.inventoryNumber ?? 'Not assigned'} â€” $name',
        ),
        _Row(label: 'Status', value: child.status.label),
        if (canViewFinancialData)
          _Row(
            label: 'Acquisition Value',
            value: CurrencyFormatter.formatCents(child.acquisitionValueCents),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: ValueKey('dealViewChildItemButton-$itemId'),
            onPressed: () {
              context.goNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': itemId},
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
