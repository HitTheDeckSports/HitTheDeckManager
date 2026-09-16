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
                  title: 'Sales Trend',
                  subtitle: 'Revenue, profit and unit trends over time',
                  accent: const Color(0xFF12853D),
                  onTap: () => _openReport(
                    context,
                    title: 'Sales Trend',
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
    final includedSaleIds = report.saleIds.toSet();
    final scopedSales = report.unitsSold == 0
        ? <dynamic>[]
        : includedSaleIds.isEmpty
        ? widget.snapshot.sales
        : widget.snapshot.sales
              .where(
                (sale) => sale.id != null && includedSaleIds.contains(sale.id),
              )
              .toList(growable: false);
    final rawPoints = _salesTrendPoints(scopedSales, _grouping);
    final points =
        rawPoints.isEmpty &&
            _grouping == _TrendGrouping.month &&
            report.monthlyTrend.isNotEmpty
        ? report.monthlyTrend
              .map(
                (point) => _TrendPoint(
                  period: point.month,
                  units: point.unitsSold,
                  revenueCents: point.revenueCents,
                  profitCents: point.profitCents,
                ),
              )
              .toList(growable: false)
        : rawPoints;
    final averageSale = report.unitsSold == 0
        ? 0
        : (report.revenueCents / report.unitsSold).round();
    final averageProfit = report.unitsSold == 0
        ? 0
        : (report.profitCents / report.unitsSold).round();
    final bestRevenue = _bestTrend(points, (point) => point.revenueCents);
    final bestProfit = _bestTrend(points, (point) => point.profitCents);

    return Column(
      key: const Key('financialPerformanceSection'),
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
            DropdownMenuItem(value: _TrendGrouping.month, child: Text('Month')),
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
        const SizedBox(height: 18),
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF082A4A),
          ),
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
        const SizedBox(height: 18),
        Text(
          'Performance by Period',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF082A4A),
          ),
        ),
        const SizedBox(height: 8),
        for (final point in points)
          _SalesTrendRow(point: point, grouping: _grouping),
      ],
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
    final visible = points.length > 7
        ? points.sublist(points.length - 7)
        : points;

    return Card(
      key: const Key('salesTrendChart'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label:
                  'Sales Trend chart showing Revenue, Profit, and Units Sold',
              child: SizedBox(
                height: 235,
                child: CustomPaint(
                  key: const Key('salesTrendThreeSeriesChart'),
                  painter: _SalesTrendPainter(
                    points: visible,
                    grouping: grouping,
                    revenueColor: const Color(0xFF12853D),
                    profitColor: const Color(0xFF125FB8),
                    unitsColor: const Color(0xFFE07B18),
                    textColor: const Color(0xFF657080),
                    gridColor: const Color(0xFFD9E0E8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                _TrendLegendItem(label: 'Revenue', color: Color(0xFF12853D)),
                _TrendLegendItem(label: 'Profit', color: Color(0xFF125FB8)),
                _TrendLegendItem(label: 'Units Sold', color: Color(0xFFE07B18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendLegendItem extends StatelessWidget {
  const _TrendLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF657080),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SalesTrendPainter extends CustomPainter {
  const _SalesTrendPainter({
    required this.points,
    required this.grouping,
    required this.revenueColor,
    required this.profitColor,
    required this.unitsColor,
    required this.textColor,
    required this.gridColor,
  });

  final List<_TrendPoint> points;
  final _TrendGrouping grouping;
  final Color revenueColor;
  final Color profitColor;
  final Color unitsColor;
  final Color textColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const left = 52.0;
    const right = 38.0;
    const top = 10.0;
    const bottom = 36.0;
    final plotWidth = size.width - left - right;
    final plotHeight = size.height - top - bottom;

    var minMoney = 0;
    var maxMoney = 1;
    var maxUnits = 1;
    for (final point in points) {
      if (point.revenueCents > maxMoney) {
        maxMoney = point.revenueCents;
      }
      if (point.profitCents > maxMoney) {
        maxMoney = point.profitCents;
      }
      if (point.profitCents < minMoney) {
        minMoney = point.profitCents;
      }
      if (point.units > maxUnits) {
        maxUnits = point.units;
      }
    }
    if (maxMoney == minMoney) {
      maxMoney = minMoney + 1;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    canvas.drawLine(
      const Offset(left, top),
      Offset(left, top + plotHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(left, top + plotHeight),
      Offset(left + plotWidth, top + plotHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(left + plotWidth, top),
      Offset(left + plotWidth, top + plotHeight),
      axisPaint,
    );

    for (var i = 0; i <= 4; i++) {
      final ratio = i / 4;
      final y = top + plotHeight * (1 - ratio);
      canvas.drawLine(Offset(left, y), Offset(left + plotWidth, y), gridPaint);

      final money = minMoney + ((maxMoney - minMoney) * ratio).round();
      final units = (maxUnits * ratio).round();
      _paintChartText(
        canvas,
        _compactAxisMoney(money),
        Offset(0, y - 7),
        width: left - 5,
        align: TextAlign.right,
        color: textColor,
      );
      _paintChartText(
        canvas,
        units.toString(),
        Offset(left + plotWidth + 5, y - 7),
        width: right - 5,
        align: TextAlign.left,
        color: textColor,
      );
    }

    double moneyY(int cents) {
      final ratio = (cents - minMoney) / (maxMoney - minMoney);
      return top + plotHeight * (1 - ratio);
    }

    double unitsY(int units) {
      final ratio = units / maxUnits;
      return top + plotHeight * (1 - ratio);
    }

    double pointX(int index) {
      if (points.length == 1) {
        return left + plotWidth / 2;
      }
      return left + (plotWidth * index / (points.length - 1));
    }

    void drawSeries(Color color, double Function(_TrendPoint point) yForPoint) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final x = pointX(i);
        final y = yForPoint(points[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);

      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(Offset(pointX(i), yForPoint(points[i])), 4, dotPaint);
      }
    }

    drawSeries(revenueColor, (point) => moneyY(point.revenueCents));
    drawSeries(profitColor, (point) => moneyY(point.profitCents));
    drawSeries(unitsColor, (point) => unitsY(point.units));

    for (var i = 0; i < points.length; i++) {
      final x = pointX(i);
      final label = _trendShortLabel(points[i].period, grouping);
      _paintChartText(
        canvas,
        label,
        Offset(x - 30, top + plotHeight + 8),
        width: 60,
        align: TextAlign.center,
        color: textColor,
      );
    }

    _paintChartText(
      canvas,
      r'$',
      const Offset(2, 0),
      width: 20,
      align: TextAlign.left,
      color: textColor,
      bold: true,
    );
    _paintChartText(
      canvas,
      'Units',
      Offset(size.width - right + 3, 0),
      width: right - 3,
      align: TextAlign.left,
      color: textColor,
      bold: true,
    );
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.grouping != grouping;
  }
}

void _paintChartText(
  Canvas canvas,
  String text,
  Offset offset, {
  required double width,
  required TextAlign align,
  required Color color,
  bool bold = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 1,
  )..layout(maxWidth: width);
  painter.paint(canvas, offset);
}

String _compactAxisMoney(int cents) {
  final dollars = cents / 100;
  if (dollars.abs() >= 1000) {
    final value = dollars / 1000;
    return '\$${value.toStringAsFixed(value.abs() >= 10 ? 0 : 1)}k';
  }
  return '\$${dollars.toStringAsFixed(0)}';
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _trendLabel(point.period, grouping),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF082A4A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InlineMetric(
                    label: 'Units',
                    value: point.units.toString(),
                    valueColor: const Color(0xFFE07B18),
                  ),
                ),
                Expanded(
                  child: _InlineMetric(
                    label: 'Revenue',
                    value: CurrencyFormatter.formatCents(point.revenueCents),
                    valueColor: const Color(0xFF12853D),
                  ),
                ),
                Expanded(
                  child: _InlineMetric(
                    label: 'Profit',
                    value: CurrencyFormatter.formatCents(point.profitCents),
                    valueColor: _profitColor(point.profitCents),
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

    return Column(
      key: const Key('salesAnalysisSection'),
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
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Text(
          row.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF082A4A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  label: 'Units',
                  value: row.units.toString(),
                ),
              ),
              Expanded(
                child: _InlineMetric(
                  label: 'Revenue',
                  value: CurrencyFormatter.formatCents(row.revenueCents),
                ),
              ),
              Expanded(
                child: _InlineMetric(
                  label: 'Profit',
                  value: CurrencyFormatter.formatCents(row.profitCents),
                  valueColor: _profitColor(row.profitCents),
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
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
    final inventoryNumber = _inventoryNumber(item, fallbackId);
    final displayName = _inventoryName(item);
    final salePrice = sale == null ? null : sale.salePriceCents as int;
    final profit = sale == null ? null : (sale.profitCents as int?) ?? 0;

    return Padding(
      key: Key('soldItem_$fallbackId'),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _InventoryThumbnail(item: item, size: 52),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inventoryNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF125FB8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF657080),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (salePrice != null && profit != null)
            SizedBox(
              width: 86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCents(salePrice),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF082A4A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _signedCurrency(profit),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _profitColor(profit),
                    ),
                  ),
                ],
              ),
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
    return Column(
      key: const Key('inventoryAgingSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in report.rows)
          _InventoryAgingRowWidget(
            row: row,
            inventoryById: inventoryById,
            asOf: asOf,
          ),
      ],
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
    final accent = _agingBucketColor(row.bucket);
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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: accent.withValues(alpha: 0.035),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 5)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            initiallyExpanded: row.bucket == InventoryAgingBucket.days0To30,
            iconColor: accent,
            collapsedIconColor: const Color(0xFF082A4A),
            title: Text(
              row.bucket.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF082A4A),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _InlineMetric(
                      label: 'Items',
                      value: row.itemCount.toString(),
                    ),
                  ),
                  Expanded(
                    child: _InlineMetric(
                      label: 'Cost',
                      value: CurrencyFormatter.formatCents(
                        row.inventoryCostCents,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _InlineMetric(
                      label: 'Asking',
                      value: CurrencyFormatter.formatCents(
                        row.askingValueCents,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _InlineMetric(
                      label: 'Potential',
                      value: CurrencyFormatter.formatCents(
                        row.potentialProfitCents,
                      ),
                      valueColor: _profitColor(row.potentialProfitCents),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(height: 1),
              if (ids.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No inventory items in this bucket.'),
                  ),
                )
              else
                for (final id in ids)
                  _AgingItemRow(
                    item: inventoryById[id],
                    fallbackId: id,
                    asOf: asOf,
                    accent: accent,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgingItemRow extends StatelessWidget {
  const _AgingItemRow({
    required this.item,
    required this.fallbackId,
    required this.asOf,
    required this.accent,
  });
  final dynamic item;
  final String fallbackId;
  final DateTime? asOf;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final inventoryNumber = _inventoryNumber(item, fallbackId);
    final displayName = _inventoryName(item);
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
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _InventoryThumbnail(item: item, size: 50),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inventoryNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF125FB8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF657080),
                  ),
                ),
              ],
            ),
          ),
          if (days != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$days days',
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ],
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
    return Column(
      key: const Key('dealsSection'),
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
    return Column(
      key: const Key('dealsSection'),
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
    final item = row.parentInventoryItem;
    final openPathCount = summary.branches
        .where((branch) => branch.openInventoryCount > 0)
        .length;

    return Card(
      key: Key('recursiveDealCard_$displayId'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: Key('recursiveDealExpansion_$displayId'),
        tilePadding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InventoryThumbnail(item: item, size: 60),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _inventoryNumber(item, row.parentSale.inventoryItemId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF125FB8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _inventoryName(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF082A4A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Original Sale',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _DealStatusPill(status: summary.status),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _InlineMetric(
                        label: 'Current Profit',
                        value: CurrencyFormatter.formatCents(
                          summary.realizedDealProfitCents,
                        ),
                        valueColor: _profitColor(
                          summary.realizedDealProfitCents,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _InlineMetric(
                        label: 'Projected Profit',
                        value: CurrencyFormatter.formatCents(
                          summary.projectedDealProfitCents,
                        ),
                        valueColor: _profitColor(
                          summary.projectedDealProfitCents,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _openPathLabel(openPathCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF657080),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
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
    final branchNodes = row.tree.branchFor(branch.rootChildInventoryItemId);
    final active = branch.openInventoryCount > 0;

    return Card(
      key: Key('recursiveDealBranch_${branch.rootChildInventoryItemId}'),
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFFBFCFE),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        title: Row(
          children: [
            _InventoryThumbnail(item: rootItem, size: 46),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trade-In $pathNumber',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    _inventoryNumber(rootItem, branch.rootChildInventoryItemId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF125FB8),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _inventoryName(rootItem),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  label: 'Current',
                  value: CurrencyFormatter.formatCents(
                    branch.realizedProfitCents,
                  ),
                  valueColor: _profitColor(branch.realizedProfitCents),
                ),
              ),
              Expanded(
                child: _InlineMetric(
                  label: 'Projected',
                  value: CurrencyFormatter.formatCents(
                    branch.projectedBranchProfitCents,
                  ),
                  valueColor: _profitColor(branch.projectedBranchProfitCents),
                ),
              ),
              _SmallStatusTag(
                label: active ? 'Active' : 'Completed',
                color: active
                    ? const Color(0xFF125FB8)
                    : const Color(0xFF12853D),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          for (var i = 0; i < branchNodes.length; i++)
            _DealPathItemRow(
              item: row.inventoryItemFor(branchNodes[i].inventoryItemId),
              fallbackId: branchNodes[i].inventoryItemId,
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
    required this.item,
    required this.fallbackId,
    required this.relationship,
    required this.isRoot,
    required this.isCurrent,
  });
  final dynamic item;
  final String fallbackId;
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _InventoryThumbnail(item: item, size: 42),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _inventoryNumber(item, fallbackId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF125FB8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _inventoryName(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  eventLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          if (isCurrent)
            const _SmallStatusTag(label: 'Current', color: Color(0xFFE07B18)),
        ],
      ),
    );
  }
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
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayId,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _DealStatusPill(status: row.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InlineMetric(
                    label: 'Current Profit',
                    value: CurrencyFormatter.formatCents(
                      row.realizedProfitCents,
                    ),
                    valueColor: _profitColor(row.realizedProfitCents),
                  ),
                ),
                Expanded(
                  child: _InlineMetric(
                    label: 'Projected Profit',
                    value: CurrencyFormatter.formatCents(
                      row.projectedProfitCents,
                    ),
                    valueColor: _profitColor(row.projectedProfitCents),
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

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF657080),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? const Color(0xFF082A4A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryThumbnail extends StatelessWidget {
  const _InventoryThumbnail({required this.item, this.size = 48});
  final dynamic item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final List<String> photoUrls = item == null
        ? const <String>[]
        : (item.photoUrls as List<String>);
    final photoUrl = photoUrls.isEmpty ? null : photoUrls.first;

    Widget fallback() => Container(
      color: const Color(0xFFEAF0F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.42,
        color: const Color(0xFF657080),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl == null || photoUrl.trim().isEmpty
            ? fallback()
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback(),
              ),
      ),
    );
  }
}

class _DealStatusPill extends StatelessWidget {
  const _DealStatusPill({required this.status});
  final DealStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _dealStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        _dealFilterLabel(status),
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallStatusTag extends StatelessWidget {
  const _SmallStatusTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _profitColor(int cents) {
  if (cents > 0) {
    return const Color(0xFF12853D);
  }
  if (cents < 0) {
    return const Color(0xFFD6242F);
  }
  return const Color(0xFF657080);
}

String _signedCurrency(int cents) {
  final formatted = CurrencyFormatter.formatCents(cents.abs());
  if (cents > 0) {
    return '+$formatted';
  }
  if (cents < 0) {
    return '-$formatted';
  }
  return formatted;
}

Color _agingBucketColor(InventoryAgingBucket bucket) {
  return switch (bucket) {
    InventoryAgingBucket.days0To30 => const Color(0xFF12853D),
    InventoryAgingBucket.days31To60 => const Color(0xFFC48A00),
    InventoryAgingBucket.days61To90 => const Color(0xFFE07B18),
    InventoryAgingBucket.days91To180 => const Color(0xFFD9561F),
    InventoryAgingBucket.days181Plus => const Color(0xFFD6242F),
  };
}

Color _dealStatusColor(DealStatus status) {
  return switch (status) {
    DealStatus.open => const Color(0xFF125FB8),
    DealStatus.partiallyRealized => const Color(0xFFE07B18),
    DealStatus.completed => const Color(0xFF12853D),
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

String _inventoryNumber(dynamic item, String fallbackId) {
  final value = item?.inventoryNumber as String?;
  if (value == null || value.trim().isEmpty) {
    return fallbackId;
  }
  return value.trim();
}

String _inventoryName(dynamic item) {
  if (item == null) {
    return 'Unknown item';
  }
  final brand = (item.brand as String).trim();
  final model = (item.model as String?)?.trim();
  final values = <String>[
    if (brand.isNotEmpty) brand,
    if (model != null && model.isNotEmpty) model,
  ];
  return values.isEmpty ? 'Unknown item' : values.join(' ');
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
