import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/currency_formatter.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../transactions/domain/models/deal_lineage_edge_type.dart';
import '../../transactions/domain/models/deal_status.dart';
import '../application/deal_rollup_report.dart';
import '../application/recursive_deal_report.dart';
import '../application/financial_performance_report.dart';
import '../application/inventory_aging_report.dart';
import '../application/report_date_range.dart';
import '../application/reports_snapshot.dart';
import '../application/sales_analysis_report.dart';
import 'providers/report_providers.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentAppPermissionsProvider);

    if (!permissions.canAccessReports) {
      return const AppPage(
        title: 'Reports',
        subtitle: 'Financial reporting is restricted to Owners and Admins.',
        child: Center(
          child: Text('You do not have permission to view financial reports.'),
        ),
      );
    }

    final reportsAsync = ref.watch(reportsSnapshotProvider);
    final selection = ref.watch(reportDateRangeSelectionProvider);

    return AppPage(
      title: 'Reports',
      subtitle:
          'Analyze financial performance, sales, inventory aging, and Deals.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportDateRangeSelector(selection: selection),
          const SizedBox(height: 24),
          reportsAsync.when(
            loading: () => const AppLoadingState(message: 'Loading reports...'),
            error: (error, stackTrace) => AppErrorState(
              message: 'Unable to load reports.',
              details: error.toString(),
              onRetry: () {
                ref.invalidate(reportsSnapshotProvider);
              },
            ),
            data: (snapshot) => _ReportsContent(snapshot: snapshot),
          ),
        ],
      ),
    );
  }
}

class _ReportDateRangeSelector extends ConsumerWidget {
  const _ReportDateRangeSelector({required this.selection});

  final ReportDateRangeSelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selector = DropdownButtonFormField<ReportDateRangePreset>(
      key: const Key('reportDateRangeSelector'),
      isExpanded: true,
      initialValue: selection.preset,
      decoration: const InputDecoration(
        labelText: 'Date Range',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: ReportDateRangePreset.today,
          child: Text('Today'),
        ),
        DropdownMenuItem(
          value: ReportDateRangePreset.last7Days,
          child: Text('Last 7 Days'),
        ),
        DropdownMenuItem(
          value: ReportDateRangePreset.monthToDate,
          child: Text('Month to Date'),
        ),
        DropdownMenuItem(
          value: ReportDateRangePreset.last30Days,
          child: Text('Last 30 Days'),
        ),
        DropdownMenuItem(
          value: ReportDateRangePreset.yearToDate,
          child: Text('Year to Date'),
        ),
        DropdownMenuItem(
          value: ReportDateRangePreset.custom,
          child: Text('Custom'),
        ),
      ],
      onChanged: (preset) async {
        if (preset == null) {
          return;
        }

        final controller = ref.read(reportDateRangeSelectionProvider.notifier);

        if (preset != ReportDateRangePreset.custom) {
          controller.selectPreset(preset);
          return;
        }

        final now = ref.read(reportAsOfProvider);
        final current = selection.resolve(asOf: now);

        final selectedRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 1, 12, 31),
          initialDateRange: DateTimeRange(
            start: current.startInclusive,
            end: current.endExclusive.subtract(const Duration(days: 1)),
          ),
          helpText: 'Select report date range',
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
            key: const Key('reportDateRangeNarrowLayout'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report Period',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              selector,
            ],
          );
        }

        return Row(
          key: const Key('reportDateRangeWideLayout'),
          children: [
            Expanded(
              child: Text(
                'Report Period',
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

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FinancialPerformanceSection(report: snapshot.financialPerformance),
        const SizedBox(height: 28),
        _SalesAnalysisSection(snapshot: snapshot),
        const SizedBox(height: 28),
        _InventoryAgingSection(report: snapshot.inventoryAging),
        const SizedBox(height: 28),
        _DealsSection(
          report: snapshot.deals,
          recursiveReport: snapshot.recursiveDeals,
        ),
      ],
    );
  }
}

class _FinancialPerformanceSection extends StatelessWidget {
  const _FinancialPerformanceSection({required this.report});

