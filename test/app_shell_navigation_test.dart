import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/app/app_shell.dart';

void main() {
  testWidgets(
    'mobile shell uses bottom navigation with approved destinations',
    (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.dashboard,
        routes: [
          ShellRoute(
            builder: (context, state, child) {
              return AppShell(child: child);
            },
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) =>
                    const Center(child: Text('Dashboard destination')),
              ),
              GoRoute(
                path: AppRoutes.inventory,
                builder: (context, state) =>
                    const Center(child: Text('Inventory destination')),
              ),
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) =>
                    const Center(child: Text('Transactions destination')),
              ),
              GoRoute(
                path: AppRoutes.contacts,
                builder: (context, state) =>
                    const Center(child: Text('Contacts destination')),
              ),
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) =>
                    const Center(child: Text('Reports destination')),
              ),
            ],
          ),
        ],
      );

      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDrawer), findsNothing);

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      expect(find.text('Home'), findsNothing);
    },
  );

  testWidgets('mobile bottom navigation routes to core destinations', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) =>
                  const Center(child: Text('Dashboard destination')),
            ),
            GoRoute(
              path: AppRoutes.inventory,
              builder: (context, state) =>
                  const Center(child: Text('Inventory destination')),
            ),
            GoRoute(
              path: AppRoutes.transactions,
              builder: (context, state) =>
                  const Center(child: Text('Transactions destination')),
            ),
            GoRoute(
              path: AppRoutes.contacts,
              builder: (context, state) =>
                  const Center(child: Text('Contacts destination')),
            ),
            GoRoute(
              path: AppRoutes.reports,
              builder: (context, state) =>
                  const Center(child: Text('Reports destination')),
            ),
          ],
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.pumpAndSettle();

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

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Reports destination'), findsOneWidget);
  });

  testWidgets('wide shell uses navigation rail without Home destination', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) =>
                  const Center(child: Text('Dashboard destination')),
            ),
            GoRoute(
              path: AppRoutes.inventory,
              builder: (context, state) =>
                  const Center(child: Text('Inventory destination')),
            ),
            GoRoute(
              path: AppRoutes.transactions,
              builder: (context, state) =>
                  const Center(child: Text('Transactions destination')),
            ),
            GoRoute(
              path: AppRoutes.contacts,
              builder: (context, state) =>
                  const Center(child: Text('Contacts destination')),
            ),
            GoRoute(
              path: AppRoutes.reports,
              builder: (context, state) =>
                  const Center(child: Text('Reports destination')),
            ),
          ],
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
