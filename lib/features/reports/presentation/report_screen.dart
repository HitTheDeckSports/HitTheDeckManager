import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/currency_formatter.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../transactions/domain/models/deal_branch_summary.dart';
import '../../transactions/domain/models/deal_lineage_edge_type.dart';
import '../../transactions/domain/models/deal_status.dart';
import '../application/deal_rollup_report.dart';
import '../application/recursive_deal_report.dart';
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
      showHeader: false,
      compact: true,
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
    return Card(
      key: const Key('reportDateRangeCompactLayout'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<ReportDateRangePreset>(
                key: const Key('reportDateRangeSelector'),
                isExpanded: true,
                initialValue: selection.preset,
                decoration: const InputDecoration(
                  labelText: 'Report Period',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
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
                  if (preset == null) return;

                  final controller = ref.read(
                    reportDateRangeSelectionProvider.notifier,
                  );
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
                      end: current.endExclusive.subtract(
                        const Duration(days: 1),
                      ),
                    ),
                    helpText: 'Select report date range',
                  );

                  if (selectedRange == null) return;
                  controller.selectCustom(
                    startDate: selectedRange.start,
                    endDate: selectedRange.end,
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
        _ReportsLandingSummary(snapshot: snapshot),
        const SizedBox(height: 14),
        _QuickReportsGrid(snapshot: snapshot),
      ],
    );
  }
}