  final FinancialPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      key: const Key('financialPerformanceSection'),
      title: 'Financial Performance',
      subtitle: report.rangeLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsiveMetricGrid(
            children: [
              _ReportMetricCard(
                label: 'Revenue',
                value: CurrencyFormatter.formatCents(report.revenueCents),
              ),
              _ReportMetricCard(
                label: 'Cost',
                value: CurrencyFormatter.formatCents(report.costCents),
              ),
              _ReportMetricCard(
                label: 'Profit',
                value: CurrencyFormatter.formatCents(report.profitCents),
              ),
              _ReportMetricCard(
                label: 'Gross Margin',
                value: '${(report.grossMargin * 100).toStringAsFixed(1)}%',
              ),
              _ReportMetricCard(
                label: 'Units Sold',
                value: report.unitsSold.toString(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Monthly Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (report.monthlyTrend.isEmpty)
            const _EmptyReportState(message: 'No sales in this period.')
          else
            for (final point in report.monthlyTrend)
              _FinancialTrendRow(point: point),
        ],
      ),
    );
  }
}

class _FinancialTrendRow extends StatelessWidget {
  const _FinancialTrendRow({required this.point});

  final FinancialTrendPoint point;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _LabeledValue(label: 'Month', value: _monthLabel(point.month)),
            _LabeledValue(
              label: 'Revenue',
              value: CurrencyFormatter.formatCents(point.revenueCents),
            ),
            _LabeledValue(
              label: 'Cost',
              value: CurrencyFormatter.formatCents(point.costCents),
            ),
            _LabeledValue(
              label: 'Profit',
              value: CurrencyFormatter.formatCents(point.profitCents),
            ),
            _LabeledValue(label: 'Units', value: point.unitsSold.toString()),
          ],
        ),
      ),
    );
  }
}

class _SalesAnalysisSection extends StatelessWidget {
  const _SalesAnalysisSection({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      key: const Key('salesAnalysisSection'),
      title: 'Sales Analysis',
      subtitle: 'Units, revenue, and profit by Category, Brand, and Model.',
      child: Column(
        children: [
          _SalesDimensionCard(
            title: 'By Category',
            report: snapshot.salesByCategory,
          ),
          const SizedBox(height: 12),
          _SalesDimensionCard(title: 'By Brand', report: snapshot.salesByBrand),
          const SizedBox(height: 12),
          _SalesDimensionCard(title: 'By Model', report: snapshot.salesByModel),
        ],
      ),
    );
  }
}

class _SalesDimensionCard extends StatelessWidget {
  const _SalesDimensionCard({required this.title, required this.report});

  final String title;
  final SalesAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(title),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (report.rows.isEmpty)
            const _EmptyReportState(message: 'No sales in this period.')
          else
            for (final row in report.rows) _SalesAnalysisRowWidget(row: row),
        ],
      ),
    );
  }
}

class _SalesAnalysisRowWidget extends StatelessWidget {
  const _SalesAnalysisRowWidget({required this.row});

  final SalesAnalysisRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;

          final values = Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LabeledValue(label: 'Units', value: row.units.toString()),
              _LabeledValue(
                label: 'Revenue',
                value: CurrencyFormatter.formatCents(row.revenueCents),
              ),
              _LabeledValue(
                label: 'Profit',
                value: CurrencyFormatter.formatCents(row.profitCents),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(row.label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                values,
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              values,
            ],
          );
        },
      ),
    );
  }
}

class _InventoryAgingSection extends StatelessWidget {
  const _InventoryAgingSection({required this.report});

