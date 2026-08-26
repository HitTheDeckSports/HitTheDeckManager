import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/auth_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authenticated_session.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/models/authorized_user.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:hit_the_deck_manager/features/authentication/domain/repositories/authorization_repository.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authentication_providers.dart';
import 'package:hit_the_deck_manager/features/authentication/presentation/providers/authorization_providers.dart';

class FakeAuthenticationRepository implements AuthenticationRepository {
  FakeAuthenticationRepository(this.user);

  final AuthUser? user;
  int signOutCount = 0;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(user);

  @override
  AuthUser? get currentUser => user;

  @override
  Future<AuthUser> signInWithGoogle() async {
    if (user == null) {
      throw StateError('No fake user configured.');
    }

    return user!;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
  }
}

class FakeAuthorizationRepository implements AuthorizationRepository {
  FakeAuthorizationRepository(this.authorization);

  final AuthorizedUser? authorization;

  @override
  Future<AuthorizedUser?> getAuthorization(AuthUser user) async {
    return authorization;
  }

  @override
  Stream<List<AuthorizedUser>> watchAuthorizedUsers() {
    return Stream.value(authorization == null ? const [] : [authorization!]);
  }

  @override
  Future<void> addAuthorizedUser({required String email}) async {}

  @override
  Future<void> disableAuthorizedUser(String email) async {}

  @override
  Future<void> restoreAuthorizedUser(String email) async {}
}

Future<AuthenticatedSession?> readSession(ProviderContainer container) async {
  final subscription = container.listen<AsyncValue<AuthenticatedSession?>>(
    authenticatedSessionProvider,
    (previous, next) {},
    fireImmediately: true,
  );

  try {
    return await container
        .read(authenticatedSessionProvider.future)
        .timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}

ProviderContainer createContainer({
  required AuthenticationRepository authenticationRepository,
  required AuthorizationRepository authorizationRepository,
}) {
  return ProviderContainer.test(
    overrides: [
      authenticationRepositoryProvider.overrideWithValue(
        authenticationRepository,
      ),
      authorizationRepositoryProvider.overrideWithValue(
        authorizationRepository,
      ),
    ],
  );
}

void main() {
  const authUser = AuthUser(id: 'admin-1', email: 'admin@example.com');

  group('authenticatedSessionProvider', () {
    test('returns null when no Firebase user is signed in', () async {
      final authenticationRepository = FakeAuthenticationRepository(null);
      final authorizationRepository = FakeAuthorizationRepository(null);

      final container = createContainer(
        authenticationRepository: authenticationRepository,
        authorizationRepository: authorizationRepository,
      );

      final session = await readSession(container);

      expect(session, isNull);
      expect(authenticationRepository.signOutCount, 0);
    });

    test('returns session for active authorized Admin', () async {
      final authenticationRepository = FakeAuthenticationRepository(authUser);
      final authorizationRepository = FakeAuthorizationRepository(
        const AuthorizedUser(
          email: 'admin@example.com',
          role: AuthorizedUserRole.admin,
          active: true,
        ),
      );

      final container = createContainer(
        authenticationRepository: authenticationRepository,
        authorizationRepository: authorizationRepository,
      );

      final session = await readSession(container);

      expect(session, isNotNull);
      expect(session!.user, authUser);
      expect(session.authorization.active, isTrue);
      expect(session.authorization.isAdmin, isTrue);
      expect(authenticationRepository.signOutCount, 0);
    });

    test('signs out when authorization record is missing', () async {
      final authenticationRepository = FakeAuthenticationRepository(authUser);
      final authorizationRepository = FakeAuthorizationRepository(null);

      final container = createContainer(
        authenticationRepository: authenticationRepository,
        authorizationRepository: authorizationRepository,
      );

      final session = await readSession(container);

      expect(session, isNull);
      expect(authenticationRepository.signOutCount, 1);
    });

    test('signs out when Admin authorization record is disabled', () async {
      final authenticationRepository = FakeAuthenticationRepository(authUser);
      final authorizationRepository = FakeAuthorizationRepository(
        const AuthorizedUser(
          email: 'admin@example.com',
          role: AuthorizedUserRole.admin,
          active: false,
        ),
      );

      final container = createContainer(
        authenticationRepository: authenticationRepository,
        authorizationRepository: authorizationRepository,
      );

      final session = await readSession(container);

      expect(session, isNull);
      expect(authenticationRepository.signOutCount, 1);
    });

    test('preserves Admin role in authenticated session', () async {
      final authenticationRepository = FakeAuthenticationRepository(authUser);
      final authorizationRepository = FakeAuthorizationRepository(
        const AuthorizedUser(
          email: 'admin@example.com',
          role: AuthorizedUserRole.admin,
          active: true,
        ),
      );

      final container = createContainer(
        authenticationRepository: authenticationRepository,
        authorizationRepository: authorizationRepository,
      );

      final session = await readSession(container);

      expect(session, isNotNull);
      expect(session!.authorization.isAdmin, isTrue);
      expect(session.authorization.isOwner, isFalse);
    });
  });
}
