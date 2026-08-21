import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as desktop_google;
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/authentication_repository.dart';

/// Firebase-backed implementation of [AuthenticationRepository].
///
/// Firebase-specific user and credential types remain inside the data layer so
/// the rest of the application can work entirely with domain models.
class FirebaseAuthenticationRepository implements AuthenticationRepository {
  FirebaseAuthenticationRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  static const String _windowsClientId = String.fromEnvironment(
    'GOOGLE_WINDOWS_CLIENT_ID',
  );
  static const String _windowsClientSecret = String.fromEnvironment(
    'GOOGLE_WINDOWS_CLIENT_SECRET',
  );
  Future<void>? _googleInitialization;
  desktop_google.GoogleSignIn? _windowsGoogleSignIn;
  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AuthUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final UserCredential credential;

      if (kIsWeb) {
        credential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        credential = await _signInWithGoogleOnWindows();
      } else {
        await _ensureGoogleSignInInitialized();

        final googleAccount = await _googleSignIn.authenticate();
        final googleAuthentication = googleAccount.authentication;
        final idToken = googleAuthentication.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw const UnexpectedException(
            'Google sign-in did not return an ID token.',
          );
        }

        final firebaseCredential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        credential = await _firebaseAuth.signInWithCredential(
          firebaseCredential,
        );
      }

      final user = _mapFirebaseUser(credential.user);

      if (user == null) {
        throw const UnexpectedException(
          'Firebase did not return an authenticated user.',
        );
      }

      return user;
    } on GoogleSignInException catch (error) {
      throw _mapGoogleSignInException(error);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    } on AppException {
      rethrow;
    } catch (error) {
      throw UnexpectedException(
        'An unexpected authentication error occurred.',
        cause: error,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        await _windowsGoogleSignIn?.signOut();
      } else if (!kIsWeb) {
        await _ensureGoogleSignInInitialized();
        await _googleSignIn.signOut();
      }
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    } on GoogleSignInException catch (error) {
      throw _mapGoogleSignInException(error);
    } catch (error) {
      throw UnexpectedException('Unable to sign out.', cause: error);
    }
  }

  Future<UserCredential> _signInWithGoogleOnWindows() async {
    if (_windowsClientId.isEmpty || _windowsClientSecret.isEmpty) {
      throw const UnexpectedException(
        'Windows Google sign-in credentials are not configured.',
      );
    }

    final windowsGoogleSignIn = _windowsGoogleSignIn ??=
        desktop_google.GoogleSignIn(
          params: const desktop_google.GoogleSignInParams(
            clientId: _windowsClientId,
            clientSecret: _windowsClientSecret,
            redirectPort: 8000,
            scopes: ['openid', 'profile', 'email'],
          ),
        );

    final googleCredentials = await windowsGoogleSignIn.signInOnline();

    if (googleCredentials == null) {
      throw const UnexpectedException('Google sign-in was canceled.');
    }

    final idToken = googleCredentials.idToken;
    final accessToken = googleCredentials.accessToken;

    if ((idToken == null || idToken.isEmpty) && accessToken.isEmpty) {
      throw const UnexpectedException(
        'Google sign-in did not return usable credentials.',
      );
    }

    final firebaseCredential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    return _firebaseAuth.signInWithCredential(firebaseCredential);
  }

  /// Initializes the google_sign_in singleton exactly once.
  ///
  /// Version 7.x requires initialization before calling authentication methods.
  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw const UnexpectedException(
        'The authenticated account does not have an email address.',
      );
    }

    return AuthUser(
      id: user.uid,
      email: email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  AppException _mapGoogleSignInException(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return UnexpectedException(
          'Google sign-in was canceled.',
          cause: error,
        );

      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return UnexpectedException(
          'Google sign-in is not configured correctly.',
          cause: error,
        );

      case GoogleSignInExceptionCode.uiUnavailable:
        return UnexpectedException(
          'Google sign-in is temporarily unavailable.',
          cause: error,
        );

      case GoogleSignInExceptionCode.interrupted:
        return NetworkException(
          'Google sign-in was interrupted. Please try again.',
          cause: error,
        );

      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return UnexpectedException(
          'Google sign-in could not be completed.',
          cause: error,
        );
    }
  }

  AppException _mapFirebaseAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return NetworkException(
          'Unable to connect to Firebase. Check your internet connection.',
          cause: error,
        );

      case 'operation-not-allowed':
        return PermissionException(
          'Google authentication is not enabled for this application.',
          cause: error,
        );

      case 'user-disabled':
        return PermissionException(
          'This account has been disabled.',
          cause: error,
        );

      case 'account-exists-with-different-credential':
        return PermissionException(
          'An account already exists with this email using another sign-in method.',
          cause: error,
        );

      default:
        return UnexpectedException(
          error.message ?? 'Firebase authentication failed.',
          cause: error,
        );
    }
  }
}