class _ReportsLandingSummary extends StatelessWidget {
  const _ReportsLandingSummary({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final report = snapshot.financialPerformance;

    return Column(
      key: const Key('reportsLandingSummary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Performance Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF082A4A),
                ),
              ),
            ),
            Text(
              report.rangeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF657080),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final width = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _CompactSummaryCard(
                  key: const Key('reportsRevenueCard'),
                  width: width,
                  label: 'Revenue',
                  value: CurrencyFormatter.formatCents(report.revenueCents),
                  icon: Icons.attach_money,
                  accent: const Color(0xFF12853D),
                ),
                _CompactSummaryCard(
                  key: const Key('reportsCostCard'),
                  width: width,
                  label: 'Cost',
                  value: CurrencyFormatter.formatCents(report.costCents),
                  icon: Icons.payments_outlined,
                  accent: const Color(0xFFD6242F),
                ),
                _CompactSummaryCard(
                  key: const Key('reportsProfitCard'),
                  width: width,
                  label: 'Profit',
                  value: CurrencyFormatter.formatCents(report.profitCents),
                  icon: Icons.trending_up,
                  accent: const Color(0xFF125FB8),
                ),
                _CompactSummaryCard(
                  key: const Key('reportsMarginCard'),
                  width: width,
                  label: 'Gross Margin',
                  value: '${(report.grossMargin * 100).toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  accent: const Color(0xFF6F42C1),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Card(
          key: const Key('reportsUnitsSoldCard'),
          margin: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 82),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07B18).withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 18,
                      color: Color(0xFFE07B18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Units Sold',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF657080),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    report.unitsSold.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF082A4A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    super.key,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF657080),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF082A4A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReportsGrid extends StatelessWidget {
  const _QuickReportsGrid({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('quickReportsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Reports',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF082A4A),
          ),
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final width = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _QuickReportCard(
                  key: const Key('quickReportSalesOverview'),
                  width: width,
                  icon: Icons.show_chart,
                  title: 'Sales Overview',
                  subtitle: 'Revenue, profit, margin and monthly trends',
                  accent: const Color(0xFF12853D),
                  onTap: () => _openReport(
                    context,
                    title: 'Sales Overview',
                    child: _SalesOverviewSection(snapshot: snapshot),
                  ),
                ),
                _QuickReportCard(
                  key: const Key('quickReportItemsSold'),
                  width: width,
                  icon: Icons.shopping_cart_outlined,
                  title: 'Items Sold',
                  subtitle: 'Sales by category, brand and model',
                  accent: const Color(0xFF125FB8),
                  onTap: () => _openReport(
                    context,
                    title: 'Items Sold',
                    child: _SalesAnalysisSection(snapshot: snapshot),
                  ),
                ),
                _QuickReportCard(
                  key: const Key('quickReportAgingInventory'),
                  width: width,
                  icon: Icons.schedule,
                  title: 'Aging Inventory',
                  subtitle: 'Open inventory grouped by age',
                  accent: const Color(0xFFE07B18),
                  onTap: () => _openReport(
                    context,
                    title: 'Aging Inventory',
                    child: _InventoryAgingSection(
                      report: snapshot.inventoryAging,
                      inventoryItems: snapshot.inventoryItems,
                      asOf: snapshot.asOf,
                    ),
                  ),
                ),
                _QuickReportCard(
                  key: const Key('quickReportDeals'),
                  width: width,
                  icon: Icons.handshake_outlined,
                  title: 'Deals',
                  subtitle: 'Open and completed Deal economics',
                  accent: const Color(0xFF6F42C1),
                  onTap: () => _openReport(
                    context,
                    title: 'Deals',
                    child: _DealsSection(
                      report: snapshot.deals,
                      recursiveReport: snapshot.recursiveDeals,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openReport(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF6F8FB),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.90,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (context, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        key: const Key('closeQuickReportButton'),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _QuickReportCard extends StatelessWidget {
  const _QuickReportCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    super.key,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 94),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accent, size: 18),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF082A4A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF657080),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesOverviewSection extends StatefulWidget {
  const _SalesOverviewSection({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  State<_SalesOverviewSection> createState() => _SalesOverviewSectionState();
}

class _SalesOverviewSectionState extends State<_SalesOverviewSection> {
  _TrendGrouping _grouping = _TrendGrouping.month;

  @override
  Widget build(BuildContext context) {
    final report = widget.snapshot.financialPerformance;
    final points = _salesTrendPoints(widget.snapshot.sales, _grouping);
    final averageSale = report.unitsSold == 0
        ? 0
        : (report.revenueCents / report.unitsSold).round();
    final averageProfit = report.unitsSold == 0
        ? 0
        : (report.profitCents / report.unitsSold).round();
    final bestRevenue = _bestTrend(points, (point) => point.revenueCents);
    final bestProfit = _bestTrend(points, (point) => point.profitCents);

    return _ReportSection(
      key: const Key('financialPerformanceSection'),
      title: 'Sales Trend',
      subtitle: 'Revenue, profit, and units sold over time.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<_TrendGrouping>(
            key: const Key('salesOverviewGroupBy'),
            initialValue: _grouping,
            decoration: const InputDecoration(
              labelText: 'Group By',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: _TrendGrouping.day, child: Text('Day')),
              DropdownMenuItem(value: _TrendGrouping.week, child: Text('Week')),
              DropdownMenuItem(
                value: _TrendGrouping.month,
                child: Text('Month'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _grouping = value);
              }
            },
          ),
          const SizedBox(height: 14),
          if (points.isEmpty)
            const _EmptyReportState(message: 'No sales in this period.')
          else
            _SalesTrendChart(points: points, grouping: _grouping),
          const SizedBox(height: 16),
          Text(
            'Key Metrics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _ResponsiveMetricGrid(
            children: [
              _ReportMetricCard(
                label: 'Average Sale Price',
                value: CurrencyFormatter.formatCents(averageSale),
              ),
              _ReportMetricCard(
                label: 'Average Profit per Item',
                value: CurrencyFormatter.formatCents(averageProfit),
              ),
              _ReportMetricCard(
                label: 'Best Revenue Period',
                value: bestRevenue == null
                    ? '—'
                    : '${_trendLabel(bestRevenue.period, _grouping)}\n${CurrencyFormatter.formatCents(bestRevenue.revenueCents)}',
              ),
              _ReportMetricCard(
                label: 'Best Profit Period',
                value: bestProfit == null
                    ? '—'
                    : '${_trendLabel(bestProfit.period, _grouping)}\n${CurrencyFormatter.formatCents(bestProfit.profitCents)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Performance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final point in points)
            _SalesTrendRow(point: point, grouping: _grouping),
        ],
      ),
    );
  }
}

enum _TrendGrouping { day, week, month }

class _TrendPoint {
  const _TrendPoint({
    required this.period,
    required this.units,
    required this.revenueCents,
    required this.profitCents,
  });
  final DateTime period;
  final int units;
  final int revenueCents;
  final int profitCents;
}

List<_TrendPoint> _salesTrendPoints(
  List<dynamic> rawSales,
  _TrendGrouping grouping,
) {
  final groups = <DateTime, List<dynamic>>{};
  for (final sale in rawSales) {
    final DateTime date = sale.saleDate as DateTime;
    final DateTime key = switch (grouping) {
      _TrendGrouping.day => DateTime(date.year, date.month, date.day),
      _TrendGrouping.week => DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - DateTime.monday)),
      _TrendGrouping.month => DateTime(date.year, date.month),
    };
    groups.putIfAbsent(key, () => <dynamic>[]).add(sale);
  }
  final points = <_TrendPoint>[];
  for (final entry in groups.entries) {
    var revenue = 0;
    var profit = 0;
    for (final sale in entry.value) {
      revenue += sale.salePriceCents as int;
      profit += (sale.profitCents as int?) ?? 0;
    }
    points.add(
      _TrendPoint(
        period: entry.key,
        units: entry.value.length,
        revenueCents: revenue,
        profitCents: profit,
      ),
    );
  }
  points.sort((a, b) => a.period.compareTo(b.period));
  return points;
}

_TrendPoint? _bestTrend(
  List<_TrendPoint> points,
  int Function(_TrendPoint) value,
) {
  if (points.isEmpty) {
    return null;
  }
  var best = points.first;
  for (final point in points.skip(1)) {
    if (value(point) > value(best)) {
      best = point;
    }
  }
  return best;
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.points, required this.grouping});
  final List<_TrendPoint> points;
  final _TrendGrouping grouping;

  @override
  Widget build(BuildContext context) {
    final visible = points.length > 8
        ? points.sublist(points.length - 8)
        : points;
    var maxRevenue = 1;
    for (final point in visible) {
      if (point.revenueCents > maxRevenue) {
        maxRevenue = point.revenueCents;
      }
    }
    return Card(
      key: const Key('salesTrendChart'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in visible)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text(
                          point.units.toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 3),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: (point.revenueCents / maxRevenue)
                                  .clamp(0.05, 1.0),
                              widthFactor: 0.58,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF125FB8),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _trendShortLabel(point.period, grouping),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesTrendRow extends StatelessWidget {
  const _SalesTrendRow({required this.point, required this.grouping});
  final _TrendPoint point;
  final _TrendGrouping grouping;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _trendLabel(point.period, grouping),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _LabeledValue(label: 'Units', value: point.units.toString()),
                _LabeledValue(
                  label: 'Revenue',
                  value: CurrencyFormatter.formatCents(point.revenueCents),
                ),
                _LabeledValue(
                  label: 'Profit',
                  value: CurrencyFormatter.formatCents(point.profitCents),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesAnalysisSection extends StatefulWidget {
  const _SalesAnalysisSection({required this.snapshot});
  final ReportsSnapshot snapshot;
  @override
  State<_SalesAnalysisSection> createState() => _SalesAnalysisSectionState();
}

class _SalesAnalysisSectionState extends State<_SalesAnalysisSection> {
  SalesAnalysisDimension _dimension = SalesAnalysisDimension.category;

  SalesAnalysisReport get _report => switch (_dimension) {
    SalesAnalysisDimension.category => widget.snapshot.salesByCategory,
    SalesAnalysisDimension.brand => widget.snapshot.salesByBrand,
    SalesAnalysisDimension.model => widget.snapshot.salesByModel,
  };

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final inventoryById = {
      for (final item in widget.snapshot.inventoryItems)
        if (item.id != null) item.id!: item,
    };
    final salesByItem = {
      for (final sale in widget.snapshot.sales) sale.inventoryItemId: sale,
    };
    return _ReportSection(
      key: const Key('salesAnalysisSection'),
      title: 'Items Sold Analysis',
      subtitle:
          'Units, revenue, and profit grouped by category, brand, or model.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<SalesAnalysisDimension>(
            key: const Key('itemsSoldGroupBy'),
            initialValue: _dimension,
            decoration: const InputDecoration(
              labelText: 'Group By',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: SalesAnalysisDimension.category,
                child: Text('Category'),
              ),
              DropdownMenuItem(
                value: SalesAnalysisDimension.brand,
                child: Text('Brand'),
              ),
              DropdownMenuItem(
                value: SalesAnalysisDimension.model,
                child: Text('Model'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _dimension = value);
              }
            },
          ),
          const SizedBox(height: 12),
          if (report.rows.isEmpty)
            const _EmptyReportState(message: 'No sales in this period.')
          else
            for (final row in report.rows)
              _ExpandableSalesGroupRow(
                row: row,
                inventoryById: inventoryById,
                salesByItem: salesByItem,
              ),
        ],
      ),
    );
  }
}

class _ExpandableSalesGroupRow extends StatelessWidget {
  const _ExpandableSalesGroupRow({
    required this.row,
    required this.inventoryById,
    required this.salesByItem,
  });
  final SalesAnalysisRow row;
  final Map<String, dynamic> inventoryById;
  final Map<String, dynamic> salesByItem;
  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('itemsSoldGroup_${row.label}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Text(
          row.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF082A4A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 18,
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
          ),
        ),
        children: [
          for (final id in row.inventoryItemIds)
            _SoldInventoryItemRow(
              item: inventoryById[id],
              sale: salesByItem[id],
              fallbackId: id,
            ),
        ],
      ),
    );
  }
}