  final InventoryAgingReport report;

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      key: const Key('inventoryAgingSection'),
      title: 'Inventory Aging',
      subtitle: 'Current open inventory grouped by days in inventory.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in report.rows) _InventoryAgingRowWidget(row: row),
          if (report.unclassifiedItemIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${report.unclassifiedItemIds.length} open item(s) have no acquisition date and are not assigned to an aging bucket.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _InventoryAgingRowWidget extends StatelessWidget {
  const _InventoryAgingRowWidget({required this.row});

  final InventoryAgingRow row;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final values = Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LabeledValue(label: 'Items', value: row.itemCount.toString()),
                _LabeledValue(
                  label: 'Cost',
                  value: CurrencyFormatter.formatCents(row.inventoryCostCents),
                ),
                _LabeledValue(
                  label: 'Asking Value',
                  value: CurrencyFormatter.formatCents(row.askingValueCents),
                ),
                _LabeledValue(
                  label: 'Potential Profit',
                  value: CurrencyFormatter.formatCents(
                    row.potentialProfitCents,
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    row.bucket.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  values,
                ],
              );
            }

            return Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    row.bucket.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Expanded(child: values),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DealsSection extends StatelessWidget {
  const _DealsSection({required this.report, required this.recursiveReport});

  final DealRollupReport report;
  final RecursiveDealReport recursiveReport;

  @override
  Widget build(BuildContext context) {
    if (recursiveReport.rows.isNotEmpty) {
      return _RecursiveDealsSection(report: recursiveReport);
    }

    final uncompleted = report.rows
        .where((row) => row.status != DealStatus.completed)
        .toList();
    final completed = report.rows
        .where((row) => row.status == DealStatus.completed)
        .toList();

    return _ReportSection(
      key: const Key('dealsSection'),
      title: 'Deals',
      subtitle: 'Realized and projected economics for trade-related Deals.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Uncompleted Deals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (uncompleted.isEmpty)
            const _EmptyReportState(message: 'No uncompleted Deals.')
          else
            for (final row in uncompleted) _DealReportCard(row: row),
          const SizedBox(height: 16),
          Text(
            'Completed Deals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (completed.isEmpty)
            const _EmptyReportState(message: 'No completed Deals.')
          else
            for (final row in completed) _DealReportCard(row: row),
        ],
      ),
    );
  }
}

class _RecursiveDealsSection extends StatelessWidget {
  const _RecursiveDealsSection({required this.report});

  final RecursiveDealReport report;

  @override
  Widget build(BuildContext context) {
    final uncompleted = report.rows
        .where((row) => row.summary.status != DealStatus.completed)
        .toList(growable: false);
    final completed = report.rows
        .where((row) => row.summary.status == DealStatus.completed)
        .toList(growable: false);

    return _ReportSection(
      key: const Key('dealsSection'),
      title: 'Deals',
      subtitle:
          'Full Deal trees with overall and branch-level realized/projected results.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Uncompleted Deals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (uncompleted.isEmpty)
            const _EmptyReportState(message: 'No uncompleted Deals.')
          else
            for (final row in uncompleted) _RecursiveDealCard(row: row),
          const SizedBox(height: 16),
          Text(
            'Completed Deals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (completed.isEmpty)
            const _EmptyReportState(message: 'No completed Deals.')
          else
            for (final row in completed) _RecursiveDealCard(row: row),
        ],
      ),
    );
  }
}

class _RecursiveDealCard extends StatelessWidget {
  const _RecursiveDealCard({required this.row});

  final RecursiveDealReportRow row;

  @override
  Widget build(BuildContext context) {
    final summary = row.summary;
    final displayId = row.deal.id ?? 'Sale ${row.deal.parentSaleTransactionId}';

    return Card(
      key: Key('recursiveDealCard_$displayId'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: Key('recursiveDealExpansion_$displayId'),
        title: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(displayId, style: Theme.of(context).textTheme.titleSmall),
            Chip(label: Text(summary.status.label)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LabeledValue(
                label: 'Parent Item',
                value: row.parentSale.inventoryItemId,
              ),
              _LabeledValue(
                label: 'Realized',
                value: CurrencyFormatter.formatCents(
                  summary.realizedDealProfitCents,
                ),
              ),
              _LabeledValue(
                label: 'Projected',
                value: CurrencyFormatter.formatCents(
                  summary.projectedDealProfitCents,
                ),
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Deal Summary',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LabeledValue(
                label: 'Parent Sale Profit',
                value: CurrencyFormatter.formatCents(
                  summary.parentTransactionProfitCents,
                ),
              ),
              _LabeledValue(
                label: 'Branch Realized',
                value: CurrencyFormatter.formatCents(
                  summary.realizedBranchProfitCents,
                ),
              ),
              _LabeledValue(
                label: 'Open Projection',
                value: CurrencyFormatter.formatCents(
                  summary.projectedOpenBranchProfitCents,
                ),
              ),
              _LabeledValue(
                label: 'Open Items',
                value: summary.openInventoryCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Branches',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 6),
          for (final branch in summary.branches)
            _RecursiveDealBranchCard(row: row, branch: branch),
        ],
      ),
    );
  }
}

class _RecursiveDealBranchCard extends StatelessWidget {
  const _RecursiveDealBranchCard({required this.row, required this.branch});

  final RecursiveDealReportRow row;
  final dynamic branch;

