import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/app/app.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/auth_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authenticated_session.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authorization_providers.dart';

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
    expect(find.text('Add Inventory'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);

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

    await tester.tap(find.text('Add Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Buy Inventory'), findsOneWidget);
  });
}
