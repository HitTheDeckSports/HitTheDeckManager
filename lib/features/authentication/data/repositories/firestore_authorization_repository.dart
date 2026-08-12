import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/authorized_user.dart';
import '../../domain/repositories/authorization_repository.dart';

class FirestoreAuthorizationRepository implements AuthorizationRepository {
  FirestoreAuthorizationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String rootOwnerEmail = 'sales.hitthedecksports@gmail.com';

  static const String _collectionName = 'authorized_users';

  final FirebaseFirestore _firestore;

  @override
  Future<AuthorizedUser?> getAuthorization(AuthUser user) async {
    final email = _normalizeEmail(user.email);

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

      return _authorizedUserFromData(email: email, data: data);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
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

  @override
  Stream<List<AuthorizedUser>> watchAuthorizedUsers() {
    try {
      return _firestore
          .collection(_collectionName)
          .orderBy('email')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((document) {
              return _authorizedUserFromData(
                email: document.id,
                data: document.data(),
              );
            }).toList();
          });
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  @override
  Future<void> addAuthorizedUser({required String email}) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail.isEmpty) {
      throw const ValidationException('An email address is required.');
    }

    if (normalizedEmail == rootOwnerEmail) {
      throw const ValidationException(
        'The owner account is already permanently authorized.',
      );
    }

    try {
      final reference = _firestore
          .collection(_collectionName)
          .doc(normalizedEmail);

      final existing = await reference.get();

      if (existing.exists) {
        throw const DuplicateException(
          'This user already has an access record.',
        );
      }

      await reference.set({
        'email': normalizedEmail,
        'role': 'user',
        'active': true,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': rootOwnerEmail,
      });
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  @override
  Future<void> disableAuthorizedUser(String email) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail == rootOwnerEmail) {
      throw const PermissionException('The owner account cannot be disabled.');
    }

    try {
      final reference = _firestore
          .collection(_collectionName)
          .doc(normalizedEmail);

      final existing = await reference.get();

      if (!existing.exists) {
        throw const NotFoundException('Authorized user not found.');
      }

      await reference.update({
        'active': false,
        'disabledAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  @override
  Future<void> restoreAuthorizedUser(String email) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail == rootOwnerEmail) {
      return;
    }

    try {
      final reference = _firestore
          .collection(_collectionName)
          .doc(normalizedEmail);

      final existing = await reference.get();

      if (!existing.exists) {
        throw const NotFoundException('Authorized user not found.');
      }

      await reference.update({
        'active': true,
        'restoredAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  AuthorizedUser _authorizedUserFromData({
    required String email,
    required Map<String, dynamic> data,
  }) {
    final active = data['active'];
    final role = data['role'];

    return AuthorizedUser(
      email: _normalizeEmail(email),
      role: _parseRole(role),
      active: active is bool ? active : false,
    );
  }

  AuthorizedUserRole _parseRole(Object? value) {
    switch (value) {
      case 'owner':
        return AuthorizedUserRole.owner;
      case 'admin':
        return AuthorizedUserRole.admin;
      case 'user':
      default:
        return AuthorizedUserRole.user;
    }
  }

  AppException _mapFirebaseException(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return PermissionException(
          'You do not have permission to manage user access.',
          cause: error,
        );

      case 'unavailable':
        return NetworkException(
          'Unable to reach Firebase. Check your internet connection.',
          cause: error,
        );

      case 'not-found':
        return NotFoundException(
          'The requested access record could not be found.',
          cause: error,
        );

      default:
        return UnexpectedException(
          'An error occurred while managing user access.',
          cause: error,
        );
    }
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}
