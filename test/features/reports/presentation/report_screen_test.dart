import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';
import 'package:hit_the_deck_manager/features/reports/application/deal_rollup_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/financial_performance_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/inventory_aging_report.dart';
import 'package:hit_the_deck_manager/features/reports/application/reports_snapshot.dart';
import 'package:hit_the_deck_manager/features/reports/application/sales_analysis_report.dart';
import 'package:hit_the_deck_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:hit_the_deck_manager/features/reports/presentation/report_screen.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/deal_status.dart';

final _financial = FinancialPerformanceReport(
  rangeLabel: 'Month to Date',
  revenueCents: 75000,
  costCents: 45000,
  profitCents: 30000,
  grossMargin: 0.40,
  unitsSold: 3,
  monthlyTrend: [
    FinancialTrendPoint(
      month: _august2026,
      revenueCents: 75000,
      costCents: 45000,
      profitCents: 30000,
      unitsSold: 3,
    ),
  ],
  saleIds: ['sale-1', 'sale-2', 'sale-3'],
);

const _salesByCategory = SalesAnalysisReport(
  dimension: SalesAnalysisDimension.category,
  rows: [
    SalesAnalysisRow(
      label: 'Bat',
      units: 3,
      revenueCents: 75000,
      profitCents: 30000,
      inventoryItemIds: ['item-1', 'item-2', 'item-3'],
    ),
  ],
);

const _salesByBrand = SalesAnalysisReport(
  dimension: SalesAnalysisDimension.brand,
  rows: [
    SalesAnalysisRow(
      label: 'Easton',
      units: 2,
      revenueCents: 50000,
      profitCents: 20000,
      inventoryItemIds: ['item-1', 'item-2'],
    ),
  ],
);

const _salesByModel = SalesAnalysisReport(
  dimension: SalesAnalysisDimension.model,
  rows: [
    SalesAnalysisRow(
      label: 'Hype Fire',
      units: 1,
      revenueCents: 30000,
      profitCents: 12000,
      inventoryItemIds: ['item-1'],
    ),
  ],
);

const _aging = InventoryAgingReport(
  rows: [
    InventoryAgingRow(
      bucket: InventoryAgingBucket.days0To30,
      itemCount: 2,
      inventoryCostCents: 30000,
      askingValueCents: 50000,
      potentialProfitCents: 20000,
      inventoryItemIds: ['open-1', 'open-2'],
    ),
    InventoryAgingRow(
      bucket: InventoryAgingBucket.days31To60,
      itemCount: 1,
      inventoryCostCents: 15000,
      askingValueCents: 25000,
      potentialProfitCents: 10000,
      inventoryItemIds: ['open-3'],
    ),
    InventoryAgingRow(
      bucket: InventoryAgingBucket.days61To90,
      itemCount: 0,
      inventoryCostCents: 0,
      askingValueCents: 0,
      potentialProfitCents: 0,
      inventoryItemIds: [],
    ),
    InventoryAgingRow(
      bucket: InventoryAgingBucket.days91To180,
      itemCount: 0,
      inventoryCostCents: 0,
      askingValueCents: 0,
      potentialProfitCents: 0,
      inventoryItemIds: [],
    ),
    InventoryAgingRow(
      bucket: InventoryAgingBucket.days181Plus,
      itemCount: 0,
      inventoryCostCents: 0,
      askingValueCents: 0,
      potentialProfitCents: 0,
      inventoryItemIds: [],
    ),
  ],
  unclassifiedItemIds: [],
);

const _openDeal = Deal(
  id: 'deal-open',
  parentSaleTransactionId: 'sale-parent-1',
  childInventoryItemIds: ['trade-1'],
);

const _completedDeal = Deal(
  id: 'deal-completed',
  parentSaleTransactionId: 'sale-parent-2',
  childInventoryItemIds: ['trade-2'],
);

const _deals = DealRollupReport(
  rows: [
    DealRollupReportRow(
      deal: _openDeal,
      status: DealStatus.open,
      realizedProfitCents: 10000,
      projectedProfitCents: 18000,
      realizedInventoryCount: 0,
      openInventoryCount: 1,
      descendantDealCount: 1,
      cycleDetected: false,
      depthLimitReached: false,
      inventoryItemIds: ['trade-1'],
      dealKeys: ['deal-open', 'deal-child'],
    ),
    DealRollupReportRow(
      deal: _completedDeal,
      status: DealStatus.completed,
      realizedProfitCents: 22000,
      projectedProfitCents: 22000,
      realizedInventoryCount: 1,
      openInventoryCount: 0,
      descendantDealCount: 0,
      cycleDetected: false,
      depthLimitReached: false,
      inventoryItemIds: ['trade-2'],
      dealKeys: ['deal-completed'],
    ),
  ],
);

