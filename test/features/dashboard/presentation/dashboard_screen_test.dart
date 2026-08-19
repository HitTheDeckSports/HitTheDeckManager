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

  testWidgets('Dashboard displays approved metric cards in both sections', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(find.text('Month to Date'), findsOneWidget);
    expect(find.text('Current Inventory'), findsOneWidget);

    expect(find.byKey(const Key('dashboardRevenueCard')), findsOneWidget);
    expect(find.text('Total Revenue'), findsOneWidget);
    expect(find.text(r'$500.00'), findsOneWidget);

    expect(find.byKey(const Key('dashboardCostCard')), findsOneWidget);
    expect(find.text('Total Cost'), findsOneWidget);
    expect(find.text(r'$300.00'), findsOneWidget);

    expect(find.byKey(const Key('dashboardProfitCard')), findsOneWidget);
    expect(find.text('Total Profit'), findsOneWidget);
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
      find.byKey(const Key('dashboardPotentialProfitCard')),
      findsOneWidget,
    );
    expect(find.text('Open Potential Profit'), findsOneWidget);
    expect(find.text(r'$110.00'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardInventoryCountCard')),
      findsOneWidget,
    );
    expect(find.text('Inventory Count'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
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
        builder: (context, state) => const DashboardScreen(),
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
