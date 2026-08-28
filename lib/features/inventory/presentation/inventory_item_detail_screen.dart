import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../contacts/presentation/providers/contact_providers.dart';
import '../../transactions/domain/models/consignment_transaction.dart';
import '../../transactions/domain/models/disposal_reason.dart';
import '../../transactions/domain/models/disposal_transaction.dart';
import '../../transactions/domain/models/repair_transaction.dart';
import '../../transactions/domain/models/sale_transaction.dart';
import '../../transactions/domain/models/trade_transaction.dart';
import '../../transactions/domain/models/transaction_enums.dart';
import '../../transactions/presentation/providers/deal_providers.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../../transactions/presentation/providers/warranty_replacement_providers.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/inventory_item.dart';
import 'providers/inventory_controller.dart';
import 'providers/inventory_location_providers.dart';
import 'providers/inventory_providers.dart';
import '../application/labels/inventory_label_data.dart';
import '../application/labels/inventory_label_pdf_generator.dart';
import '../application/labels/inventory_label_template.dart';
import '../application/qr/inventory_qr_codec.dart';

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
    final permissions = ref.watch(currentAppPermissionsProvider);
    final locationsAsync = ref.watch(inventoryLocationsProvider);

    final locationLabel = item.locationId == null
        ? 'Unassigned'
        : locationsAsync.maybeWhen(
            data: (locations) {
              for (final location in locations) {
                if (location.id == item.locationId) {
                  return location.active
                      ? location.name
                      : '${location.name} (Inactive)';
                }
              }
              return 'Unknown Location';
            },
            orElse: () => 'Loading...',
          );

    final isUpdatingStatus = inventoryControllerState.isLoading;

    return AppPage(
      title: 'Inventory Item',
      showHeader: false,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InventoryDetailHeader(
            item: item,
            displayName: displayName,
            isUpdatingStatus: isUpdatingStatus,
          ),
          const SizedBox(height: 12),
          _InventoryPhotosSection(item: item),
          const SizedBox(height: 12),
          _InventorySummarySection(
            item: item,
            canViewFinancialData: permissions.canViewFinancialData,
          ),
          const SizedBox(height: 12),
          _InventoryQuickInfoGrid(
            item: item,
            locationLabel: locationLabel,
            canViewFinancialData: permissions.canViewFinancialData,
          ),
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Notes',
              children: [_DetailRow(label: 'Notes', value: item.notes!.trim())],
            ),
          ],
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Additional Pricing',
            children: [
              _DetailRow(
                label: 'New Value',
                value: _formatOptionalMoney(item.newValueCents),
              ),
              _DetailRow(
                label: 'Minimum Acceptable Price',
                value: _formatOptionalMoney(item.minimumPriceCents),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SellerInformationSection(sellerContactId: item.sellerContactId),
          if (item.acquisitionType == AcquisitionType.consignment &&
              item.id != null) ...[
            const SizedBox(height: 16),
            _ConsignmentSection(item: item),
          ],
          if (item.id != null) ...[
            const SizedBox(height: 16),
            _RepairHistorySection(
              inventoryItemId: item.id!,
              acquisitionValueCents: item.acquisitionValueCents,
              canViewFinancialData: permissions.canViewFinancialData,
            ),
            const SizedBox(height: 16),
            _DisposalHistorySection(inventoryItemId: item.id!),
          ],
          if (item.status == InventoryStatus.sold && item.id != null) ...[
            const SizedBox(height: 16),
            _SaleInformationSection(
              inventoryItemId: item.id!,
              canViewFinancialData: permissions.canViewFinancialData,
            ),
          ],
          if (item.id != null) ...[
            const SizedBox(height: 16),
            _TradeHistorySection(
              inventoryItemId: item.id!,
              canViewFinancialData: permissions.canViewFinancialData,
            ),
            const SizedBox(height: 16),
            _InventoryDealSection(
              inventoryItemId: item.id!,
              status: item.status,
            ),
          ],
          const SizedBox(height: 18),
          _InventoryPrimaryActions(
            item: item,
            canDisposeInventory: permissions.canDisposeInventory,
            isUpdatingStatus: isUpdatingStatus,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _InventoryDetailHeader extends StatelessWidget {
  const _InventoryDetailHeader({
    required this.item,
    required this.displayName,
    required this.isUpdatingStatus,
  });

  final InventoryItem item;
  final String displayName;
  final bool isUpdatingStatus;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('inventoryDetailActionHeader'),
      children: [
        TextButton.icon(
          key: const Key('inventoryItemBackButton'),
          onPressed: () => context.goNamed(AppRouteNames.inventory),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
        const Spacer(),
        Flexible(
          flex: 3,
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        if (item.id != null)
          TextButton.icon(
            key: const Key('inventoryItemEditButton'),
            onPressed: isUpdatingStatus
                ? null
                : () {
                    context.goNamed(
                      AppRouteNames.inventoryEdit,
                      pathParameters: {'itemId': item.id!},
                    );
                  },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
      ],
    );
  }
}

class _InventoryQuickInfoGrid extends StatelessWidget {
  const _InventoryQuickInfoGrid({
    required this.item,
    required this.locationLabel,
    required this.canViewFinancialData,
  });

  final InventoryItem item;
  final String locationLabel;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final cells = <_QuickInfoData>[
      _QuickInfoData('Category', item.category.label),
      _QuickInfoData('Brand', item.brand),
      _QuickInfoData('Model', _displayOptionalText(item.model)),
      _QuickInfoData('Condition', item.condition?.label ?? 'Not specified'),
      _QuickInfoData(
        'Purchased',
        item.purchaseDate == null
            ? 'Not specified'
            : _formatDate(item.purchaseDate!),
      ),
      if (canViewFinancialData)
        _QuickInfoData(
          'Cost',
          CurrencyFormatter.formatCents(item.acquisitionValueCents),
        )
      else
        const _QuickInfoData('Cost', 'Restricted'),
      _QuickInfoData('Location', locationLabel),
      _QuickInfoData('Acquisition', item.acquisitionType.label),
      const _QuickInfoData('QR Code', 'View / Print'),
    ];

    return Card(
      key: const Key('inventoryItemQuickInfoGrid'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final columns = constraints.maxWidth >= 700 ? 3 : 3;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final cell in cells)
                  SizedBox(
                    width: width,
                    child: _QuickInfoCell(data: cell),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickInfoData {
  const _QuickInfoData(this.label, this.value);

  final String label;
  final String value;
}

class _QuickInfoCell extends StatelessWidget {
  const _QuickInfoCell({required this.data});

  final _QuickInfoData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label.toUpperCase(),
            key: ValueKey('inventoryQuickInfoLabel-${data.label}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            key: ValueKey('inventoryQuickInfoValue-${data.label}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InventorySummarySection extends ConsumerWidget {
  const _InventorySummarySection({
    required this.item,
    required this.canViewFinancialData,
  });

  final InventoryItem item;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = item.model == null || item.model!.trim().isEmpty
        ? item.brand
        : '${item.brand} ${item.model}';
    final itemId = item.id;
    final repairsAsync = itemId == null
        ? const AsyncValue<List<RepairTransaction>>.data([])
        : ref.watch(repairsForInventoryItemProvider(itemId));
    final totalRepairCostCents = repairsAsync.maybeWhen<int?>(
      data: (repairs) =>
          repairs.fold<int>(0, (total, repair) => total + repair.costCents),
      orElse: () => null,
    );
    final totalCostCents = totalRepairCostCents == null
        ? null
        : item.acquisitionValueCents + totalRepairCostCents;
    final estimatedProfitCents =
        totalCostCents == null || item.askingPriceCents == null
        ? null
        : item.askingPriceCents! - totalCostCents;
    final specifications = _compactItemSpecifications(item);
    final categoryColor = _inventoryCategoryColor(item.category);
    final ageText = _inventoryAgeLabel(item);

    return Card(
      key: const Key('inventoryItemSummaryCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          item.inventoryNumber ?? 'Not assigned',
                          key: const Key('inventoryItemSummaryNumber'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    key: const Key('inventoryItemSummaryName'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (specifications != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      specifications,
                      key: const Key('inventoryItemSummarySpecs'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item.condition != null)
                        Container(
                          key: const Key('inventoryItemConditionPill'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.condition!.label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      Text(
                        ageText,
                        key: const Key('inventoryItemAgeLabel'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCompactPrice(item.askingPriceCents),
                    key: const Key('inventoryItemAskingPrice'),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (canViewFinancialData && estimatedProfitCents != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatProfit(estimatedProfitCents),
                      key: const Key('inventoryItemEstimatedProfitMetric'),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: estimatedProfitCents >= 0
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryPrimaryActions extends ConsumerWidget {
  const _InventoryPrimaryActions({
    required this.item,
    required this.canDisposeInventory,
    required this.isUpdatingStatus,
  });

  final InventoryItem item;
  final bool canDisposeInventory;
  final bool isUpdatingStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      key: const Key('inventoryItemPrimaryActions'),
      spacing: 12,
      runSpacing: 12,
      children: [
        if (item.id != null && item.status == InventoryStatus.available)
          FilledButton.icon(
            key: const Key('inventoryItemSellButton'),
            onPressed: isUpdatingStatus
                ? null
                : () {
                    context.goNamed(AppRouteNames.sellInventory, extra: item);
                  },
            icon: const Icon(Icons.sell_outlined),
            label: const Text('Sell Item'),
          ),
        if (item.id != null && item.status != InventoryStatus.disposed)
          OutlinedButton.icon(
            key: const Key('inventoryItemAddRepairButton'),
            onPressed: isUpdatingStatus
                ? null
                : () {
                    context.goNamed(
                      AppRouteNames.addRepair,
                      pathParameters: {'itemId': item.id!},
                    );
                  },
            icon: const Icon(Icons.build_outlined),
            label: const Text('Add Repair'),
          ),
        if (item.id != null)
          OutlinedButton.icon(
            key: const Key('inventoryItemQrButton'),
            onPressed: isUpdatingStatus
                ? null
                : () {
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return _InventoryQrDialog(item: item);
                      },
                    );
                  },
            icon: const Icon(Icons.qr_code),
            label: const Text('View / Print QR'),
          ),
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
        if (canDisposeInventory &&
            item.id != null &&
            item.status != InventoryStatus.sold &&
            item.status != InventoryStatus.disposed)
          OutlinedButton.icon(
            key: const Key('inventoryItemDisposeButton'),
            onPressed: isUpdatingStatus
                ? null
                : () {
                    context.goNamed(
                      AppRouteNames.disposeInventory,
                      pathParameters: {'itemId': item.id!},
                    );
                  },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Dispose'),
          ),
      ],
    );
  }
}

class _InventoryQrDialog extends StatelessWidget {
  const _InventoryQrDialog({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final itemId = item.id;
    final displayName = item.model == null || item.model!.trim().isEmpty
        ? item.brand
        : '${item.brand} ${item.model}';

    if (itemId == null) {
      return const SizedBox.shrink();
    }

    final qrValue = InventoryQrCodec.encodeInventoryItemId(itemId);

    return AlertDialog(
      key: const Key('inventoryQrDialog'),
      title: const Text('Inventory QR Code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Inventory QR code',
              image: true,
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: QrImageView(
                    key: const Key('inventoryQrCode'),
                    data: qrValue,
                    version: QrVersions.auto,
                    size: 220,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.inventoryNumber ?? 'Inventory number not assigned',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(displayName, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Scan this code to open this inventory item.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventoryQrCloseButton'),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        FilledButton.icon(
          key: const Key('inventoryPrintLabelButton'),
          onPressed: () async {
            final startingPosition = await showDialog<int>(
              context: context,
              builder: (context) {
                return const _InventoryLabelPositionDialog();
              },
            );

            if (startingPosition == null || !context.mounted) {
              return;
            }

            final label = InventoryLabelData.fromInventoryItem(item);

            await Printing.layoutPdf(
              name: '${label.inventoryNumber}-label.pdf',
              onLayout: (_) {
                return InventoryLabelPdfGenerator.generateSingleLabelSheet(
                  label: label,
                  template: InventoryLabelTemplate.avery5366,
                  startingPosition: startingPosition,
                );
              },
            );
          },
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print Label'),
        ),
      ],
    );
  }
}

class _InventoryLabelPositionDialog extends StatefulWidget {
  const _InventoryLabelPositionDialog();

  @override
  State<_InventoryLabelPositionDialog> createState() =>
      _InventoryLabelPositionDialogState();
}

class _InventoryLabelPositionDialogState
    extends State<_InventoryLabelPositionDialog> {
  int _startingPosition = 1;

  @override
  Widget build(BuildContext context) {
    const template = InventoryLabelTemplate.avery5366;

    return AlertDialog(
      key: const Key('inventoryLabelPositionDialog'),
      title: const Text('Choose Label Position'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select the first unused label position on the Avery 5366 sheet.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: const Key('inventoryLabelPositionField'),
            initialValue: _startingPosition,
            decoration: const InputDecoration(
              labelText: 'Starting Position',
              border: OutlineInputBorder(),
            ),
            items: [
              for (
                var position = 1;
                position <= template.labelsPerSheet;
                position++
              )
                DropdownMenuItem<int>(
                  value: position,
                  child: Text('Position $position'),
                ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _startingPosition = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Text('Avery 5366 has ${template.labelsPerSheet} labels per sheet.'),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('inventoryLabelPositionCancelButton'),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('inventoryLabelPositionContinueButton'),
          onPressed: () {
            Navigator.of(context).pop(_startingPosition);
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _InventoryPhotosSection extends StatelessWidget {
  const _InventoryPhotosSection({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final photoUrls = item.photoUrls;

    return _DetailSection(
      title: 'Photos',
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: photoUrls.isEmpty
                    ? ColoredBox(
                        key: const Key('inventoryPrimaryPhotoPlaceholder'),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 52,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Image.network(
                        photoUrls.first,
                        key: const Key('inventoryPrimaryPhoto'),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: Color(0xFFE0E0E0),
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _InventoryStatusBadge(status: item.status),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_camera_outlined,
                        size: 17,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        photoUrls.length.toString(),
                        key: const Key('inventoryPhotoCountLabel'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (photoUrls.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length - 1,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photoIndex = index + 1;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Image.network(
                      photoUrls[photoIndex],
                      key: Key('inventoryPhotoThumbnail-$photoIndex'),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFFE0E0E0),
                          child: Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _InventoryStatusBadge extends StatelessWidget {
  const _InventoryStatusBadge({required this.status});

  final InventoryStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      InventoryStatus.available => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      InventoryStatus.sold => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      InventoryStatus.inactive => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      InventoryStatus.broken => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      InventoryStatus.disposed => (
        colorScheme.surfaceContainerHigh,
        colorScheme.onSurface,
      ),
    };

    return DecoratedBox(
      key: const Key('inventoryItemStatusBadge'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          status.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ConsignmentSection extends ConsumerWidget {
  const _ConsignmentSection({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemId = item.id!;
    final consignmentAsync = ref.watch(
      consignmentForInventoryItemProvider(itemId),
    );

    return consignmentAsync.when(
      loading: () => const _DetailSection(
        title: 'Consignment',
        children: [
          AppLoadingState(message: 'Loading consignment agreement...'),
        ],
      ),
      error: (error, stackTrace) => _DetailSection(
        title: 'Consignment',
        children: [
          AppErrorState(
            message: 'Unable to load consignment agreement.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(consignmentForInventoryItemProvider(itemId));
            },
          ),
        ],
      ),
      data: (consignment) {
        if (consignment == null) {
          return _DetailSection(
            title: 'Consignment',
            children: [
              const Text(
                'No commission agreement has been recorded for this consigned item.',
              ),
              if (item.status != InventoryStatus.sold &&
                  item.status != InventoryStatus.disposed) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('recordConsignmentAgreementButton'),
                    onPressed: () {
                      context.goNamed(
                        AppRouteNames.recordConsignment,
                        pathParameters: {'itemId': itemId},
                      );
                    },
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Record Consignment Agreement'),
                  ),
                ),
              ],
            ],
          );
        }

        return _ConsignmentAgreementDetails(consignment: consignment);
      },
    );
  }
}

class _ConsignmentAgreementDetails extends ConsumerWidget {
  const _ConsignmentAgreementDetails({required this.consignment});

  final ConsignmentTransaction consignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleId = consignment.saleTransactionId;

    if (saleId == null || saleId.trim().isEmpty) {
      return _DetailSection(
        title: 'Consignment',
        children: [
          _DetailRow(
            label: 'Agreement Date',
            value: _formatDate(consignment.consignmentDate),
          ),
          _DetailRow(
            label: 'Hit the Deck Commission',
            value: CurrencyFormatter.formatCents(consignment.commissionCents),
          ),
          const _DetailRow(label: 'Status', value: 'Awaiting Sale'),
          if (consignment.notes != null && consignment.notes!.trim().isNotEmpty)
            _DetailRow(label: 'Notes', value: consignment.notes!),
        ],
      );
    }

    final saleAsync = ref.watch(saleTransactionProvider(saleId));

    return saleAsync.when(
      loading: () => const _DetailSection(
        title: 'Consignment',
        children: [
          AppLoadingState(message: 'Loading completed consignment sale...'),
        ],
      ),
      error: (error, stackTrace) => _DetailSection(
        title: 'Consignment',
        children: [
          AppErrorState(
            message: 'Unable to load completed consignment sale.',
            details: error.toString(),
          ),
        ],
      ),
      data: (sale) {
        final payoutCents = sale == null
            ? null
            : consignment.consignorPayoutCentsForSale(sale.salePriceCents);

        return _DetailSection(
          title: 'Consignment',
          children: [
            _DetailRow(
              label: 'Agreement Date',
              value: _formatDate(consignment.consignmentDate),
            ),
            _DetailRow(
              label: 'Hit the Deck Commission',
              value: CurrencyFormatter.formatCents(consignment.commissionCents),
            ),
            const _DetailRow(label: 'Status', value: 'Sold / Completed'),
            if (sale != null)
              _DetailRow(
                label: 'Sale Price',
                value: CurrencyFormatter.formatCents(sale.salePriceCents),
              ),
            if (payoutCents != null)
              _DetailRow(
                label: 'Consignor Payout',
                value: CurrencyFormatter.formatCents(payoutCents),
              ),
            if (consignment.notes != null &&
                consignment.notes!.trim().isNotEmpty)
              _DetailRow(label: 'Notes', value: consignment.notes!),
          ],
        );
      },
    );
  }
}

class _InventoryDealSection extends ConsumerWidget {
  const _InventoryDealSection({
    required this.inventoryItemId,
    required this.status,
  });

  final String inventoryItemId;
  final InventoryStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childDealAsync = ref.watch(
      dealForChildInventoryItemProvider(inventoryItemId),
    );

    return childDealAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (childDeal) {
        if (childDeal != null) {
          return _DealLinkSection(
            dealId: childDeal.id,
            message: 'This inventory item is a direct child of a Deal.',
          );
        }

        if (status != InventoryStatus.sold) {
          return const SizedBox.shrink();
        }

        final saleAsync = ref.watch(
          saleForInventoryItemProvider(inventoryItemId),
        );

        return saleAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
          data: (sale) {
            final saleId = sale?.id;

            if (saleId == null || saleId.trim().isEmpty) {
              return const SizedBox.shrink();
            }

            final parentDealAsync = ref.watch(
              dealForParentSaleProvider(saleId),
            );

            return parentDealAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (parentDeal) {
                if (parentDeal == null) {
                  return const SizedBox.shrink();
                }

                return _DealLinkSection(
                  dealId: parentDeal.id,
                  message:
                      'This sold inventory item is the parent item for a Deal.',
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DealLinkSection extends StatelessWidget {
  const _DealLinkSection({required this.dealId, required this.message});

  final String? dealId;
  final String message;

  @override
  Widget build(BuildContext context) {
    final id = dealId?.trim() ?? '';

    if (id.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DetailSection(
      title: 'Deal',
      children: [
        Text(message),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('inventoryViewDealButton'),
            onPressed: () {
              context.goNamed(
                AppRouteNames.dealDetail,
                pathParameters: {'dealId': id},
              );
            },
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('View Deal'),
          ),
        ),
      ],
    );
  }
}

class _TradeHistorySection extends ConsumerWidget {
  const _TradeHistorySection({
    required this.inventoryItemId,
    required this.canViewFinancialData,
  });

  final String inventoryItemId;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(
      tradesForInventoryItemProvider(inventoryItemId),
    );
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return tradesAsync.when(
      loading: () => const _DetailSection(
        title: 'Trade History',
        children: [AppLoadingState(message: 'Loading trade history...')],
      ),
      error: (error, stackTrace) => _DetailSection(
        title: 'Trade History',
        children: [
          AppErrorState(
            message: 'Unable to load trade history.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(tradesForInventoryItemProvider(inventoryItemId));
            },
          ),
        ],
      ),
      data: (trades) {
        if (trades.isEmpty) {
          return const _DetailSection(
            title: 'Trade History',
            children: [Text('This inventory item is not linked to a trade.')],
          );
        }

        return inventoryAsync.when(
          loading: () => const _DetailSection(
            title: 'Trade History',
            children: [
              AppLoadingState(message: 'Loading related inventory...'),
            ],
          ),
          error: (error, stackTrace) => _DetailSection(
            title: 'Trade History',
            children: [
              AppErrorState(
                message: 'Unable to load related inventory.',
                details: error.toString(),
                onRetry: () {
                  ref.invalidate(inventoryItemsProvider);
                },
              ),
            ],
          ),
          data: (items) {
            final inventoryById = <String, InventoryItem>{
              for (final item in items)
                if (item.id != null) item.id!: item,
            };

            return _DetailSection(
              title: 'Trade History',
              children: [
                for (var index = 0; index < trades.length; index++) ...[
                  if (index > 0) const Divider(height: 32),
                  _TradeHistoryEntry(
                    inventoryItemId: inventoryItemId,
                    trade: trades[index],
                    inventoryById: inventoryById,
                    canViewFinancialData: canViewFinancialData,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _TradeHistoryEntry extends StatelessWidget {
  const _TradeHistoryEntry({
    required this.inventoryItemId,
    required this.trade,
    required this.inventoryById,
    required this.canViewFinancialData,
  });

  final String inventoryItemId;
  final TradeTransaction trade;
  final Map<String, InventoryItem> inventoryById;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = trade.outgoingInventoryItemIds.contains(inventoryItemId);

    final relatedIds = isOutgoing
        ? trade.incomingInventoryItemIds
        : trade.outgoingInventoryItemIds;

    return Column(
      key: ValueKey('inventoryTradeHistoryEntry-${trade.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(
          label: 'Relationship',
          value: isOutgoing
              ? 'Sold item in a trade-in sale'
              : 'Inventory received as a trade-in',
        ),
        _DetailRow(label: 'Trade Date', value: _formatDate(trade.tradeDate)),
        _DetailRow(
          label: isOutgoing ? 'Trade-In Items Received' : 'Original Items Sold',
          value: relatedIds.length.toString(),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < relatedIds.length; index++) ...[
          if (index > 0) const Divider(height: 24),
          _RelatedTradeInventoryItem(
            inventoryItemId: relatedIds[index],
            item: inventoryById[relatedIds[index]],
            canViewFinancialData: canViewFinancialData,
          ),
        ],
        if (trade.saleTransactionId != null &&
            trade.saleTransactionId!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: ValueKey('inventoryTradeViewSaleButton-${trade.id}'),
              onPressed: () {
                context.goNamed(
                  AppRouteNames.transactionDetail,
                  pathParameters: {'transactionId': trade.saleTransactionId!},
                );
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View Original Sale'),
            ),
          ),
        ],
      ],
    );
  }
}

class _RelatedTradeInventoryItem extends StatelessWidget {
  const _RelatedTradeInventoryItem({
    required this.inventoryItemId,
    required this.item,
    required this.canViewFinancialData,
  });

  final String inventoryItemId;
  final InventoryItem? item;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final relatedItem = item;

    if (relatedItem == null) {
      return Text(
        'A related inventory record is unavailable.',
        key: ValueKey('inventoryTradeMissingItem-$inventoryItemId'),
      );
    }

    final model = relatedItem.model?.trim();
    final displayName = model == null || model.isEmpty
        ? relatedItem.brand
        : '${relatedItem.brand} $model';

    return Column(
      key: ValueKey('inventoryTradeRelatedItem-$inventoryItemId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(
          label: 'Inventory Item',
          value:
              '${relatedItem.inventoryNumber ?? 'Not assigned'} — $displayName',
        ),
        _DetailRow(label: 'Status', value: relatedItem.status.label),
        if (canViewFinancialData)
          _DetailRow(
            label: 'Acquisition Value',
            value: CurrencyFormatter.formatCents(
              relatedItem.acquisitionValueCents,
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: ValueKey('inventoryTradeViewItemButton-$inventoryItemId'),
            onPressed: () {
              context.goNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': inventoryItemId},
              );
            },
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('View Inventory Item'),
          ),
        ),
      ],
    );
  }
}

class _DisposalHistorySection extends ConsumerWidget {
  const _DisposalHistorySection({required this.inventoryItemId});
  final String inventoryItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disposalsAsync = ref.watch(
      disposalsForInventoryItemProvider(inventoryItemId),
    );
    return disposalsAsync.when(
      loading: () => const _DetailSection(
        title: 'Disposal History',
        children: [AppLoadingState(message: 'Loading disposal history...')],
      ),
      error: (error, stackTrace) => _DetailSection(
        title: 'Disposal History',
        children: [
          AppErrorState(
            message: 'Unable to load disposal history.',
            details: error.toString(),
            onRetry: () => ref.invalidate(
              disposalsForInventoryItemProvider(inventoryItemId),
            ),
          ),
        ],
      ),
      data: (disposals) {
        if (disposals.isEmpty) {
          return const _DetailSection(
            title: 'Disposal History',
            children: [Text('This inventory item has not been disposed.')],
          );
        }
        return _DetailSection(
          title: 'Disposal History',
          children: [
            for (var index = 0; index < disposals.length; index++) ...[
              if (index > 0) const Divider(height: 32),
              _DisposalHistoryEntry(disposal: disposals[index]),
            ],
          ],
        );
      },
    );
  }
}

class _DisposalHistoryEntry extends StatelessWidget {
  const _DisposalHistoryEntry({required this.disposal});
  final DisposalTransaction disposal;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('inventoryDisposalHistoryEntry-${disposal.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(
          label: 'Disposal Date',
          value: _formatDate(disposal.disposalDate),
        ),
        _DetailRow(label: 'Reason', value: disposal.reason.label),
        if (disposal.notes != null && disposal.notes!.trim().isNotEmpty)
          _DetailRow(label: 'Notes', value: disposal.notes!),
        if (disposal.requiresReplacementDeal) ...[
          const SizedBox(height: 8),
          _WarrantyReplacementDealEntry(disposal: disposal),
        ],
      ],
    );
  }
}

class _WarrantyReplacementDealEntry extends ConsumerWidget {
  const _WarrantyReplacementDealEntry({required this.disposal});

  final DisposalTransaction disposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disposalId = disposal.id;

    if (disposalId == null || disposalId.trim().isEmpty) {
      return const Text(
        'Warranty replacement: replacement Deal follow-up required.',
      );
    }

    final dealAsync = ref.watch(
      warrantyReplacementDealForDisposalProvider(disposalId),
    );

    return dealAsync.when(
      loading: () => const AppLoadingState(
        message: 'Loading warranty replacement Deal...',
      ),
      error: (error, stackTrace) => AppErrorState(
        message: 'Unable to load warranty replacement Deal.',
        details: error.toString(),
      ),
      data: (deal) {
        if (deal == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Warranty replacement: replacement Deal follow-up required.',
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: ValueKey('createWarrantyReplacementButton-$disposalId'),
                  onPressed: () {
                    context.goNamed(
                      AppRouteNames.warrantyReplacement,
                      pathParameters: {'disposalId': disposalId},
                    );
                  },
                  icon: const Icon(Icons.autorenew_outlined),
                  label: const Text('Create Replacement'),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Warranty Replacement Deal completed.'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: ValueKey('viewWarrantyReplacementItemButton-${deal.id}'),
                onPressed: () {
                  context.goNamed(
                    AppRouteNames.inventoryDetail,
                    pathParameters: {'itemId': deal.replacementInventoryItemId},
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('View Replacement Item'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RepairHistorySection extends ConsumerWidget {
  const _RepairHistorySection({
    required this.inventoryItemId,
    required this.acquisitionValueCents,
    required this.canViewFinancialData,
  });

  final String inventoryItemId;
  final int acquisitionValueCents;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repairsAsync = ref.watch(
      repairsForInventoryItemProvider(inventoryItemId),
    );

    return repairsAsync.when(
      loading: () => const _DetailSection(
        title: 'Repair History',
        children: [AppLoadingState(message: 'Loading repair history...')],
      ),
      error: (error, stackTrace) => _DetailSection(
        title: 'Repair History',
        children: [
          AppErrorState(
            message: 'Unable to load repair history.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(repairsForInventoryItemProvider(inventoryItemId));
            },
          ),
        ],
      ),
      data: (repairs) {
        return _RepairHistoryContent(
          repairs: repairs,
          acquisitionValueCents: acquisitionValueCents,
          canViewFinancialData: canViewFinancialData,
        );
      },
    );
  }
}

class _RepairHistoryContent extends StatelessWidget {
  const _RepairHistoryContent({
    required this.repairs,
    required this.acquisitionValueCents,
    required this.canViewFinancialData,
  });

  final List<RepairTransaction> repairs;
  final int acquisitionValueCents;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final totalRepairCostCents = repairs.fold<int>(
      0,
      (total, repair) => total + repair.costCents,
    );

    final trueCostCents = acquisitionValueCents + totalRepairCostCents;

    return _DetailSection(
      title: 'Repair History',
      children: [
        _DetailRow(
          label: 'Number of Repairs',
          value: repairs.length.toString(),
        ),
        if (canViewFinancialData) ...[
          _DetailRow(
            label: 'Total Repair Cost',
            value: CurrencyFormatter.formatCents(totalRepairCostCents),
          ),
          _DetailRow(
            label: 'True Cost',
            value: CurrencyFormatter.formatCents(trueCostCents),
          ),
        ],
        const SizedBox(height: 12),
        if (repairs.isEmpty)
          const Text('No repairs have been recorded for this item.')
        else
          for (var index = 0; index < repairs.length; index++) ...[
            if (index > 0) const Divider(height: 32),
            _RepairHistoryEntry(
              repair: repairs[index],
              canViewFinancialData: canViewFinancialData,
            ),
          ],
      ],
    );
  }
}

class _RepairHistoryEntry extends StatelessWidget {
  const _RepairHistoryEntry({
    required this.repair,
    required this.canViewFinancialData,
  });

  final RepairTransaction repair;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final repairId = repair.id;

    return Column(
      key: ValueKey('repairHistoryEntry-${repair.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(label: 'Repair Date', value: _formatDate(repair.repairDate)),
        _DetailRow(label: 'Description', value: repair.description),
        if (canViewFinancialData)
          _DetailRow(
            label: 'Repair Cost',
            value: CurrencyFormatter.formatCents(repair.costCents),
          ),
        if (repair.notes != null && repair.notes!.trim().isNotEmpty)
          _DetailRow(label: 'Notes', value: repair.notes!),
        if (repairId != null && repairId.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: ValueKey('repairHistoryViewButton-$repairId'),
              onPressed: () {
                context.goNamed(
                  AppRouteNames.repairDetail,
                  pathParameters: {'repairId': repairId},
                );
              },
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('View Repair'),
            ),
          ),
        ],
      ],
    );
  }
}

class _SellerInformationSection extends ConsumerWidget {
  const _SellerInformationSection({required this.sellerContactId});

  final String? sellerContactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactId = sellerContactId?.trim() ?? '';

    if (contactId.isEmpty) {
      return const _DetailSection(
        title: 'Seller Information',
        children: [_DetailRow(label: 'Seller', value: 'No seller linked')],
      );
    }

    final sellerAsync = ref.watch(contactProvider(contactId));

    return sellerAsync.when(
      loading: () => const _DetailSection(
        title: 'Seller Information',
        children: [AppLoadingState(message: 'Loading seller information...')],
      ),
      error: (error, stackTrace) => _DetailSection(
        title: 'Seller Information',
        children: [
          AppErrorState(
            message: 'Unable to load seller information.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(contactProvider(contactId));
            },
          ),
        ],
      ),
      data: (seller) {
        if (seller == null) {
          return const _DetailSection(
            title: 'Seller Information',
            children: [
              Text(
                'A seller is linked to this item, but the Contact record is unavailable.',
              ),
            ],
          );
        }

        return _SellerInformationContent(
          sellerId: contactId,
          sellerName: seller.name,
          sellerPhone: seller.phone,
          sellerEmail: seller.email,
        );
      },
    );
  }
}

class _SellerInformationContent extends StatelessWidget {
  const _SellerInformationContent({
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerEmail,
  });

  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String? sellerEmail;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Seller Information',
      children: [
        _DetailRow(label: 'Seller', value: sellerName),
        _DetailRow(label: 'Phone', value: _displayOptionalText(sellerPhone)),
        _DetailRow(label: 'Email', value: _displayOptionalText(sellerEmail)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('inventoryItemViewSellerButton'),
            onPressed: () {
              context.goNamed(
                AppRouteNames.contactDetail,
                pathParameters: {'contactId': sellerId},
              );
            },
            icon: const Icon(Icons.person_outline),
            label: const Text('View Seller'),
          ),
        ),
      ],
    );
  }
}

class _SaleInformationSection extends ConsumerWidget {
  const _SaleInformationSection({
    required this.inventoryItemId,
    required this.canViewFinancialData,
  });

  final String inventoryItemId;
  final bool canViewFinancialData;

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

        return _SaleInformationCardContent(
          sale: sale,
          canViewFinancialData: canViewFinancialData,
        );
      },
    );
  }
}

class _SaleInformationCardContent extends StatelessWidget {
  const _SaleInformationCardContent({
    required this.sale,
    required this.canViewFinancialData,
  });

  final SaleTransaction sale;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final acquisitionValue = sale.acquisitionValueCents;
    final profit = sale.profitCents;

    return _DetailSection(
      title: 'Sale Information',
      children: [
        _DetailRow(label: 'Sale Date', value: _formatDate(sale.saleDate)),
        _DetailRow(label: 'Payment Method', value: sale.paymentMethod.label),
        _SaleBuyerInformation(buyerContactId: sale.buyerContactId),
        _DetailRow(
          label: 'Sale Price',
          value: CurrencyFormatter.formatCents(sale.salePriceCents),
        ),
        if (canViewFinancialData) ...[
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
        ],
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

class _SaleBuyerInformation extends ConsumerWidget {
  const _SaleBuyerInformation({required this.buyerContactId});

  final String? buyerContactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactId = buyerContactId?.trim() ?? '';

    if (contactId.isEmpty) {
      return const _DetailRow(label: 'Buyer', value: 'No buyer linked');
    }

    final buyerAsync = ref.watch(contactProvider(contactId));

    return buyerAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: AppLoadingState(message: 'Loading buyer information...'),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AppErrorState(
          message: 'Unable to load buyer information.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(contactProvider(contactId));
          },
        ),
      ),
      data: (buyer) {
        if (buyer == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'A buyer is linked to this sale, but the Contact record is unavailable.',
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(label: 'Buyer', value: buyer.name),
              _DetailRow(
                label: 'Buyer Phone',
                value: _displayOptionalText(buyer.phone),
              ),
              _DetailRow(
                label: 'Buyer Email',
                value: _displayOptionalText(buyer.email),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('inventoryItemViewBuyerButton'),
                  onPressed: () {
                    context.goNamed(
                      AppRouteNames.contactDetail,
                      pathParameters: {'contactId': contactId},
                    );
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('View Buyer'),
                ),
              ),
            ],
          ),
        );
      },
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

String? _compactItemSpecifications(InventoryItem item) {
  final values = <String>[];

  switch (item.category) {
    case InventoryCategory.bat:
      final length = item.lengthInches == null
          ? null
          : '${_formatNumber(item.lengthInches!)}"';
      final weight = item.weightOunces == null
          ? null
          : '${_formatNumber(item.weightOunces!)} oz';

      if (length != null || weight != null) {
        values.add([?length, ?weight].join(' / '));
      }
      if (item.drop != null) {
        values.add(_formatNumber(item.drop!));
      }
      if (item.certification != null && item.certification!.trim().isNotEmpty) {
        values.add(item.certification!.trim());
      }
    case InventoryCategory.glove:
      if (item.gloveSizeInches != null) {
        values.add('${_formatNumber(item.gloveSizeInches!)}"');
      }
      if (item.handOrientation != null &&
          item.handOrientation!.trim().isNotEmpty) {
        values.add(item.handOrientation!.trim());
      }
    case InventoryCategory.catchersGear:
      if (item.catchersGearSize != null &&
          item.catchersGearSize!.trim().isNotEmpty) {
        values.add(item.catchersGearSize!.trim());
      }
    case InventoryCategory.helmet:
      if (item.helmetSize != null && item.helmetSize!.trim().isNotEmpty) {
        values.add(item.helmetSize!.trim());
      }
    case InventoryCategory.other:
      break;
  }

  return values.isEmpty ? null : values.join(' * ');
}

String _formatCompactPrice(int? cents) {
  if (cents == null) {
    return r'$---';
  }

  final dollars = cents / 100;
  return '\$${dollars.toStringAsFixed(0)}';
}

String _formatProfit(int cents) {
  final dollars = (cents.abs() / 100).toStringAsFixed(0);
  final sign = cents >= 0 ? '+' : '-';
  return '$sign\$$dollars';
}

String _inventoryAgeLabel(InventoryItem item) {
  final start = item.purchaseDate;
  if (start == null) {
    return 'Age unavailable';
  }

  final now = DateTime.now();
  final startDate = DateTime(start.year, start.month, start.day);
  final nowDate = DateTime(now.year, now.month, now.day);
  final days = nowDate.difference(startDate).inDays;

  return '${days < 0 ? 0 : days} days';
}

Color _inventoryCategoryColor(InventoryCategory category) {
  return switch (category) {
    InventoryCategory.bat => Colors.blue.shade700,
    InventoryCategory.glove => Colors.orange.shade800,
    InventoryCategory.catchersGear => Colors.purple.shade700,
    InventoryCategory.helmet => Colors.indigo.shade900,
    InventoryCategory.other => Colors.blueGrey.shade600,
  };
}

String _displayOptionalText(String? value) {
  final trimmedValue = value?.trim() ?? '';

  return trimmedValue.isEmpty ? 'Not specified' : trimmedValue;
}

String _formatOptionalMoney(int? cents) {
  return cents == null ? 'Not specified' : CurrencyFormatter.formatCents(cents);
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
