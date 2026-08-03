import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import 'buy_inventory_screen.dart';
import 'providers/inventory_providers.dart';

class EditInventoryScreen extends ConsumerWidget {
  const EditInventoryScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemProvider(itemId));

    return itemAsync.when(
      loading: () => const AppPage(
        title: 'Edit Inventory',
        child: AppLoadingState(message: 'Loading inventory item...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Edit Inventory',
        child: AppErrorState(
          message: 'Unable to load inventory item.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(inventoryItemProvider(itemId));
          },
        ),
      ),
      data: (item) {
        if (item == null) {
          return const AppPage(
            title: 'Edit Inventory',
            child: AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Inventory item not found.',
              message:
                  'The item may have been removed or is no longer available.',
            ),
          );
        }

        return BuyInventoryScreen(existingItem: item);
      },
    );
  }
}
