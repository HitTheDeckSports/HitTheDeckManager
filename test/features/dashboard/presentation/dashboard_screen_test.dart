import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';
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

  testWidgets('Dashboard shows the approved inventory overview', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(find.text('Inventory Overview'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardInventoryCountCard')),
      findsOneWidget,
    );
    expect(find.text('Total Inventory Items'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    expect(find.byKey(const Key('dashboardInventoryCostCard')), findsOneWidget);
    expect(find.text('Total Cost of Inventory'), findsOneWidget);
    expect(find.text(r'$180.00'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardInventoryValueCard')),
      findsOneWidget,
    );
    expect(find.text('Est. Inventory Revenue'), findsOneWidget);
    expect(find.text(r'$290.00'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardPotentialProfitCard')),
      findsOneWidget,
    );
    expect(find.text('Est. Inventory Profit'), findsOneWidget);
    expect(find.text(r'$110.00'), findsOneWidget);
  });

  testWidgets('Dashboard shows the approved quick stats', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(find.text('Quick Stats'), findsOneWidget);

    expect(
      find.byKey(const Key('dashboardAvailableItemsCard')),
      findsOneWidget,
    );
    expect(find.text('Available Items'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    expect(find.byKey(const Key('dashboardUnitsSoldCard')), findsOneWidget);
    expect(find.text('Items Sold Month to Date'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    expect(find.byKey(const Key('dashboardBrokenItemsCard')), findsOneWidget);
    expect(find.text('Needs Repair'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    expect(find.byKey(const Key('dashboardAverageDaysCard')), findsOneWidget);
    expect(find.text('Average Days in Inventory'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('days'), findsOneWidget);
  });

  testWidgets('Dashboard omits report-only performance controls and cards', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(tester, router: router);

    expect(find.byKey(const Key('dashboardDateRangeSelector')), findsNothing);
    expect(find.text('Performance Period'), findsNothing);
    expect(find.text('Revenue'), findsNothing);
    expect(find.text('Cost'), findsNothing);
    expect(find.text('Profit'), findsNothing);
    expect(find.text('Gross Margin'), findsNothing);
  });

  testWidgets('ordinary User sees revenue but not cost or profit', (
    WidgetTester tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpDashboard(
      tester,
      router: router,
      permissions: const AppPermissions.none(),
    );

    expect(
      find.byKey(const Key('dashboardInventoryCountCard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dashboardInventoryValueCard')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboardInventoryCostCard')), findsNothing);
    expect(find.byKey(const Key('dashboardPotentialProfitCard')), findsNothing);

    expect(
      find.byKey(const Key('dashboardAvailableItemsCard')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboardUnitsSoldCard')), findsOneWidget);
    expect(find.byKey(const Key('dashboardBrokenItemsCard')), findsOneWidget);
    expect(find.byKey(const Key('dashboardAverageDaysCard')), findsOneWidget);
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
  AppPermissions permissions = const AppPermissions.ownerOrAdmin(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAppPermissionsProvider.overrideWithValue(permissions),
        dashboardMetricsProvider.overrideWithValue(
          const AsyncValue.data(_testMetrics),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  await tester.pumpAndSettle();
}
