import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../domain/models/inventory_enums.dart';
import 'providers/inventory_providers.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../app/app_routes.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return AppPage(
      title: 'Inventory',
      subtitle: 'Review and manage available, sold, and inactive equipment.',
      actions: [
        FilledButton.icon(
          key: const Key('inventoryScanQrButton'),
          onPressed: () {
            context.goNamed(AppRouteNames.inventoryScanner);
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR'),
        ),
      ],
      child: inventoryAsync.when(
        loading: () => const AppLoadingState(message: 'Loading inventory...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load inventory.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(inventoryItemsProvider);
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No inventory items yet.',
              message: 'Use Buy Inventory to add your first item.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${items.length} inventory item${items.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final item in items)
                Card(
                  child: ListTile(
                    key: ValueKey('inventoryItemTile-${item.id}'),
                    onTap: item.id == null
                        ? null
                        : () {
                            context.goNamed(
                              AppRouteNames.inventoryDetail,
                              pathParameters: {'itemId': item.id!},
                            );
                          },
                    leading: const Icon(Icons.sports_baseball),
                    title: Text(
                      item.model == null || item.model!.trim().isEmpty
                          ? item.brand
                          : '${item.brand} ${item.model}',
                    ),
                    subtitle: Text(
                      '${item.category.label} • '
                      '${item.inventoryNumber ?? 'Not assigned'}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.askingPriceCents == null
                              ? 'No asking price'
                              : CurrencyFormatter.formatCents(
                                  item.askingPriceCents!,
                                ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cost: ${CurrencyFormatter.formatCents(item.acquisitionValueCents)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