class _SoldInventoryItemRow extends StatelessWidget {
  const _SoldInventoryItemRow({
    required this.item,
    required this.sale,
    required this.fallbackId,
  });
  final dynamic item;
  final dynamic sale;
  final String fallbackId;
  @override
  Widget build(BuildContext context) {
    final inventoryNumber = item?.inventoryNumber ?? fallbackId;
    final brand = (item?.brand as String?)?.trim();
    final model = (item?.model as String?)?.trim();
    final displayName = [
      if (brand != null && brand.isNotEmpty) brand,
      if (model != null && model.isNotEmpty) model,
    ].join(' ');
    return Padding(
      key: Key('soldItem_$fallbackId'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inventoryNumber,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF125FB8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(displayName.isEmpty ? 'Unknown item' : displayName),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (sale != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.formatCents(sale.salePriceCents as int)),
                Text(
                  '${CurrencyFormatter.formatCents((sale.profitCents as int?) ?? 0)} profit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InventoryAgingSection extends StatelessWidget {
  const _InventoryAgingSection({
    required this.report,
    this.inventoryItems = const [],
    this.asOf,
  });
  final InventoryAgingReport report;
  final List<dynamic> inventoryItems;
  final DateTime? asOf;
  @override
  Widget build(BuildContext context) {
    final inventoryById = {
      for (final item in inventoryItems)
        if (item.id != null) item.id as String: item,
    };
    return _ReportSection(
      key: const Key('inventoryAgingSection'),
      title: 'Inventory Aging',
      subtitle: 'Current open inventory grouped by days in inventory.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in report.rows)
            _InventoryAgingRowWidget(
              row: row,
              inventoryById: inventoryById,
              asOf: asOf,
            ),
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
  const _InventoryAgingRowWidget({
    required this.row,
    required this.inventoryById,
    required this.asOf,
  });
  final InventoryAgingRow row;
  final Map<String, dynamic> inventoryById;
  final DateTime? asOf;
  @override
  Widget build(BuildContext context) {
    final ids = [...row.inventoryItemIds]
      ..sort((a, b) {
        final aDate = inventoryById[a]?.purchaseDate as DateTime?;
        final bDate = inventoryById[b]?.purchaseDate as DateTime?;
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });
    return Card(
      key: Key('agingBucket_${row.bucket.name}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        initiallyExpanded: row.bucket == InventoryAgingBucket.days0To30,
        title: Text(
          row.bucket.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF082A4A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LabeledValue(label: 'Items', value: row.itemCount.toString()),
              _LabeledValue(
                label: 'Cost',
                value: CurrencyFormatter.formatCents(row.inventoryCostCents),
              ),
              _LabeledValue(
                label: 'Asking',
                value: CurrencyFormatter.formatCents(row.askingValueCents),
              ),
              _LabeledValue(
                label: 'Potential Profit',
                value: CurrencyFormatter.formatCents(row.potentialProfitCents),
              ),
            ],
          ),
        ),
        children: [
          if (ids.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No inventory items in this bucket.'),
            )
          else
            for (final id in ids)
              _AgingItemRow(
                item: inventoryById[id],
                fallbackId: id,
                asOf: asOf,
              ),
        ],
      ),
    );
  }
}

class _AgingItemRow extends StatelessWidget {
  const _AgingItemRow({
    required this.item,
    required this.fallbackId,
    required this.asOf,
  });
  final dynamic item;
  final String fallbackId;
  final DateTime? asOf;
  @override
  Widget build(BuildContext context) {
    final inventoryNumber = item?.inventoryNumber ?? fallbackId;
    final brand = (item?.brand as String?)?.trim();
    final model = (item?.model as String?)?.trim();
    final displayName = [
      if (brand != null && brand.isNotEmpty) brand,
      if (model != null && model.isNotEmpty) model,
    ].join(' ');
    final purchaseDate = item?.purchaseDate as DateTime?;
    final reference = asOf ?? DateTime.now();
    final days = purchaseDate == null
        ? null
        : DateTime(reference.year, reference.month, reference.day)
              .difference(
                DateTime(
                  purchaseDate.year,
                  purchaseDate.month,
                  purchaseDate.day,
                ),
              )
              .inDays
              .clamp(0, 999999);
    return Padding(
      key: Key('agingItem_$fallbackId'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inventoryNumber,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF125FB8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(displayName.isEmpty ? 'Unknown item' : displayName),
              ],
            ),
          ),
          if (days != null)
            Text('$days days', style: Theme.of(context).textTheme.bodySmall),
        ],
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
    return _LegacyDealsFilteredSection(report: report);
  }
}

class _LegacyDealsFilteredSection extends StatefulWidget {
  const _LegacyDealsFilteredSection({required this.report});
  final DealRollupReport report;
  @override
  State<_LegacyDealsFilteredSection> createState() =>
      _LegacyDealsFilteredSectionState();
}

class _LegacyDealsFilteredSectionState
    extends State<_LegacyDealsFilteredSection> {
  DealStatus _status = DealStatus.open;
  @override
  Widget build(BuildContext context) {
    final rows = widget.report.rows
        .where((row) => row.status == _status)
        .toList(growable: false);
    return _ReportSection(
      key: const Key('dealsSection'),
      title: 'Deals',
      subtitle: 'Filter Deals by lifecycle status.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DealStatusSelector(
            value: _status,
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            _EmptyReportState(message: 'No ${_dealFilterLabel(_status)} Deals.')
          else
            for (final row in rows) _DealReportCard(row: row),
        ],
      ),
    );
  }
}

