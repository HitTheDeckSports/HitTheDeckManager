import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/contact.dart';
import 'contact_providers.dart';

final contactControllerProvider =
    AsyncNotifierProvider<ContactController, void>(ContactController.new);

class ContactController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Contact> createContact(Contact contact) async {
    state = const AsyncLoading();

    final repository = ref.read(contactRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.createContact(contact),
    );

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

  Future<Contact> updateContact(Contact contact) async {
    state = const AsyncLoading();

    final repository = ref.read(contactRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.updateContact(contact),
    );

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

  Future<void> deleteContact(String id) async {
    state = const AsyncLoading();

    final repository = ref.read(contactRepositoryProvider);

    final result = await AsyncValue.guard(() => repository.deleteContact(id));

    state = result;

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