  @override
  Widget build(BuildContext context) {
    final rootItem = row.inventoryItemFor(branch.rootChildInventoryItemId);
    final rootLabel = _inventoryLabel(
      rootItem,
      branch.rootChildInventoryItemId as String,
    );
    final branchNodes = row.tree.branchFor(
      branch.rootChildInventoryItemId as String,
    );

    return Card(
      key: Key('recursiveDealBranch_${branch.rootChildInventoryItemId}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: Key(
          'recursiveDealBranchExpansion_${branch.rootChildInventoryItemId}',
        ),
        title: Text(rootLabel),
        subtitle: Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _LabeledValue(
              label: 'Realized',
              value: CurrencyFormatter.formatCents(
                branch.realizedProfitCents as int,
              ),
            ),
            _LabeledValue(
              label: 'Projected',
              value: CurrencyFormatter.formatCents(
                branch.projectedBranchProfitCents as int,
              ),
            ),
            _LabeledValue(
              label: 'Open',
              value: (branch.openInventoryCount as int).toString(),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        children: [
          for (final node in branchNodes)
            _DealLineageItemRow(
              label: _inventoryLabel(
                row.inventoryItemFor(node.inventoryItemId),
                node.inventoryItemId,
              ),
              depth: node.depth,
              relationship: node.edgeTypeFromParent,
            ),
        ],
      ),
    );
  }
}

class _DealLineageItemRow extends StatelessWidget {
  const _DealLineageItemRow({
    required this.label,
    required this.depth,
    required this.relationship,
  });

  final String label;
  final int depth;
  final DealLineageEdgeType? relationship;

  @override
  Widget build(BuildContext context) {
    final relationshipLabel = switch (relationship) {
      DealLineageEdgeType.trade => 'Trade',
      DealLineageEdgeType.warrantyReplacement => 'Warranty',
      null => 'Branch Root',
    };

    return Padding(
      padding: EdgeInsets.only(left: depth * 14.0, top: 6, bottom: 6),
      child: Row(
        children: [
          Icon(
            relationship == DealLineageEdgeType.warrantyReplacement
                ? Icons.verified_outlined
                : relationship == DealLineageEdgeType.trade
                ? Icons.swap_horiz
                : Icons.account_tree_outlined,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(relationshipLabel, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

String _inventoryLabel(dynamic item, String fallbackId) {
  if (item == null) {
    return fallbackId;
  }

  final inventoryNumber = item.inventoryNumber as String?;
  final brand = item.brand as String;
  final model = item.model as String?;

  final descriptiveName = [
    brand.trim(),
    if (model != null && model.trim().isNotEmpty) model.trim(),
  ].where((value) => value.isNotEmpty).join(' ');

  if (inventoryNumber != null && inventoryNumber.trim().isNotEmpty) {
    return descriptiveName.isEmpty
        ? inventoryNumber
        : '$inventoryNumber - $descriptiveName';
  }

  return descriptiveName.isEmpty ? fallbackId : descriptiveName;
}

class _DealReportCard extends StatelessWidget {
  const _DealReportCard({required this.row});

  final DealRollupReportRow row;

  @override
  Widget build(BuildContext context) {
    final displayId = row.deal.id ?? 'Sale ${row.deal.parentSaleTransactionId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(displayId, style: Theme.of(context).textTheme.titleSmall),
                Chip(label: Text(row.status.label)),
                if (row.cycleDetected)
                  const Chip(label: Text('Cycle detected')),
                if (row.depthLimitReached)
                  const Chip(label: Text('Depth limit reached')),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LabeledValue(
                  label: 'Realized Profit',
                  value: CurrencyFormatter.formatCents(row.realizedProfitCents),
                ),
                _LabeledValue(
                  label: 'Projected Profit',
                  value: CurrencyFormatter.formatCents(
                    row.projectedProfitCents,
                  ),
                ),
                _LabeledValue(
                  label: 'Sold Children',
                  value: row.realizedInventoryCount.toString(),
                ),
                _LabeledValue(
                  label: 'Open Children',
                  value: row.openInventoryCount.toString(),
                ),
                _LabeledValue(
                  label: 'Nested Deals',
                  value: row.descendantDealCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ResponsiveMetricGrid extends StatelessWidget {
  const _ResponsiveMetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 700
            ? 3
            : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

String _monthLabel(DateTime month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${names[month.month - 1]} ${month.year}';
}
