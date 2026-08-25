import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../application/dashboard_metrics.dart';
import 'providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);

    return AppPage(
      title: 'Dashboard',
      subtitle: 'A live overview of your current inventory.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const Key('dashboardAddInventoryButton'),
                onPressed: () {
                  context.goNamed(AppRouteNames.buyInventory);
                },
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add Inventory'),
              ),
              FilledButton.icon(
                key: const Key('dashboardScanQrButton'),
                onPressed: () {
                  context.goNamed(AppRouteNames.inventoryScanner);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          metricsAsync.when(
            loading: () =>
                const AppLoadingState(message: 'Loading dashboard...'),
            error: (error, stackTrace) => AppErrorState(
              message: 'Unable to load dashboard.',
              details: error.toString(),
              onRetry: () {
                ref.invalidate(dashboardMetricsProvider);
              },
            ),
            data: (metrics) => _DashboardMetricsContent(
              metrics: metrics,
              canViewFinancialData: permissions.canViewFinancialData,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricsContent extends StatelessWidget {
  const _DashboardMetricsContent({
    required this.metrics,
    required this.canViewFinancialData,
  });

  final DashboardMetrics metrics;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Inventory Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          children: [
            _MetricCard(
              key: const Key('dashboardInventoryCountCard'),
              label: 'Total Inventory Items',
              value: metrics.inventoryCount.toString(),
            ),
            if (canViewFinancialData)
              _MetricCard(
                key: const Key('dashboardInventoryCostCard'),
                label: 'Total Cost of Inventory',
                value: CurrencyFormatter.formatCents(
                  metrics.openInventoryCostCents,
                ),
              ),
            _MetricCard(
              key: const Key('dashboardInventoryValueCard'),
              label: 'Est. Inventory Revenue',
              value: CurrencyFormatter.formatCents(
                metrics.openInventoryValueCents,
              ),
            ),
            if (canViewFinancialData)
              _MetricCard(
                key: const Key('dashboardPotentialProfitCard'),
                label: 'Est. Inventory Profit',
                value: CurrencyFormatter.formatCents(
                  metrics.openPotentialProfitCents,
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Quick Stats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _MetricGrid(
          children: [
            _MetricCard(
              key: const Key('dashboardAvailableItemsCard'),
              label: 'Available Items',
              value: metrics.availableItems.toString(),
            ),
            _MetricCard(
              key: const Key('dashboardUnitsSoldCard'),
              label: 'Items Sold Month to Date',
              value: metrics.unitsSold.toString(),
            ),
            _MetricCard(
              key: const Key('dashboardBrokenItemsCard'),
              label: 'Needs Repair',
              value: metrics.brokenItems.toString(),
            ),
            _MetricCard(
              key: const Key('dashboardAverageDaysCard'),
              label: 'Average Days in Inventory',
              value: metrics.averageDaysInInventory.toString(),
              suffix: 'days',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.suffix,
    super.key,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      suffix!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
