import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_metrics.dart';
import 'package:hit_the_deck_manager/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hit_the_deck_manager/features/dashboard/presentation/providers/dashboard_providers.dart';

const _testMetrics = DashboardMetrics(
  totalRevenueCents: 50000,
  totalCostCents: 30000,
  totalProfitCents: 20000,
  grossMargin: 0.40,
  openInventoryValueCents: 29000,
  openInventoryCostCents: 18000,
  openPotentialProfitCents: 11000,
  inventoryCount: 3,
  unitsSold: 7,
  availableItems: 12,
  averageDaysInInventory: 26,
  brokenItems: 2,
  dateRangeLabel: 'Month to Date',
);

void main() {
  testWidgets('Dashboard shows approved quick actions without Sell', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(
      find.byKey(const Key('dashboardAddInventoryButton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboardScanQrButton')), findsOneWidget);

    expect(find.text('Add Inventory'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);

    expect(find.text('Sell Inventory'), findsNothing);
    expect(find.text('Sell'), findsNothing);
  });

  testWidgets('Dashboard displays approved eight primary cards', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(find.byKey(const Key('dashboardRevenueCard')), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text(r'$500.00'), findsOneWidget);

    expect(find.byKey(const Key('dashboardCostCard')), findsOneWidget);
    expect(find.text('Cost'), findsOneWidget);
    expect(find.text(r'$300.00'), findsOneWidget);

    expect(find.byKey(const Key('dashboardProfitCard')), findsOneWidget);
    expect(find.text('Profit'), findsOneWidget);
    expect(find.text(r'$200.00'), findsOneWidget);

    expect(find.byKey(const Key('dashboardMarginCard')), findsOneWidget);
    expect(find.text('Gross Margin'), findsOneWidget);
    expect(find.text('40.0%'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardInventoryValueCard')),
      findsOneWidget,
    );
    expect(find.text('Open Inventory Value'), findsOneWidget);
    expect(find.text(r'$290.00'), findsOneWidget);

    expect(find.byKey(const Key('dashboardInventoryCostCard')), findsOneWidget);
    expect(find.text('Open Inventory Cost'), findsOneWidget);
    expect(find.text(r'$180.00'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardInventoryCountCard')),
      findsOneWidget,
    );
    expect(find.text('Inventory Count'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardPotentialProfitCard')),
      findsOneWidget,
    );
    expect(find.text('Current Inventory Potential Profit'), findsOneWidget);
    expect(find.text(r'$110.00'), findsOneWidget);
  });

  testWidgets('Dashboard displays the approved Quick Snapshot', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(find.text('Quick Snapshot'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardAvailableItemsCard')),
      findsOneWidget,
    );
    expect(find.text('Available Items'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    expect(find.byKey(const Key('dashboardUnitsSoldCard')), findsOneWidget);
    expect(find.text('Units Sold'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    expect(find.byKey(const Key('dashboardAverageDaysCard')), findsOneWidget);
    expect(find.text('Average Days in Inventory'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('days'), findsOneWidget);

    expect(find.byKey(const Key('dashboardBrokenItemsCard')), findsOneWidget);
    expect(find.text('Broken Items'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Dashboard date selector uses narrow layout on a phone width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(
      find.byKey(const Key('dashboardDateRangeNarrowLayout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboardDateRangeWideLayout')), findsNothing);
    expect(find.byKey(const Key('dashboardDateRangeSelector')), findsOneWidget);
    expect(find.text('Performance Period'), findsOneWidget);
  });
  testWidgets('Dashboard defaults date-range selector to Month to Date', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(find.byKey(const Key('dashboardDateRangeSelector')), findsOneWidget);
    expect(
      find.byKey(const Key('dashboardPerformancePeriodLabel')),
      findsOneWidget,
    );
    expect(find.text('Month to Date'), findsWidgets);
  });

  testWidgets('Dashboard date-range selector updates preset selection', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    final selector = find.byKey(const Key('dashboardDateRangeSelector'));
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 Days').last);
    await tester.pumpAndSettle();

    expect(find.text('Last 7 Days'), findsOneWidget);
  });
  testWidgets('Dashboard Add Inventory action navigates correctly', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    await tester.tap(find.byKey(const Key('dashboardAddInventoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Inventory destination'), findsOneWidget);
  });

  testWidgets('Dashboard Scan QR action navigates correctly', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    await tester.tap(find.byKey(const Key('dashboardScanQrButton')));
    await tester.pumpAndSettle();

    expect(find.text('Scanner destination'), findsOneWidget);
  });
}

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const Scaffold(body: DashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.buyInventory,
        name: AppRouteNames.buyInventory,
        builder: (context, state) {
          return const Scaffold(body: Text('Add Inventory destination'));
        },
      ),
      GoRoute(
        path: AppRoutes.inventoryScanner,
        name: AppRouteNames.inventoryScanner,
        builder: (context, state) {
          return const Scaffold(body: Text('Scanner destination'));
        },
      ),
    ],
  );
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardMetricsProvider.overrideWithValue(
          const AsyncValue.data(_testMetrics),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  await tester.pumpAndSettle();
}
