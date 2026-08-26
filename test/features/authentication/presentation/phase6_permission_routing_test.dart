import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/app/app.dart';
import 'package:hit_the_deck_manager/app/app_router.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/auth_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authenticated_session.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authorization_providers.dart';

const ordinarySession = AuthenticatedSession(
  user: AuthUser(
    id: 'ordinary-user-id',
    email: 'user@example.com',
    displayName: 'Ordinary User',
  ),
  authorization: AuthorizedUser(
    email: 'user@example.com',
    role: AuthorizedUserRole.user,
    active: true,
  ),
);

Widget buildOrdinaryUserApp() {
  return ProviderScope(
    overrides: [
      authenticatedSessionProvider.overrideWith(
        (ref) => Stream.value(ordinarySession),
      ),
    ],
    child: const HitTheDeckApp(),
  );
}

Future<void> expectOrdinaryUserRedirect(
  WidgetTester tester,
  String restrictedPath,
) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(buildOrdinaryUserApp());
  await tester.pumpAndSettle();

  final element = tester.element(find.byType(MaterialApp));
  final container = ProviderScope.containerOf(element);
  final router = container.read(appRouterProvider);

  router.go(restrictedPath);
  await tester.pumpAndSettle();

  expect(router.routeInformationProvider.value.uri.path, '/');
  expect(find.text('Dashboard'), findsWidgets);
}

void main() {
  setUp(() {});

  tearDown(() {});

  testWidgets('ordinary user direct Reports route redirects to dashboard', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await expectOrdinaryUserRedirect(tester, '/reports');
  });

  testWidgets('ordinary user direct disposal route redirects to dashboard', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await expectOrdinaryUserRedirect(tester, '/inventory/item-1/dispose');
  });

  testWidgets('ordinary user direct User Access route redirects to dashboard', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await expectOrdinaryUserRedirect(tester, '/settings/user-access');
  });

  testWidgets('ordinary user direct edit-repair route redirects to dashboard', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await expectOrdinaryUserRedirect(tester, '/repairs/repair-1/edit');
  });

  testWidgets(
    'ordinary user direct warranty-replacement route redirects to dashboard',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await expectOrdinaryUserRedirect(
        tester,
        '/disposals/disposal-1/warranty-replacement',
      );
    },
  );
}
