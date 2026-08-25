import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hit_the_deck_manager/app/app_routes.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/app_permissions.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/app_permissions_provider.dart';
import 'package:hit_the_deck_manager/features/settings/presentation/more_screen.dart';

void main() {
  testWidgets('Owner/Admin More screen includes Reports and Settings', (
    WidgetTester tester,
  ) async {
    await _pumpMore(tester, permissions: const AppPermissions.ownerOrAdmin());
    expect(find.byKey(const Key('moreReportsTile')), findsOneWidget);
    expect(find.byKey(const Key('moreSettingsTile')), findsOneWidget);
  });

  testWidgets('ordinary User More screen hides Reports but keeps Settings', (
    WidgetTester tester,
  ) async {
    await _pumpMore(tester, permissions: const AppPermissions.none());
    expect(find.byKey(const Key('moreReportsTile')), findsNothing);
    expect(find.byKey(const Key('moreSettingsTile')), findsOneWidget);
  });
}

Future<void> _pumpMore(
  WidgetTester tester, {
  required AppPermissions permissions,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.more,
    routes: [
      GoRoute(
        path: AppRoutes.more,
        builder: (context, state) => const MoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const Scaffold(body: Text('Reports page')),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            const Scaffold(body: Text('Settings page')),
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
}
