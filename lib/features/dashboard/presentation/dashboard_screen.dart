import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/dashboard_date_range.dart';
import '../application/dashboard_metrics.dart';
import 'providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final rangeSelection = ref.watch(dashboardDateRangeSelectionProvider);

    return AppPage(
      title: 'Dashboard',
      subtitle: 'Review business performance and current inventory.',
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
          _DateRangeSelector(selection: rangeSelection),
          const SizedBox(height: 24),
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

class _DateRangeSelector extends ConsumerWidget {
  const _DateRangeSelector({required this.selection});

  final DashboardDateRangeSelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selector = DropdownButtonFormField<DashboardDateRangePreset>(
      key: const Key('dashboardDateRangeSelector'),
      isExpanded: true,
      initialValue: selection.preset,
      decoration: const InputDecoration(
        labelText: 'Date Range',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: DashboardDateRangePreset.today,
          child: Text('Today'),
        ),
        DropdownMenuItem(
          value: DashboardDateRangePreset.last7Days,
          child: Text('Last 7 Days'),
        ),
        DropdownMenuItem(
          value: DashboardDateRangePreset.monthToDate,
          child: Text('Month to Date'),
        ),
        DropdownMenuItem(
          value: DashboardDateRangePreset.last30Days,
          child: Text('Last 30 Days'),
        ),
        DropdownMenuItem(
          value: DashboardDateRangePreset.yearToDate,
          child: Text('Year to Date'),
        ),
        DropdownMenuItem(
          value: DashboardDateRangePreset.custom,
          child: Text('Custom'),
        ),
      ],
      onChanged: (preset) async {
        if (preset == null) {
          return;
        }

        final controller = ref.read(
          dashboardDateRangeSelectionProvider.notifier,
        );

        if (preset != DashboardDateRangePreset.custom) {
          controller.selectPreset(preset);
          return;
        }

        final now = ref.read(dashboardAsOfProvider);
        final currentResolved = selection.resolve(asOf: now);

        final selectedRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 1, 12, 31),
          initialDateRange: DateTimeRange(
            start: currentResolved.startInclusive,
            end: currentResolved.endExclusive.subtract(const Duration(days: 1)),
          ),
          helpText: 'Select dashboard date range',
        );

        if (selectedRange == null) {
          return;
        }

        controller.selectCustom(
          startDate: selectedRange.start,
          endDate: selectedRange.end,
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            key: const Key('dashboardDateRangeNarrowLayout'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Performance Period',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              selector,
            ],
          );
        }

        return Row(
          key: const Key('dashboardDateRangeWideLayout'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Performance Period',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 260, child: selector),
          ],
        );
      },
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
        Text(
          metrics.dateRangeLabel,
          key: const Key('dashboardPerformancePeriodLabel'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          children: [
            _MetricCard(
              key: const Key('dashboardRevenueCard'),
              label: 'Revenue',
              value: CurrencyFormatter.formatCents(metrics.totalRevenueCents),
            ),
            _MetricCard(
              key: const Key('dashboardCostCard'),
              label: 'Cost',
              value: CurrencyFormatter.formatCents(metrics.totalCostCents),
            ),
            _MetricCard(
              key: const Key('dashboardProfitCard'),
              label: 'Profit',
              value: CurrencyFormatter.formatCents(metrics.totalProfitCents),
            ),
            _MetricCard(
              key: const Key('dashboardMarginCard'),
              label: 'Gross Margin',
              value: '${(metrics.grossMargin * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Quick Snapshot', style: Theme.of(context).textTheme.titleLarge),
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
              label: 'Units Sold',
              value: metrics.unitsSold.toString(),
            ),
            _MetricCard(
              key: const Key('dashboardAverageDaysCard'),
              label: 'Average Days in Inventory',
              value: metrics.averageDaysInInventory.toString(),
              suffix: 'days',
            ),
            _MetricCard(
              key: const Key('dashboardBrokenItemsCard'),
              label: 'Broken Items',
              value: metrics.brokenItems.toString(),
            ),
          ],
        ),
        const SizedBox(height: 28),
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
              key: const Key('dashboardInventoryCountCard'),
              label: 'Inventory Count',
              value: metrics.inventoryCount.toString(),
            ),
            _MetricCard(
              key: const Key('dashboardPotentialProfitCard'),
              label: 'Current Inventory Potential Profit',
              value: CurrencyFormatter.formatCents(
                metrics.openPotentialProfitCents,
              ),
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