final _snapshot = ReportsSnapshot(
  financialPerformance: _financial,
  salesByCategory: _salesByCategory,
  salesByBrand: _salesByBrand,
  salesByModel: _salesByModel,
  inventoryAging: _aging,
  deals: _deals,
);

final _august2026 = DateTime(2026, 8);

void main() {
  testWidgets('Reports displays all four approved report areas', (
    WidgetTester tester,
  ) async {
    await _pumpReports(tester);

    expect(
      find.byKey(const Key('financialPerformanceSection')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('salesAnalysisSection')), findsOneWidget);
    expect(find.byKey(const Key('inventoryAgingSection')), findsOneWidget);
    expect(find.byKey(const Key('dealsSection')), findsOneWidget);

    expect(find.text('Financial Performance'), findsOneWidget);
    expect(find.text('Sales Analysis'), findsOneWidget);
    expect(find.text('Inventory Aging'), findsOneWidget);
    expect(find.text('Deals'), findsOneWidget);
  });

  testWidgets('Reports displays financial performance and monthly trend', (
    WidgetTester tester,
  ) async {
    await _pumpReports(tester);

    expect(find.text(r'$750.00'), findsWidgets);
    expect(find.text(r'$450.00'), findsWidgets);
    expect(find.text(r'$300.00'), findsWidgets);
    expect(find.text('40.0%'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Monthly Trend'), findsOneWidget);
    expect(find.text('Aug 2026'), findsOneWidget);
  });

  testWidgets('Reports displays sales analysis dimensions', (
    WidgetTester tester,
  ) async {
    await _pumpReports(tester);

    expect(find.text('By Category'), findsOneWidget);
    expect(find.text('By Brand'), findsOneWidget);
    expect(find.text('By Model'), findsOneWidget);
    expect(find.text('Bat'), findsOneWidget);
    expect(find.text('Easton'), findsOneWidget);
    expect(find.text('Hype Fire'), findsOneWidget);
  });

  testWidgets('Reports displays inventory aging buckets and Deal sections', (
    WidgetTester tester,
  ) async {
    await _pumpReports(tester);

    expect(find.text('0-30 days'), findsOneWidget);
    expect(find.text('31-60 days'), findsOneWidget);
    expect(find.text('181+ days'), findsOneWidget);

    expect(find.text('Uncompleted Deals'), findsOneWidget);
    expect(find.text('Completed Deals'), findsOneWidget);
    expect(find.text('deal-open'), findsOneWidget);
    expect(find.text('deal-completed'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('Reports defaults date range to Month to Date', (
    WidgetTester tester,
  ) async {
    await _pumpReports(tester);

    expect(find.byKey(const Key('reportDateRangeSelector')), findsOneWidget);
    expect(find.text('Month to Date'), findsWidgets);
  });

  testWidgets('Reports date selector updates a preset visibly', (
    WidgetTester tester,
  ) async {
    await _pumpReports(tester);

    final selector = find.byKey(const Key('reportDateRangeSelector'));
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 Days').last);
    await tester.pumpAndSettle();

    expect(find.text('Last 7 Days'), findsOneWidget);
  });

  testWidgets('Reports uses a phone-friendly narrow date layout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpReports(tester);

    expect(
      find.byKey(const Key('reportDateRangeNarrowLayout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reportDateRangeWideLayout')), findsNothing);
  });

  testWidgets('ordinary User is denied financial Reports', (
    WidgetTester tester,
  ) async {
    await _pumpReports(tester, permissions: const AppPermissions.none());

    expect(
      find.text('You do not have permission to view financial reports.'),
      findsOneWidget,
    );
    expect(find.text('Financial Performance'), findsNothing);
    expect(find.text('Sales Analysis'), findsNothing);
    expect(find.text('Inventory Aging'), findsNothing);
    expect(find.text('Deals'), findsNothing);
  });
  testWidgets('Reports shows loading state', (WidgetTester tester) async {
    await _pumpReports(
      tester,
      reportsValue: const AsyncValue<ReportsSnapshot>.loading(),
      settle: false,
    );

    expect(find.text('Loading reports...'), findsOneWidget);
  });

  testWidgets('Reports shows error state', (WidgetTester tester) async {
    await _pumpReports(
      tester,
      reportsValue: AsyncValue<ReportsSnapshot>.error(
        StateError('test failure'),
        StackTrace.empty,
      ),
    );

    expect(find.text('Unable to load reports.'), findsOneWidget);
  });
}

Future<void> _pumpReports(
  WidgetTester tester, {
  AsyncValue<ReportsSnapshot>? reportsValue,
  AppPermissions permissions = const AppPermissions.ownerOrAdmin(),
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAppPermissionsProvider.overrideWithValue(permissions),
        reportsSnapshotProvider.overrideWithValue(
          reportsValue ?? AsyncValue.data(_snapshot),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ReportScreen())),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
