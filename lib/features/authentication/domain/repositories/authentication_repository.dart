import '../models/auth_user.dart';

/// Contract for authentication operations used by the application.
///
/// The domain layer does not know whether authentication is backed by
/// Firebase, another provider, or a test implementation.
abstract interface class AuthenticationRepository {
  /// Emits the current authenticated user and future authentication changes.
  Stream<AuthUser?> authStateChanges();

  /// Returns the currently authenticated user, if one exists.
  AuthUser? get currentUser;

  /// Starts an interactive Google sign-in flow.
  Future<AuthUser> signInWithGoogle();

  /// Signs out of the active authentication session.
  Future<void> signOut();
}
