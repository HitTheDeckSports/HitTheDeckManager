import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/app/app.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/auth_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authenticated_session.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authorization_providers.dart';
import 'package:hit_the_deck_manager/features/dashboard/application/dashboard_metrics.dart';
import 'package:hit_the_deck_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:hit_the_deck_manager/features/settings/presentation/settings_screen.dart';

const regressionTestDashboardMetrics = DashboardMetrics(
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
const ownerSession = AuthenticatedSession(
  user: AuthUser(
    id: 'owner-id',
    email: 'sales.hitthedecksports@gmail.com',
    displayName: 'Owner',
  ),
  authorization: AuthorizedUser(
    email: 'sales.hitthedecksports@gmail.com',
    role: AuthorizedUserRole.owner,
    active: true,
  ),
);

const adminSession = AuthenticatedSession(
  user: AuthUser(
    id: 'admin-user-id',
    email: 'admin@example.com',
    displayName: 'Admin User',
  ),
  authorization: AuthorizedUser(
    email: 'admin@example.com',
    role: AuthorizedUserRole.admin,
    active: true,
  ),
);

Widget buildAppWithSession(AuthenticatedSession? session) {
  return ProviderScope(
    overrides: [
      authenticatedSessionProvider.overrideWith((ref) => Stream.value(session)),
      dashboardMetricsProvider.overrideWithValue(
        const AsyncValue.data(regressionTestDashboardMetrics),
      ),
    ],
    child: const HitTheDeckApp(),
  );
}

Widget buildSettingsWithSession(AuthenticatedSession session) {
  return ProviderScope(
    overrides: [
      authenticatedSessionProvider.overrideWith((ref) => Stream.value(session)),
    ],
    child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
  );
}

void main() {
  group('authentication routing', () {
    testWidgets('signed-out user is redirected to login', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppWithSession(null));
      await tester.pumpAndSettle();

      expect(find.text('Hit the Deck Manager'), findsWidgets);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('Admin is allowed into protected home', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppWithSession(adminSession));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsWidgets);
      expect(
        find.byKey(const Key('dashboardInventoryCountCard')),
        findsOneWidget,
      );
      expect(find.text('Sign in with Google'), findsNothing);
    });
  });

  group('Settings role visibility', () {
    for (final entry in <String, AuthenticatedSession>{
      'Owner': ownerSession,
      'Admin': adminSession,
    }.entries) {
      testWidgets('${entry.key} sees User Access administration option', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildSettingsWithSession(entry.value));
        await tester.pumpAndSettle();

        expect(find.text('Administration'), findsOneWidget);
        expect(find.text('User Access'), findsOneWidget);
      });
    }
  });
}
