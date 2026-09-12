import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/repair_transaction.dart';
import 'providers/repair_transaction_controller.dart';
import 'providers/transaction_providers.dart';

class RepairDetailScreen extends ConsumerWidget {
  const RepairDetailScreen({required this.repairId, super.key});
  final String repairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(repairTransactionProvider(repairId));

    return async.when(
      loading: () => const AppPage(
        title: 'Repair Details',
        showHeader: false,
        compact: true,
        child: AppLoadingState(message: 'Loading repair details...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Repair Details',
        showHeader: false,
        compact: true,
        child: AppErrorState(
          message: 'Unable to load the repair.',
          details: error.toString(),
          onRetry: () => ref.invalidate(repairTransactionProvider(repairId)),
        ),
      ),
      data: (repair) => repair == null
          ? const AppPage(
              title: 'Repair Details',
              showHeader: false,
              compact: true,
              child: AppEmptyState(
                icon: Icons.build_circle_outlined,
                title: 'Repair not found.',
                message:
                    'The repair may have been removed or is no longer available.',
              ),
            )
          : _RepairBody(repair: repair),
    );
  }
}

class _RepairBody extends ConsumerWidget {
  const _RepairBody({required this.repair});
  final RepairTransaction repair;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Repair?'),
        content: const Text(
          'This permanently removes the repair record and reduces the item’s total repair cost and true cost.',
        ),
        actions: [
          TextButton(
            key: const Key('repairDeleteCancelButton'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('repairDeleteConfirmButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete Repair'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(repairTransactionControllerProvider.notifier)
          .deleteRepair(repair);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repair was deleted successfully.')),
      );
      context.goNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': repair.inventoryItemId},
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete repair: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemProvider(repair.inventoryItemId));
    final permissions = ref.watch(currentAppPermissionsProvider);
    final controller = ref.watch(repairTransactionControllerProvider);
    final deleting = controller.isLoading;

    return AppPage(
      title: 'Repair Details',
      showHeader: false,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          itemAsync.when(
            loading: () => const _LoadingCard(),
            error: (error, stackTrace) => const _MissingInventoryCard(),
            data: (item) => item == null
                ? const _MissingInventoryCard()
                : _RepairItemHero(item: item),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.build_outlined,
            title: 'Repair Details',
            children: [
              _Row(label: 'Repair Date', value: _date(repair.repairDate)),
              if (permissions.canViewFinancialData) ...[
                const Divider(),
                _Row(
                  label: 'Repair Cost',
                  value: CurrencyFormatter.formatCents(repair.costCents),
                ),
              ],
              const Divider(),
              _Row(label: 'Description', value: repair.description),
              if ((repair.notes ?? '').trim().isNotEmpty) ...[
                const Divider(),
                _Row(label: 'Notes', value: repair.notes!.trim()),
              ],
            ],
          ),
          if (permissions.canViewFinancialData) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('repairEditButton'),
                    onPressed: deleting || repair.id == null
                        ? null
                        : () => context.goNamed(
                            AppRouteNames.editRepair,
                            pathParameters: {'repairId': repair.id!},
                          ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Repair'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('repairDeleteButton'),
                    onPressed: deleting ? null : () => _delete(context, ref),
                    icon: deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(deleting ? 'Deleting...' : 'Delete Repair'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RepairItemHero extends StatelessWidget {
  const _RepairItemHero({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final model = item.model?.trim() ?? '';
    final name = model.isEmpty ? item.brand : '${item.brand} $model';
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        key: const Key('repairViewInventoryItemButton'),
        onTap: item.id == null
            ? null
            : () => context.goNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': item.id!},
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: Color(0xFF082A4A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.inventoryNumber ?? 'Inventory number not assigned',
                      style: const TextStyle(
                        color: Color(0xFF1174C2),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF082A4A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFF082A4A),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 9),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: Color(0xFF5F6D7E))),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: Color(0xFF082A4A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _MissingInventoryCard extends StatelessWidget {
  const _MissingInventoryCard();

  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'The inventory item linked to this repair is unavailable.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

String _date(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
