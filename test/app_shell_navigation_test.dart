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

    router.go('/transactions/sale-1');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('transactionDetailHeaderBackButton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('globalSearchHeaderButton')), findsNothing);
    expect(find.byKey(const Key('globalSettingsHeaderButton')), findsNothing);

    await tester.tap(
      find.byKey(const Key('transactionDetailHeaderBackButton')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Transactions destination'), findsOneWidget);
  });

  testWidgets('secondary routes use centered contextual header', (
    tester,
  ) async {
    final router = await _pump(tester);

    for (final route in <String>[
      '/inventory/item-1/repairs/new',
      '/inventory/item-1/dispose',
      '/inventory/item-1/consignment/new',
      '/repairs/repair-1/edit',
      '/disposals/disposal-1/warranty-replacement',
      AppRoutes.createContact,
      '/contacts/contact-1',
      '/contacts/contact-1/edit',
      AppRoutes.inventoryLocations,
      AppRoutes.userAccess,
      AppRoutes.search,
      AppRoutes.inventoryScanner,
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('contextualHeaderBackButton')),
        findsOneWidget,
        reason: 'Expected contextual Back button for $route',
      );
      expect(find.byKey(const Key('globalSearchHeaderButton')), findsNothing);
      expect(find.byKey(const Key('globalSettingsHeaderButton')), findsNothing);
    }
  });

  testWidgets('pushed search returns to originating screen', (tester) async {
    final router = await _pump(tester);
    router.go(AppRoutes.contacts);
    await tester.pumpAndSettle();

    router.push(AppRoutes.search);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contextualHeaderBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('Contacts destination'), findsOneWidget);
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
          _r(AppRoutes.inventoryScanner, 'Scanner destination'),
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
          _r(AppRoutes.addRepair, 'Add repair destination'),
          _r(AppRoutes.disposeInventory, 'Dispose destination'),
          _r(AppRoutes.recordConsignment, 'Consignment destination'),
          _r(AppRoutes.warrantyReplacement, 'Warranty destination'),
          _r(AppRoutes.repairDetail, 'Repair detail destination'),
          _r(AppRoutes.editRepair, 'Edit repair destination'),
          GoRoute(
            path: AppRoutes.transactionDetail,
            name: AppRouteNames.transactionDetail,
            builder: (c, s) =>
                const Center(child: Text('Transaction detail destination')),
          ),
          _r(AppRoutes.transactions, 'Transactions destination'),
          _r(AppRoutes.contacts, 'Contacts destination'),
          _r(AppRoutes.createContact, 'Create contact destination'),
          _r(AppRoutes.contactDetail, 'Contact detail destination'),
          _r(AppRoutes.editContact, 'Edit contact destination'),
          _r(AppRoutes.reports, 'Reports destination'),
          _r(AppRoutes.search, 'Search destination'),
          _r(AppRoutes.settings, 'Settings destination'),
          _r(AppRoutes.inventoryLocations, 'Locations destination'),
          _r(AppRoutes.userAccess, 'User access destination'),
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
