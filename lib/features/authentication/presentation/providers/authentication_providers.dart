import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_authentication_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/authentication_repository.dart';

/// Provides the application's authentication repository.
///
/// The concrete Firebase implementation is injected behind the domain
/// repository contract so presentation code does not depend on Firebase.
final authenticationRepositoryProvider = Provider<AuthenticationRepository>((
  ref,
) {
  return FirebaseAuthenticationRepository();
});

/// Exposes the authenticated user and reacts to future sign-in/sign-out events.
///
/// A null value means there is currently no authenticated Firebase user.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authenticationRepositoryProvider);

  return repository.authStateChanges();
});
