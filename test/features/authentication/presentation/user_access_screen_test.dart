import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/auth_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authenticated_session.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/repositories/authorization_repository.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authorization_providers.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/user_access_screen.dart';

class FakeAuthorizationRepository implements AuthorizationRepository {
  String? addedEmail;
  String? disabledEmail;
  String? restoredEmail;

  @override
  Future<AuthorizedUser?> getAuthorization(AuthUser user) async => null;

  @override
  Stream<List<AuthorizedUser>> watchAuthorizedUsers() => const Stream.empty();

  @override
  Future<void> addAuthorizedUser({required String email}) async {
    addedEmail = email;
  }

  @override
  Future<void> disableAuthorizedUser(String email) async {
    disabledEmail = email;
  }

  @override
  Future<void> restoreAuthorizedUser(String email) async {
    restoredEmail = email;
  }
}

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
    id: 'admin-id',
    email: 'admin@example.com',
    displayName: 'Admin',
  ),
  authorization: AuthorizedUser(
    email: 'admin@example.com',
    role: AuthorizedUserRole.admin,
    active: true,
  ),
);

const activeAdmin = AuthorizedUser(
  email: 'active-admin@example.com',
  role: AuthorizedUserRole.admin,
  active: true,
);

const disabledAdmin = AuthorizedUser(
  email: 'disabled-admin@example.com',
  role: AuthorizedUserRole.admin,
  active: false,
);

const ownerProfile = AuthorizedUser(
  email: 'sales.hitthedecksports@gmail.com',
  role: AuthorizedUserRole.owner,
  active: true,
);

Widget buildUserAccess({
  required AuthenticatedSession session,
  required FakeAuthorizationRepository repository,
}) {
  return ProviderScope(
    overrides: [
      authorizationRepositoryProvider.overrideWithValue(repository),
      authenticatedSessionProvider.overrideWith((ref) => Stream.value(session)),
      authorizedUsersProvider.overrideWith(
        (ref) => Stream.value(const [ownerProfile, activeAdmin, disabledAdmin]),
      ),
    ],
    child: const MaterialApp(home: UserAccessScreen()),
  );
}

void main() {
  testWidgets(
    'Owner can disable and restore Admin profiles while Owner stays protected',
    (tester) async {
      final repository = FakeAuthorizationRepository();

      await tester.pumpWidget(
        buildUserAccess(session: ownerSession, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Admin'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Disable'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin can add Admin profiles but cannot modify existing Admins',
    (tester) async {
      final repository = FakeAuthorizationRepository();

      await tester.pumpWidget(
        buildUserAccess(session: adminSession, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Admin'), findsOneWidget);
      expect(find.text('Disable'), findsNothing);
      expect(find.text('Restore'), findsNothing);
      expect(find.text('Admin'), findsNWidgets(2));
    },
  );

  testWidgets('Admin Add dialog creates a new Admin access record', (
    tester,
  ) async {
    final repository = FakeAuthorizationRepository();

    await tester.pumpWidget(
      buildUserAccess(session: adminSession, repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Admin'));
    await tester.pumpAndSettle();

    expect(find.text('Add Admin Profile'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'new-admin@example.com');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(repository.addedEmail, 'new-admin@example.com');
    expect(
      find.text('Admin access granted to new-admin@example.com.'),
      findsOneWidget,
    );
  });
}
