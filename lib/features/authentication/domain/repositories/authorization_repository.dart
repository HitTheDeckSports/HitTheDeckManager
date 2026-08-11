import '../models/auth_user.dart';
import '../models/authorized_user.dart';

/// Contract for determining and managing Hit the Deck Manager access.
///
/// Authentication proves identity. Authorization separately determines
/// whether that identity has access to the application.
abstract interface class AuthorizationRepository {
  /// Returns the user's authorization record, or null if access is not granted.
  Future<AuthorizedUser?> getAuthorization(AuthUser user);

  /// Returns all access records.
  ///
  /// This operation is intended for the permanent owner account.
  Stream<List<AuthorizedUser>> watchAuthorizedUsers();

  /// Adds a new authorized user.
  Future<void> addAuthorizedUser({required String email});

  /// Disables an existing user's access without deleting their history.
  Future<void> disableAuthorizedUser(String email);

  /// Restores access for a previously disabled user.
  Future<void> restoreAuthorizedUser(String email);
}
