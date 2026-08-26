import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../domain/models/repair_transaction.dart';
import 'providers/repair_transaction_controller.dart';
import 'providers/transaction_providers.dart';

class RepairDetailScreen extends ConsumerWidget {
  const RepairDetailScreen({required this.repairId, super.key});

  final String repairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repairAsync = ref.watch(repairTransactionProvider(repairId));

    return repairAsync.when(
      loading: () => const AppPage(
        title: 'Repair Details',
        child: AppLoadingState(message: 'Loading repair details...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Repair Details',
        child: AppErrorState(
          message: 'Unable to load the repair.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(repairTransactionProvider(repairId));
          },
        ),
      ),
      data: (repair) {
        if (repair == null) {
          return const AppPage(
            title: 'Repair Details',
            child: AppEmptyState(
              icon: Icons.build_circle_outlined,
              title: 'Repair not found.',
              message:
                  'The repair may have been removed or is no longer available.',
            ),
          );
        }

        return _RepairDetailContent(repair: repair);
      },
    );
  }
}

class _RepairDetailContent extends ConsumerWidget {
  const _RepairDetailContent({required this.repair});

  final RepairTransaction repair;

  Future<void> _deleteRepair(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Repair?'),
          content: const Text(
            'This permanently removes the repair record and reduces the item’s total repair cost and true cost.',
          ),
          actions: [
            TextButton(
              key: const Key('repairDeleteCancelButton'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('repairDeleteConfirmButton'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete Repair'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(repairTransactionControllerProvider.notifier)
          .deleteRepair(repair);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repair was deleted successfully.')),
      );

      context.goNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': repair.inventoryItemId},
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete repair: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryItemAsync = ref.watch(
      inventoryItemProvider(repair.inventoryItemId),
    );

    final controllerState = ref.watch(repairTransactionControllerProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);

    final isDeleting = controllerState.isLoading;

    return AppPage(
      title: 'Repair Details',
      subtitle: _formatDate(repair.repairDate),
      actions: permissions.canViewFinancialData
          ? [
              OutlinedButton.icon(
                key: const Key('repairEditButton'),
                onPressed: isDeleting
                    ? null
                    : () {
                        context.goNamed(
                          AppRouteNames.editRepair,
                          pathParameters: {'repairId': repair.id!},
                        );
                      },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Repair'),
              ),
              FilledButton.icon(
                key: const Key('repairDeleteButton'),
                onPressed: isDeleting
                    ? null
                    : () {
                        _deleteRepair(context, ref);
                      },
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(
                  isDeleting ? 'Deleting Repair...' : 'Delete Repair',
                ),
              ),
            ]
          : const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RepairDetailSection(
            title: 'Repair Information',
            children: [
              _RepairDetailRow(
                label: 'Repair Date',
                value: _formatDate(repair.repairDate),
              ),
              if (permissions.canViewFinancialData)
                _RepairDetailRow(
                  label: 'Repair Cost',
                  value: CurrencyFormatter.formatCents(repair.costCents),
                ),
              _RepairDetailRow(label: 'Description', value: repair.description),
              _RepairDetailRow(
                label: 'Notes',
                value: _displayOptionalText(repair.notes),
              ),
            ],
          ),
          const SizedBox(height: 24),
          inventoryItemAsync.when(
            loading: () => const _RepairDetailSection(
              title: 'Inventory Item',
              children: [AppLoadingState(message: 'Loading inventory item...')],
            ),
            error: (error, stackTrace) => _RepairDetailSection(
              title: 'Inventory Item',
              children: [
                AppErrorState(
                  message: 'Unable to load the inventory item.',
                  details: error.toString(),
                  onRetry: () {
                    ref.invalidate(
                      inventoryItemProvider(repair.inventoryItemId),
                    );
                  },
                ),
              ],
            ),
            data: (item) {
              if (item == null) {
                return const _RepairDetailSection(
                  title: 'Inventory Item',
                  children: [
                    Text(
                      'The inventory item linked to this repair is unavailable.',
                    ),
                  ],
                );
              }

              return _RepairInventoryItemSection(item: item);
            },
          ),
        ],
      ),
    );
  }
}

class _RepairInventoryItemSection extends StatelessWidget {
  const _RepairInventoryItemSection({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final itemId = item.id;

    final model = item.model?.trim();

    final displayName = model == null || model.isEmpty
        ? item.brand
        : '${item.brand} $model';

    return _RepairDetailSection(
      title: 'Inventory Item',
      children: [
        _RepairDetailRow(
          label: 'Inventory Number',
          value: item.inventoryNumber ?? 'Not assigned',
        ),
        _RepairDetailRow(label: 'Item', value: displayName),
        if (itemId != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('repairViewInventoryItemButton'),
              onPressed: () {
                context.goNamed(
                  AppRouteNames.inventoryDetail,
                  pathParameters: {'itemId': itemId},
                );
              },
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('View Inventory Item'),
            ),
          ),
        ],
      ],
    );
  }
}

class _RepairDetailSection extends StatelessWidget {
  const _RepairDetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RepairDetailRow extends StatelessWidget {
  const _RepairDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month/$day/${date.year}';
}

String _displayOptionalText(String? value) {
  final trimmedValue = value?.trim() ?? '';

  return trimmedValue.isEmpty ? 'Not specified' : trimmedValue;
}
