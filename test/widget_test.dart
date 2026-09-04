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
const testOwnerSession = AuthenticatedSession(
  user: AuthUser(
    id: 'test-owner-id',
    email: 'sales.hitthedecksports@gmail.com',
    displayName: 'Hit the Deck Sports',
  ),
  authorization: AuthorizedUser(
    email: 'sales.hitthedecksports@gmail.com',
    role: AuthorizedUserRole.owner,
    active: true,
  ),
);

Widget buildAuthorizedApp() {
  return ProviderScope(
    overrides: [
      authenticatedSessionProvider.overrideWith(
        (ref) => Stream.value(testOwnerSession),
      ),
      dashboardMetricsProvider.overrideWithValue(
        const AsyncValue.data(regressionTestDashboardMetrics),
      ),
    ],
    child: const HitTheDeckApp(),
  );
}

void main() {
  testWidgets('app loads dashboard and navigates between sections', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildAuthorizedApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(
      find.byKey(const Key('dashboardAddInventoryButton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboardScanQrButton')), findsOneWidget);

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('dashboard Add Inventory opens buy workflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildAuthorizedApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboardAddInventoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Buy Inventory'), findsOneWidget);
  });
}
