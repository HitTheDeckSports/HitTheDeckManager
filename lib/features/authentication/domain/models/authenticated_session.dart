import 'auth_user.dart';
import 'authorized_user.dart';

/// Represents a user who is both authenticated and authorized to use
/// Hit the Deck Manager.
class AuthenticatedSession {
  const AuthenticatedSession({required this.user, required this.authorization});

  final AuthUser user;
  final AuthorizedUser authorization;

  bool get isOwner => authorization.isOwner;
}
