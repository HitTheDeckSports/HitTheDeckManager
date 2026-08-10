import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/authorized_user.dart';
import '../../domain/repositories/authorization_repository.dart';

/// Firestore-backed authorization repository.
///
/// Approved users are stored in the `authorized_users` collection using their
/// normalized email address as the document ID.
class FirestoreAuthorizationRepository implements AuthorizationRepository {
  FirestoreAuthorizationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String rootOwnerEmail = 'sales.hitthedecksports@gmail.com';

  static const String _collectionName = 'authorized_users';

  final FirebaseFirestore _firestore;

  @override
  Future<AuthorizedUser?> getAuthorization(AuthUser user) async {
    final email = _normalizeEmail(user.email);

    // The business owner is the permanent root administrator. This safeguard
    // prevents an accidental Firestore document change from locking the owner
    // out of the application.
    if (email == rootOwnerEmail) {
      return const AuthorizedUser(
        email: rootOwnerEmail,
        role: AuthorizedUserRole.owner,
        active: true,
      );
    }

    try {
      final document = await _firestore
          .collection(_collectionName)
          .doc(email)
          .get();

      if (!document.exists) {
        return null;
      }

      final data = document.data();

      if (data == null) {
        return null;
      }

      final active = data['active'];

      if (active is! bool || !active) {
        return null;
      }

      final roleValue = data['role'];

      return AuthorizedUser(
        email: email,
        role: _parseRole(roleValue),
        active: active,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw PermissionException(
          'Unable to verify access to Hit the Deck Manager.',
          cause: error,
        );
      }

      if (error.code == 'unavailable') {
        throw NetworkException(
          'Unable to verify access. Check your internet connection.',
          cause: error,
        );
      }

      throw UnexpectedException(
        'An error occurred while verifying application access.',
        cause: error,
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }

      throw UnexpectedException(
        'An unexpected authorization error occurred.',
        cause: error,
      );
    }
  }

  AuthorizedUserRole _parseRole(Object? value) {
    switch (value) {
      case 'owner':
        return AuthorizedUserRole.owner;
      case 'user':
      default:
        return AuthorizedUserRole.user;
    }
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}
