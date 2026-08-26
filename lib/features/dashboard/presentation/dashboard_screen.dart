import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../../shared/presentation/widgets/app_surface_card.dart';
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
      showHeader: false,
      compact: true,
      child: metricsAsync.when(
        loading: () => const AppLoadingState(message: 'Loading dashboard...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load dashboard.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(dashboardMetricsProvider);
          },
        ),
        data: (metrics) => _DashboardContent(
          metrics: metrics,
          canViewFinancialData: permissions.canViewFinancialData,
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
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
        Row(
          children: [
            Expanded(
              child: Text(
                'OVERVIEW',
                key: const Key('dashboardOverviewHeading'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            IconButton.filledTonal(
              key: const Key('dashboardScanQrButton'),
              tooltip: 'Scan QR code',
              onPressed: () {
                context.goNamed(AppRouteNames.inventoryScanner);
              },
              icon: const Icon(Icons.qr_code_scanner),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OverviewGrid(
          children: [
            _OverviewMetricCard(
              key: const Key('dashboardInventoryCountCard'),
              icon: Icons.inventory_2_outlined,
              iconColor: AppTheme.navy,
              label: 'TOTAL INVENTORY',
              value: metrics.inventoryCount.toString(),
              supportingText: 'Items',
            ),
            if (canViewFinancialData)
              _OverviewMetricCard(
                key: const Key('dashboardInventoryCostCard'),
                icon: Icons.attach_money,
                iconColor: AppTheme.primaryRed,
                label: 'MONEY INVESTED',
                value: CurrencyFormatter.formatCents(
                  metrics.openInventoryCostCents,
                ),
                supportingText: 'Total Cost',
              ),
            _OverviewMetricCard(
              key: const Key('dashboardInventoryValueCard'),
              icon: Icons.trending_up,
              iconColor: AppTheme.success,
              label: 'INVENTORY VALUE',
              value: CurrencyFormatter.formatCents(
                metrics.openInventoryValueCents,
              ),
            ),
            if (canViewFinancialData)
              _OverviewMetricCard(
                key: const Key('dashboardPotentialProfitCard'),
                icon: Icons.emoji_events_outlined,
                iconColor: AppTheme.navy,
                valueColor: AppTheme.success,
                label: 'POTENTIAL PROFIT',
                value: CurrencyFormatter.formatCents(
                  metrics.openPotentialProfitCents,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppSurfaceCard(
          key: const Key('dashboardQuickStatsPanel'),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'QUICK STATS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                key: const Key('dashboardQuickStatsRow'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuickStat(
                      key: const Key('dashboardAvailableItemsCard'),
                      icon: Icons.sell_outlined,
                      iconColor: AppTheme.navy,
                      value: metrics.availableItems.toString(),
                      label: 'Available',
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _QuickStat(
                      key: const Key('dashboardUnitsSoldCard'),
                      icon: Icons.shopping_cart_outlined,
                      iconColor: AppTheme.primaryRed,
                      valueColor: AppTheme.primaryRed,
                      value: metrics.unitsSold.toString(),
                      label: _soldLabel(metrics.dateRangeLabel),
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _QuickStat(
                      key: const Key('dashboardBrokenItemsCard'),
                      icon: Icons.build,
                      iconColor: AppTheme.success,
                      valueColor: AppTheme.success,
                      value: metrics.brokenItems.toString(),
                      label: 'Needs Repair',
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _QuickStat(
                      key: const Key('dashboardAverageDaysCard'),
                      icon: Icons.schedule,
                      iconColor: AppTheme.navy,
                      value: metrics.averageDaysInInventory.toString(),
                      label: 'Avg. Days in Inventory',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _DashboardAction(
          key: const Key('dashboardAddInventoryButton'),
          backgroundColor: AppTheme.primaryRed,
          icon: Icons.add_circle_outline,
          label: 'ADD INVENTORY',
          onPressed: () {
            context.goNamed(AppRouteNames.buyInventory);
          },
        ),
      ],
    );
  }

  static String _soldLabel(String dateRangeLabel) {
    final normalized = dateRangeLabel.trim().toLowerCase();

    if (normalized == 'today') {
      return 'Sold Today';
    }
    if (normalized == 'month to date') {
      return 'Sold MTD';
    }
    return 'Items Sold';
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        const spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

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

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.supportingText,
    this.valueColor,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final String label;
  final String value;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: AppSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricIcon(icon: icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: valueColor ?? AppTheme.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  if (supportingText != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      supportingText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: iconColor, size: 25),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: valueColor ?? AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 96, child: VerticalDivider(width: 12));
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final Color backgroundColor;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              SizedBox(
                width: 82,
                child: Icon(icon, color: Colors.white, size: 34),
              ),
              const SizedBox(
                height: 46,
                child: VerticalDivider(color: Color(0x66FFFFFF), width: 1),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 32),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
