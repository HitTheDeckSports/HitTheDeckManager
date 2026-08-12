import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'authorization_providers.dart';

final userAccessControllerProvider =
    AsyncNotifierProvider<UserAccessController, void>(UserAccessController.new);

class UserAccessController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addUser(String email) async {
    state = const AsyncLoading();

    final repository = ref.read(authorizationRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.addAuthorizedUser(email: email),
    );

    state = result;

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }

  Future<void> disableUser(String email) async {
    state = const AsyncLoading();

    final repository = ref.read(authorizationRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.disableAuthorizedUser(email),
    );

    state = result;

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }

  Future<void> restoreUser(String email) async {
    state = const AsyncLoading();

    final repository = ref.read(authorizationRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.restoreAuthorizedUser(email),
    );

    state = result;

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
