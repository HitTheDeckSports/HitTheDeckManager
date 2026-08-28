import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/app/app_shell.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';

void main() {
  testWidgets('mobile shell uses approved navigation and header destinations', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('More'), findsNothing);
    expect(find.byKey(const Key('globalSearchHeaderButton')), findsOneWidget);
    expect(find.byKey(const Key('globalSettingsHeaderButton')), findsOneWidget);
    expect(find.byKey(const Key('globalSearchFloatingButton')), findsNothing);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, const Color(0xFF031C35));
    expect(find.text('HIT THE DECK'), findsOneWidget);
    expect(find.text('MANAGER'), findsOneWidget);
  });

  testWidgets('mobile bottom navigation routes to core destinations', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);

    expect(find.text('Dashboard destination'), findsOneWidget);

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();
    expect(find.text('Inventory destination'), findsOneWidget);

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('Transactions destination'), findsOneWidget);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Contacts destination'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Reports destination'), findsOneWidget);
  });

  testWidgets('header buttons route to Search and Settings', (
    WidgetTester tester,
  ) async {
    final router = await _pumpShell(tester);

    await tester.tap(find.byKey(const Key('globalSearchHeaderButton')));
    await tester.pumpAndSettle();
    expect(find.text('Search destination'), findsOneWidget);

    router.go(AppRoutes.dashboard);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('globalSettingsHeaderButton')));
    await tester.pumpAndSettle();
    expect(find.text('Settings destination'), findsOneWidget);
  });

  testWidgets('Inventory Detail uses route-specific global header', (
    WidgetTester tester,
  ) async {
    final router = await _pumpShell(tester);

    router.go('/inventory/item-1');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventoryDetailHeaderBackButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryDetailHeaderEditButton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('globalSearchHeaderButton')), findsNothing);
    expect(find.byKey(const Key('globalSettingsHeaderButton')), findsNothing);
    expect(find.text('HIT THE DECK'), findsOneWidget);
    expect(find.text('MANAGER'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inventoryDetailHeaderEditButton')));
    await tester.pumpAndSettle();
    expect(find.text('Inventory edit destination'), findsOneWidget);
  });
  testWidgets('ordinary User navigation hides Reports', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester, permissions: const AppPermissions.none());

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(navigationBar.destinations, hasLength(4));
    expect(find.text('Reports'), findsNothing);
    expect(find.text('More'), findsNothing);
    expect(find.byKey(const Key('globalSearchHeaderButton')), findsOneWidget);
    expect(find.byKey(const Key('globalSettingsHeaderButton')), findsOneWidget);
  });

  testWidgets('wide shell uses navigation rail with approved destinations', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpShell(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('More'), findsNothing);
  });
}

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  AppPermissions permissions = const AppPermissions.ownerOrAdmin(),
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          _route(AppRoutes.dashboard, 'Dashboard destination'),
          _route(AppRoutes.inventory, 'Inventory destination'),
          GoRoute(
            path: AppRoutes.inventoryDetail,
            name: AppRouteNames.inventoryDetail,
            builder: (context, state) =>
                const Center(child: Text('Inventory detail destination')),
          ),
          GoRoute(
            path: AppRoutes.inventoryEdit,
            name: AppRouteNames.inventoryEdit,
            builder: (context, state) =>
                const Center(child: Text('Inventory edit destination')),
          ),
          _route(AppRoutes.transactions, 'Transactions destination'),
          _route(AppRoutes.contacts, 'Contacts destination'),
          _route(AppRoutes.reports, 'Reports destination'),
          _route(AppRoutes.search, 'Search destination'),
          _route(AppRoutes.settings, 'Settings destination'),
        ],
      ),
    ],
  );

  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentAppPermissionsProvider.overrideWithValue(permissions)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}

GoRoute _route(String path, String label) {
  return GoRoute(
    path: path,
    builder: (context, state) => Center(child: Text(label)),
  );
}
