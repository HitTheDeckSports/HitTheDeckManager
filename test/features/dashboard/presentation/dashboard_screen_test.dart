import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard shows approved quick actions without Sell', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.buyInventory,
          name: AppRouteNames.buyInventory,
          builder: (context, state) =>
              const Scaffold(body: Text('Add Inventory destination')),
        ),
        GoRoute(
          path: AppRoutes.inventoryScanner,
          name: AppRouteNames.inventoryScanner,
          builder: (context, state) =>
              const Scaffold(body: Text('Scanner destination')),
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

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

  testWidgets('Dashboard Add Inventory action navigates correctly', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.buyInventory,
          name: AppRouteNames.buyInventory,
          builder: (context, state) =>
              const Scaffold(body: Text('Add Inventory destination')),
        ),
        GoRoute(
          path: AppRoutes.inventoryScanner,
          name: AppRouteNames.inventoryScanner,
          builder: (context, state) =>
              const Scaffold(body: Text('Scanner destination')),
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboardAddInventoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Inventory destination'), findsOneWidget);
  });

  testWidgets('Dashboard Scan QR action navigates correctly', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.buyInventory,
          name: AppRouteNames.buyInventory,
          builder: (context, state) =>
              const Scaffold(body: Text('Add Inventory destination')),
        ),
        GoRoute(
          path: AppRoutes.inventoryScanner,
          name: AppRouteNames.inventoryScanner,
          builder: (context, state) =>
              const Scaffold(body: Text('Scanner destination')),
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboardScanQrButton')));
    await tester.pumpAndSettle();

    expect(find.text('Scanner destination'), findsOneWidget);
  });
}
