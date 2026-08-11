import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/app/app.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/auth_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authenticated_session.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authorization_providers.dart';
import 'package:hit_the_deck_manager/features/settings/presentation/settings_screen.dart';

const testAuthUser = AuthUser(
  id: 'test-user-id',
  email: 'user@example.com',
  displayName: 'Test User',
);

const regularSession = AuthenticatedSession(
  user: testAuthUser,
  authorization: AuthorizedUser(
    email: 'user@example.com',
    role: AuthorizedUserRole.user,
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
      expect(find.text('Inventory Management'), findsNothing);
    });

    testWidgets('authorized user is allowed into protected home', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppWithSession(regularSession));
      await tester.pumpAndSettle();

      expect(find.text('Inventory Management'), findsOneWidget);
      expect(find.text('Buy Inventory'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsNothing);
    });
  });

  group('Settings role visibility', () {
    testWidgets('admin sees User Access administration option', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSettingsWithSession(adminSession));
      await tester.pumpAndSettle();

      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('User Access'), findsOneWidget);
    });

    testWidgets('normal user does not see User Access option', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSettingsWithSession(regularSession));
      await tester.pumpAndSettle();

      expect(find.text('Administration'), findsNothing);
      expect(find.text('User Access'), findsNothing);
      expect(find.text('Preferences'), findsOneWidget);
    });
  });
}
