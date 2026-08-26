import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firestore_authorization_repository.dart';
import '../../domain/models/authenticated_session.dart';
import '../../domain/models/authorized_user.dart';
import '../../domain/repositories/authorization_repository.dart';
import 'authentication_providers.dart';

/// Provides access to the Firestore-backed authorization service.
final authorizationRepositoryProvider = Provider<AuthorizationRepository>((
  ref,
) {
  return FirestoreAuthorizationRepository();
});

/// Represents the currently authenticated and authorized application session.
///
/// Firebase Authentication may remember a Google login between app launches.
/// Every authenticated user is therefore rechecked against the application's
/// authorization rules before an application session is granted.
///
/// If a user's access has been disabled or removed, the Firebase session is
/// immediately signed out.
final authenticatedSessionProvider = StreamProvider<AuthenticatedSession?>((
  ref,
) {
  final authenticationRepository = ref.watch(authenticationRepositoryProvider);
  final authorizationRepository = ref.watch(authorizationRepositoryProvider);

  return authenticationRepository.authStateChanges().asyncMap((user) async {
    if (user == null) {
      return null;
    }

    final authorization = await authorizationRepository.getAuthorization(user);

    if (authorization == null || !authorization.active) {
      await authenticationRepository.signOut();
      return null;
    }

    return AuthenticatedSession(user: user, authorization: authorization);
  });
});

/// Streams the full authorized-user list.
///
/// Version 1.0 allows both the Owner and active Admins to view this list.
/// Firestore rules separately restrict changes to existing Admin profiles
/// to the permanent Owner.
final authorizedUsersProvider = StreamProvider<List<AuthorizedUser>>((ref) {
  final repository = ref.watch(authorizationRepositoryProvider);

  return repository.watchAuthorizedUsers();
});
