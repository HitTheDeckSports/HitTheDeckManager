import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import 'authorization_providers.dart';
import '../../domain/models/auth_user.dart';
import 'authentication_providers.dart';

/// Coordinates interactive authentication actions.
///
/// Long-lived authentication state comes from [authStateProvider]. This
/// controller only represents the loading/error state of sign-in and sign-out
/// operations initiated by the user.
final authenticationControllerProvider =
    AsyncNotifierProvider<AuthenticationController, void>(
      AuthenticationController.new,
    );

class AuthenticationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Starts Google authentication and returns the authenticated domain user.
  /// Authenticates the Google account and then verifies application access.
  ///
  /// Successfully authenticating with Google does not automatically grant
  /// permission to use Hit the Deck Manager. Non-authorized accounts are signed
  /// back out immediately.
  Future<AuthUser> signInWithGoogle() async {
    state = const AsyncLoading();

    final authenticationRepository = ref.read(authenticationRepositoryProvider);
    final authorizationRepository = ref.read(authorizationRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final user = await authenticationRepository.signInWithGoogle();

      final authorization = await authorizationRepository.getAuthorization(
        user,
      );

      if (authorization == null || !authorization.active) {
        await authenticationRepository.signOut();

        throw const PermissionException(
          'This Google account is not authorized to access Hit the Deck Manager.',
        );
      }

      return user;
    });

    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }

    return result.requireValue;
  }

  /// Ends the Firebase and Google authentication sessions.
  Future<void> signOut() async {
    state = const AsyncLoading();

    final repository = ref.read(authenticationRepositoryProvider);

    final result = await AsyncValue.guard(repository.signOut);

    state = result;

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
