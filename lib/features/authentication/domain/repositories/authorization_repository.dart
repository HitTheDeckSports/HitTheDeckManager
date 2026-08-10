import '../models/auth_user.dart';
import '../models/authorized_user.dart';

/// Contract for determining whether an authenticated identity may use the app.
///
/// Authentication proves identity. Authorization separately determines
/// whether that identity has access to Hit the Deck Manager.
abstract interface class AuthorizationRepository {
  /// Returns the user's authorization record, or null if access is not granted.
  Future<AuthorizedUser?> getAuthorization(AuthUser user);
}
