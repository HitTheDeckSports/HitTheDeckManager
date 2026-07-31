import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/inventory_item.dart';
import 'inventory_providers.dart';

final inventoryControllerProvider =
    AsyncNotifierProvider<InventoryController, void>(InventoryController.new);

class InventoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<InventoryItem> createItem(InventoryItem item) async {
    state = const AsyncLoading();

    final repository = ref.read(inventoryRepositoryProvider);

    final savedItem = await AsyncValue.guard(
      () => repository.createInventoryItem(item),
    );

    state = savedItem.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );

    if (savedItem.hasError) {
      Error.throwWithStackTrace(savedItem.error!, savedItem.stackTrace!);
    }

    return savedItem.requireValue;
  }

  Future<InventoryItem> updateItem(InventoryItem item) async {
    state = const AsyncLoading();

    final repository = ref.read(inventoryRepositoryProvider);

    final updatedItem = await AsyncValue.guard(
      () => repository.updateInventoryItem(item),
    );

    state = updatedItem.when(
      data: (_) => const AsyncData(null),
      error: AsyncError.new,
      loading: () => const AsyncLoading(),
    );

    if (updatedItem.hasError) {
      Error.throwWithStackTrace(updatedItem.error!, updatedItem.stackTrace!);
    }

    return updatedItem.requireValue;
  }

  Future<void> deleteItem(String id) async {
    state = const AsyncLoading();

    final repository = ref.read(inventoryRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.deleteInventoryItem(id),
    );

    state = result;

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
