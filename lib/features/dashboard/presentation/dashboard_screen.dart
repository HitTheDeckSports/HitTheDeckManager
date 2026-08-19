import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/dashboard_metrics.dart';
import 'providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return AppPage(
      title: 'Dashboard',
      subtitle: 'Review month-to-date performance and current inventory.',
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
          const SizedBox(height: 32),
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
            data: (metrics) => _DashboardMetricsContent(metrics: metrics),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricsContent extends StatelessWidget {
  const _DashboardMetricsContent({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Month to Date', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _MetricGrid(
          children: [
            _MetricCard(
              key: const Key('dashboardRevenueCard'),
              label: 'Total Revenue',
              value: CurrencyFormatter.formatCents(metrics.totalRevenueCents),
            ),
            _MetricCard(
              key: const Key('dashboardCostCard'),
              label: 'Total Cost',
              value: CurrencyFormatter.formatCents(metrics.totalCostCents),
            ),
            _MetricCard(
              key: const Key('dashboardProfitCard'),
              label: 'Total Profit',
              value: CurrencyFormatter.formatCents(metrics.totalProfitCents),
            ),
            _MetricCard(
              key: const Key('dashboardMarginCard'),
              label: 'Gross Margin',
              value: '${(metrics.grossMargin * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Current Inventory',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          children: [
            _MetricCard(
              key: const Key('dashboardInventoryValueCard'),
              label: 'Open Inventory Value',
              value: CurrencyFormatter.formatCents(
                metrics.openInventoryValueCents,
              ),
            ),
            _MetricCard(
              key: const Key('dashboardInventoryCostCard'),
              label: 'Open Inventory Cost',
              value: CurrencyFormatter.formatCents(
                metrics.openInventoryCostCents,
              ),
            ),
            _MetricCard(
              key: const Key('dashboardPotentialProfitCard'),
              label: 'Open Potential Profit',
              value: CurrencyFormatter.formatCents(
                metrics.openPotentialProfitCents,
              ),
            ),
            _MetricCard(
              key: const Key('dashboardInventoryCountCard'),
              label: 'Inventory Count',
              value: metrics.inventoryCount.toString(),
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
  const _MetricCard({required this.label, required this.value, super.key});

  final String label;
  final String value;

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
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
