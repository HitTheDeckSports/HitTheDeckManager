import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import '../../transactions/domain/models/transaction_enums.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/inventory_item.dart';
import 'providers/inventory_controller.dart';
import 'providers/inventory_providers.dart';

class InventoryItemDetailScreen extends ConsumerWidget {
  const InventoryItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemProvider(itemId));

    return itemAsync.when(
      loading: () => const AppPage(
        title: 'Inventory Item',
        child: AppLoadingState(message: 'Loading inventory item...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Inventory Item',
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
            title: 'Inventory Item',
            child: AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Inventory item not found.',
              message:
                  'The item may have been removed or is no longer available.',
            ),
          );
        }

        return _InventoryItemDetailContent(item: item);
      },
    );
  }
}

class _InventoryItemDetailContent extends ConsumerWidget {
  const _InventoryItemDetailContent({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = item.model == null || item.model!.trim().isEmpty
        ? item.brand
        : '${item.brand} ${item.model}';
    final inventoryControllerState = ref.watch(inventoryControllerProvider);

    final isUpdatingStatus = inventoryControllerState.isLoading;
    return AppPage(
      title: displayName,
      subtitle: item.inventoryNumber ?? 'Inventory number not assigned',
      actions: [
        if (item.id != null)
          PopupMenuButton<InventoryStatus>(
            key: const Key('inventoryItemStatusButton'),
            enabled: !isUpdatingStatus,
            tooltip: 'Change inventory status',
            onSelected: (status) async {
              try {
                final updatedItem = await ref
                    .read(inventoryControllerProvider.notifier)
                    .updateStatus(item: item, status: status);

                ref.invalidate(inventoryItemProvider(updatedItem.id!));

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Inventory status changed to ${updatedItem.status.label}.',
                    ),
                  ),
                );
              } catch (error) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unable to change inventory status: $error'),
                  ),
                );
              }
            },
            itemBuilder: (context) {
              return [
                for (final status in const [
                  InventoryStatus.available,
                  InventoryStatus.inactive,
                  InventoryStatus.broken,
                ])
                  PopupMenuItem<InventoryStatus>(
                    value: status,
                    enabled: status != item.status,
                    child: Row(
                      children: [
                        Icon(
                          status == item.status
                              ? Icons.check
                              : Icons.circle_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(status.label),
                      ],
                    ),
                  ),
              ];
            },
            child: OutlinedButton.icon(
              onPressed: null,
              icon: isUpdatingStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(
                isUpdatingStatus ? 'Updating Status...' : 'Change Status',
              ),
            ),
          ),
        if (item.id != null)
          FilledButton.icon(
            key: const Key('inventoryItemEditButton'),
            onPressed: isUpdatingStatus
                ? null
                : () {
                    context.goNamed(
                      AppRouteNames.inventoryEdit,
                      pathParameters: {'itemId': item.id!},
                    );
                  },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailSection(
            title: 'Basic Information',
            children: [
              _DetailRow(
                label: 'Inventory Number',
                value: item.inventoryNumber ?? 'Not assigned',
              ),
              _DetailRow(label: 'Category', value: item.category.label),
              _DetailRow(label: 'Brand', value: item.brand),
              _DetailRow(
                label: 'Model',
                value: _displayOptionalText(item.model),
              ),
              _DetailRow(
                label: 'Acquisition Type',
                value: item.acquisitionType.label,
              ),
              _DetailRow(
                label: 'Condition',
                value: item.condition?.label ?? 'Not specified',
              ),
              _DetailRow(label: 'Status', value: item.status.label),
              _DetailRow(
                label: 'Purchase Date',
                value: item.purchaseDate == null
                    ? 'Not specified'
                    : _formatDate(item.purchaseDate!),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'Pricing',
            children: [
              _DetailRow(
                label: 'Acquisition Value',
                value: CurrencyFormatter.formatCents(
                  item.acquisitionValueCents,
                ),
              ),
              _DetailRow(
                label: 'New Value',
                value: _formatOptionalMoney(item.newValueCents),
              ),
              _DetailRow(
                label: 'Asking Price',
                value: _formatOptionalMoney(item.askingPriceCents),
              ),
              _DetailRow(
                label: 'Minimum Acceptable Price',
                value: _formatOptionalMoney(item.minimumPriceCents),
              ),
            ],
          ),
          if (item.status == InventoryStatus.sold && item.id != null) ...[
            const SizedBox(height: 24),
            _SaleInformationSection(inventoryItemId: item.id!),
          ],
          const SizedBox(height: 24),
          _DetailSection(
            title: 'Item Details',
            children: [
              ..._categorySpecificRows(item),
              _DetailRow(
                label: 'Notes',
                value: _displayOptionalText(item.notes),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleInformationSection extends ConsumerWidget {
  const _SaleInformationSection({required this.inventoryItemId});

  final String inventoryItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleForInventoryItemProvider(inventoryItemId));

    return saleAsync.when(
      loading: () => const _DetailSection(
        title: 'Sale Information',
        children: [AppLoadingState(message: 'Loading sale information...')],
      ),
      error: (error, stackTrace) => _DetailSection(
        title: 'Sale Information',
        children: [
          AppErrorState(
            message: 'Unable to load sale information.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(saleForInventoryItemProvider(inventoryItemId));
            },
          ),
        ],
      ),
      data: (sale) {
        if (sale == null) {
          return const _DetailSection(
            title: 'Sale Information',
            children: [
              Text(
                'This item is marked Sold, but no matching sale transaction was found.',
              ),
            ],
          );
        }

        return _SaleInformationCardContent(sale: sale);
      },
    );
  }
}

class _SaleInformationCardContent extends StatelessWidget {
  const _SaleInformationCardContent({required this.sale});

  final SaleTransaction sale;

  @override
  Widget build(BuildContext context) {
    final acquisitionValue = sale.acquisitionValueCents;
    final profit = sale.profitCents;

    return _DetailSection(
      title: 'Sale Information',
      children: [
        _DetailRow(label: 'Sale Date', value: _formatDate(sale.saleDate)),
        _DetailRow(label: 'Payment Method', value: sale.paymentMethod.label),
        _DetailRow(
          label: 'Sale Price',
          value: CurrencyFormatter.formatCents(sale.salePriceCents),
        ),
        _DetailRow(
          label: 'Cost at Time of Sale',
          value: acquisitionValue == null
              ? 'Not available'
              : CurrencyFormatter.formatCents(acquisitionValue),
        ),
        _DetailRow(
          label: 'Profit',
          value: profit == null
              ? 'Not available'
              : CurrencyFormatter.formatCents(profit),
        ),
        _DetailRow(
          label: 'Gross Margin',
          value: sale.grossMargin == null
              ? 'Not available'
              : '${(sale.grossMargin! * 100).toStringAsFixed(1)}%',
        ),
        if (sale.notes != null && sale.notes!.trim().isNotEmpty)
          _DetailRow(label: 'Sale Notes', value: sale.notes!),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('inventoryItemViewTransactionButton'),
            onPressed: sale.id == null
                ? null
                : () {
                    context.goNamed(
                      AppRouteNames.transactionDetail,
                      pathParameters: {'transactionId': sale.id!},
                    );
                  },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View Transaction'),
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

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
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
            width: 190,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

List<Widget> _categorySpecificRows(InventoryItem item) {
  return switch (item.category) {
    InventoryCategory.bat => [
      _DetailRow(
        label: 'Bat Length',
        value: _formatOptionalMeasurement(item.lengthInches, 'in'),
      ),
      _DetailRow(
        label: 'Bat Weight',
        value: _formatOptionalMeasurement(item.weightOunces, 'oz'),
      ),
      _DetailRow(
        label: 'Drop',
        value: item.drop == null ? 'Not specified' : _formatNumber(item.drop!),
      ),
      _DetailRow(
        label: 'Certification',
        value: _displayOptionalText(item.certification),
      ),
    ],
    InventoryCategory.glove => [
      _DetailRow(
        label: 'Glove Size',
        value: _formatOptionalMeasurement(item.gloveSizeInches, 'in'),
      ),
      _DetailRow(
        label: 'Hand Orientation',
        value: _displayOptionalText(item.handOrientation),
      ),
    ],
    InventoryCategory.catchersGear => [
      _DetailRow(
        label: "Catcher’s Gear Size",
        value: _displayOptionalText(item.catchersGearSize),
      ),
    ],
    InventoryCategory.helmet || InventoryCategory.other => const [],
  };
}

String _displayOptionalText(String? value) {
  final trimmedValue = value?.trim() ?? '';

  return trimmedValue.isEmpty ? 'Not specified' : trimmedValue;
}

String _formatOptionalMoney(int? cents) {
  return cents == null ? 'Not specified' : CurrencyFormatter.formatCents(cents);
}

String _formatOptionalMeasurement(double? value, String unit) {
  return value == null ? 'Not specified' : '${_formatNumber(value)} $unit';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$month/$day/${date.year}';
}