class _RecursiveDealsSection extends StatefulWidget {
  const _RecursiveDealsSection({required this.report});
  final RecursiveDealReport report;
  @override
  State<_RecursiveDealsSection> createState() => _RecursiveDealsSectionState();
}

class _RecursiveDealsSectionState extends State<_RecursiveDealsSection> {
  DealStatus _status = DealStatus.open;
  @override
  Widget build(BuildContext context) {
    final rows = widget.report.rows
        .where((row) => row.summary.status == _status)
        .toList(growable: false);
    return _ReportSection(
      key: const Key('dealsSection'),
      title: 'Deals',
      subtitle:
          'Track the original sale and each trade-in path through the full Deal.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DealStatusSelector(
            value: _status,
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            _EmptyReportState(message: 'No ${_dealFilterLabel(_status)} Deals.')
          else
            for (final row in rows) _RecursiveDealCard(row: row),
        ],
      ),
    );
  }
}

class _DealStatusSelector extends StatelessWidget {
  const _DealStatusSelector({required this.value, required this.onChanged});
  final DealStatus value;
  final ValueChanged<DealStatus> onChanged;
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DealStatus>(
      key: const Key('dealStatusFilter'),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Deal Status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: DealStatus.open, child: Text('Active')),
        DropdownMenuItem(
          value: DealStatus.partiallyRealized,
          child: Text('Partially Realized'),
        ),
        DropdownMenuItem(value: DealStatus.completed, child: Text('Completed')),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
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
    final originalSaleLabel = _inventoryLabel(
      row.parentInventoryItem,
      row.parentSale.inventoryItemId,
    );
    final openPathCount = summary.branches
        .where((branch) => branch.openInventoryCount > 0)
        .length;

