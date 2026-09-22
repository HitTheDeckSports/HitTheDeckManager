import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/auth_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authenticated_session.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authentication_providers.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authorization_providers.dart';
import 'package:hit_the_deck_manager/features/settings/presentation/settings_screen.dart';

class _FakeAuthenticationRepository implements AuthenticationRepository {
  bool signedOut = false;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  AuthUser? get currentUser =>
      const AuthUser(id: 'admin-user', email: 'admin@example.com');

  @override
  Future<AuthUser> signInWithGoogle() async => currentUser!;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

const _adminSession = AuthenticatedSession(
  user: AuthUser(id: 'admin-user', email: 'admin@example.com'),
  authorization: AuthorizedUser(
    email: 'admin@example.com',
    role: AuthorizedUserRole.admin,
    active: true,
  ),
);

void main() {
  testWidgets('Settings exposes Sign Out and confirms before signing out', (
    tester,
  ) async {
    final repository = _FakeAuthenticationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
          authenticatedSessionProvider.overrideWith(
            (ref) => Stream.value(_adminSession),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final signOut = find.byKey(const Key('settingsSignOutTile'));
    expect(signOut, findsOneWidget);

    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    expect(find.text('Sign Out?'), findsOneWidget);
    expect(repository.signedOut, isFalse);

    await tester.tap(find.byKey(const Key('confirmSignOutButton')));
    await tester.pumpAndSettle();

    expect(repository.signedOut, isTrue);
  });

  testWidgets('canceling Sign Out keeps the current session', (tester) async {
    final repository = _FakeAuthenticationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
          authenticatedSessionProvider.overrideWith(
            (ref) => Stream.value(_adminSession),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final signOut = find.byKey(const Key('settingsSignOutTile'));
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.signedOut, isFalse);
  });
}
