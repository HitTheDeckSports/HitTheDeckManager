import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/app/app_shell.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';

void main() {
  testWidgets('workflow routes use contextual header back buttons', (
    tester,
  ) async {
    final router = await _pump(tester);
    router.go(AppRoutes.buyInventory);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('inventoryWorkflowHeaderBackButton')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('inventoryWorkflowHeaderBackButton')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Inventory destination'), findsOneWidget);
    router.go('/inventory/item-1/edit');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('inventoryEditHeaderBackButton')),
      findsOneWidget,
    );
  });
  testWidgets('standard shell retains core navigation', (tester) async {
    await _pump(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('globalSearchHeaderButton')), findsOneWidget);
    expect(find.byKey(const Key('globalSettingsHeaderButton')), findsOneWidget);
  });
}

Future<GoRouter> _pump(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          _r(AppRoutes.dashboard, 'Dashboard destination'),
          _r(AppRoutes.inventory, 'Inventory destination'),
          _r(AppRoutes.buyInventory, 'Buy destination'),
          _r(AppRoutes.sellInventory, 'Sell destination'),
          GoRoute(
            path: AppRoutes.inventoryDetail,
            name: AppRouteNames.inventoryDetail,
            builder: (c, s) => const Center(child: Text('Detail destination')),
          ),
          GoRoute(
            path: AppRoutes.inventoryEdit,
            name: AppRouteNames.inventoryEdit,
            builder: (c, s) => const Center(child: Text('Edit destination')),
          ),
          _r(AppRoutes.transactions, 'Transactions destination'),
          _r(AppRoutes.contacts, 'Contacts destination'),
          _r(AppRoutes.reports, 'Reports destination'),
          _r(AppRoutes.search, 'Search destination'),
          _r(AppRoutes.settings, 'Settings destination'),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAppPermissionsProvider.overrideWithValue(
          const AppPermissions.ownerOrAdmin(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

GoRoute _r(String path, String label) => GoRoute(
  path: path,
  builder: (c, s) => Center(child: Text(label)),
);