    return Card(
      key: Key('recursiveDealCard_$displayId'),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        key: Key('recursiveDealExpansion_$displayId'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              originalSaleLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text('Original Sale', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(label: Text(_dealStatusLabel(summary.status))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _LabeledValue(
                    label: 'Current Profit',
                    value: CurrencyFormatter.formatCents(
                      summary.realizedDealProfitCents,
                    ),
                  ),
                  _LabeledValue(
                    label: 'Projected Profit',
                    value: CurrencyFormatter.formatCents(
                      summary.projectedDealProfitCents,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _openPathLabel(openPathCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Original Sale',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          _BusinessEventCard(
            icon: Icons.receipt_long_outlined,
            title: originalSaleLabel,
            label: 'Original Sale Profit',
            value: CurrencyFormatter.formatCents(
              summary.parentTransactionProfitCents,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Trade-In Paths',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Each path starts with an item received in the original trade.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < summary.branches.length; i++)
            _RecursiveDealBranchCard(
              row: row,
              branch: summary.branches[i],
              pathNumber: i + 1,
            ),
        ],
      ),
    );
  }
}

class _RecursiveDealBranchCard extends StatelessWidget {
  const _RecursiveDealBranchCard({
    required this.row,
    required this.branch,
    required this.pathNumber,
  });

  final RecursiveDealReportRow row;
  final DealBranchSummary branch;
  final int pathNumber;

  @override
  Widget build(BuildContext context) {
    final rootItem = row.inventoryItemFor(branch.rootChildInventoryItemId);
    final rootLabel = _inventoryLabel(
      rootItem,
      branch.rootChildInventoryItemId,
    );
    final branchNodes = row.tree.branchFor(branch.rootChildInventoryItemId);
    final active = branch.openInventoryCount > 0;

    return Card(
      key: Key('recursiveDealBranch_${branch.rootChildInventoryItemId}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: Key(
          'recursiveDealBranchExpansion_${branch.rootChildInventoryItemId}',
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trade-In $pathNumber',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(rootLabel, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _LabeledValue(
                    label: 'Current Path Profit',
                    value: CurrencyFormatter.formatCents(
                      branch.realizedProfitCents,
                    ),
                  ),
                  _LabeledValue(
                    label: 'Projected Path Profit',
                    value: CurrencyFormatter.formatCents(
                      branch.projectedBranchProfitCents,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                active ? 'Still Active' : 'Completed',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        children: [
          for (var i = 0; i < branchNodes.length; i++)
            _DealPathItemRow(
              label: _inventoryLabel(
                row.inventoryItemFor(branchNodes[i].inventoryItemId),
                branchNodes[i].inventoryItemId,
              ),
              relationship: branchNodes[i].edgeTypeFromParent,
              isRoot: i == 0,
              isCurrent:
                  i == branchNodes.length - 1 && branch.openInventoryCount > 0,
            ),
        ],
      ),
    );
  }
}

class _DealPathItemRow extends StatelessWidget {
  const _DealPathItemRow({
    required this.label,
    required this.relationship,
    required this.isRoot,
    required this.isCurrent,
  });

  final String label;
  final DealLineageEdgeType? relationship;
  final bool isRoot;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final eventLabel = isRoot
        ? 'Received in Trade'
        : switch (relationship) {
            DealLineageEdgeType.trade => 'Received in Later Trade',
            DealLineageEdgeType.warrantyReplacement => 'Warranty Replacement',
            null => 'Continued Deal Item',
          };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRoot
                ? Icons.input_outlined
                : relationship == DealLineageEdgeType.warrantyReplacement
                ? Icons.verified_outlined
                : Icons.swap_horiz,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(label),
                if (isCurrent) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Current Item',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessEventCard extends StatelessWidget {
  const _BusinessEventCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                _LabeledValue(label: label, value: value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _dealStatusLabel(DealStatus status) {
  return switch (status) {
    DealStatus.open => 'Active',
    DealStatus.partiallyRealized => 'Partially Completed',
    DealStatus.completed => 'Completed',
  };
}

String _openPathLabel(int count) {
  if (count == 0) {
    return 'All Trade-In Paths Completed';
  }
  if (count == 1) {
    return '1 Trade-In Path Still Open';
  }
  return '$count Trade-In Paths Still Open';
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

String _dealFilterLabel(DealStatus status) {
  return switch (status) {
    DealStatus.open => 'Active',
    DealStatus.partiallyRealized => 'Partially Realized',
    DealStatus.completed => 'Completed',
  };
}

String _trendLabel(DateTime date, _TrendGrouping grouping) {
  return switch (grouping) {
    _TrendGrouping.day => '${date.month}/${date.day}/${date.year}',
    _TrendGrouping.week => 'Week of ${date.month}/${date.day}/${date.year}',
    _TrendGrouping.month => _monthLabel(date),
  };
}

String _trendShortLabel(DateTime date, _TrendGrouping grouping) {
  return switch (grouping) {
    _TrendGrouping.day => '${date.month}/${date.day}',
    _TrendGrouping.week => '${date.month}/${date.day}',
    _TrendGrouping.month => _monthShortLabel(date),
  };
}

String _monthShortLabel(DateTime month) {
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
  return names[month.month - 1];
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
