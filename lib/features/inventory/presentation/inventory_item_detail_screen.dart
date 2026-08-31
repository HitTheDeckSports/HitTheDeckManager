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

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: AppPage(
              title: 'Inventory Item',
              showHeader: false,
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    _CollapsibleDetailSection(
                      key: const Key('inventoryNotesSection'),
                      icon: Icons.description_outlined,
                      title: 'Notes',
                      summary: _singleLineSummary(item.notes!.trim()),
                      child: Text(item.notes!.trim()),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _CollapsibleDetailSection(
                    key: const Key('inventoryAdditionalPricingSection'),
                    icon: Icons.paid_outlined,
                    title: 'Additional Pricing',
                    child: _ThreeValueSummary(
                      values: [
                        ('Price New', _formatOptionalMoney(item.newValueCents)),
                        (
                          'Asking Price',
                          _formatOptionalMoney(item.askingPriceCents),
                        ),
                        (
                          'Min Price',
                          _formatOptionalMoney(item.minimumPriceCents),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SellerInformationSection(
                    sellerContactId: item.sellerContactId,
                  ),
                  if (item.acquisitionType == AcquisitionType.consignment &&
                      item.id != null) ...[
                    const SizedBox(height: 10),
                    _ConsignmentSection(item: item),
                  ],
                  if (item.id != null) ...[
                    const SizedBox(height: 10),
                    _RepairHistorySection(
                      inventoryItemId: item.id!,
                      acquisitionValueCents: item.acquisitionValueCents,
                      canViewFinancialData: permissions.canViewFinancialData,
                    ),
                    const SizedBox(height: 10),
                    _DisposalHistorySection(inventoryItemId: item.id!),
                  ],
                  if (item.status == InventoryStatus.sold &&
                      item.id != null) ...[
                    const SizedBox(height: 10),
                    _SaleInformationSection(
                      inventoryItemId: item.id!,
                      canViewFinancialData: permissions.canViewFinancialData,
                    ),
                  ],
                  if (item.id != null) ...[
                    const SizedBox(height: 10),
                    _TradeHistorySection(
                      inventoryItemId: item.id!,
                      canViewFinancialData: permissions.canViewFinancialData,
                    ),
                    const SizedBox(height: 10),
                    _InventoryDealSection(
                      inventoryItemId: item.id!,
                      status: item.status,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _InventoryPrimaryActions(
            item: item,
            canDisposeInventory: permissions.canDisposeInventory,
            isUpdatingStatus: isUpdatingStatus,
          ),
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
      _QuickInfoData(
        'Category',
        item.category.label,
        _inventoryCategoryIcon(item.category),
      ),
      _QuickInfoData('Brand', item.brand, Icons.sell_outlined),
      _QuickInfoData(
        'Model',
        _displayOptionalText(item.model),
        Icons.local_offer_outlined,
      ),
      _QuickInfoData(
        'Condition',
        item.condition?.label ?? 'Not specified',
        Icons.workspace_premium_outlined,
      ),
      _QuickInfoData(
        'Purchased',
        item.purchaseDate == null
            ? 'Not specified'
            : _formatDate(item.purchaseDate!),
        Icons.calendar_month_outlined,
      ),
      if (canViewFinancialData)
        _QuickInfoData(
          'Cost',
          CurrencyFormatter.formatCents(item.acquisitionValueCents),
          Icons.paid_outlined,
        )
      else
        const _QuickInfoData('Cost', 'Restricted', Icons.lock_outline),
      _QuickInfoData('Location', locationLabel, Icons.location_on_outlined),
      _QuickInfoData(
        'Acquisition',
        item.acquisitionType.label,
        Icons.shopping_cart_outlined,
      ),
      _QuickInfoData(
        'QR Code',
        'View / Print',
        Icons.qr_code_2,
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (context) => _InventoryQrDialog(item: item),
          );
        },
      ),
    ];

    return Card(
      key: const Key('inventoryItemQuickInfoGrid'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            const columns = 3;
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
  const _QuickInfoData(this.label, this.value, this.icon, {this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
}

class _QuickInfoCell extends StatelessWidget {
  const _QuickInfoCell({required this.data});

  final _QuickInfoData data;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16062A4D),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                data.icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.label.toUpperCase(),
                  key: ValueKey('inventoryQuickInfoLabel-${data.label}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
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

    if (data.onTap == null) {
      return content;
    }

    return Semantics(
      button: true,
      child: InkWell(
        key: ValueKey('inventoryQuickInfoAction-${data.label}'),
        borderRadius: BorderRadius.circular(12),
        onTap: data.onTap,
        child: content,
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
                            color: const Color(0xFFF0F2F5),

                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.condition!.label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
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
                    'Asking Price',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCompactPrice(item.askingPriceCents),
                    key: const Key('inventoryItemAskingPrice'),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
    return Material(
      key: const Key('inventoryItemPrimaryActions'),
      elevation: 10,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            key: const Key('inventoryItemPrimaryActionRow'),
            children: [
              if (item.id != null && item.status == InventoryStatus.available)
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('inventoryItemSellButton'),
                    onPressed: isUpdatingStatus
                        ? null
                        : () {
                            context.goNamed(
                              AppRouteNames.sellInventory,
                              extra: item,
                            );
                          },
                    icon: const Icon(Icons.sell_outlined, size: 18),
                    label: const Text('Sell'),
                  ),
                ),
              if (item.id != null && item.status == InventoryStatus.available)
                const SizedBox(width: 8),
              if (item.id != null && item.status != InventoryStatus.disposed)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('inventoryItemAddRepairButton'),
                    onPressed: isUpdatingStatus
                        ? null
                        : () {
                            context.goNamed(
                              AppRouteNames.addRepair,
                              pathParameters: {'itemId': item.id!},
                            );
                          },
                    icon: const Icon(Icons.build_outlined, size: 18),
                    label: const Text(
                      'Add Repair',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              if (item.id != null && item.status != InventoryStatus.disposed)
                const SizedBox(width: 8),
              if (item.id != null)
                Expanded(
                  child: PopupMenuButton<InventoryStatus>(
                    key: const Key('inventoryItemStatusButton'),
                    enabled: !isUpdatingStatus,
                    tooltip: 'Change inventory status',
                    onSelected: (status) async {
                      if (status == InventoryStatus.disposed) {
                        if (item.id != null && context.mounted) {
                          context.goNamed(
                            AppRouteNames.disposeInventory,
                            pathParameters: {'itemId': item.id!},
                          );
                        }
                        return;
                      }

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
                            content: Text(
                              'Unable to change inventory status: $error',
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        for (final status in [
                          InventoryStatus.available,
                          InventoryStatus.inactive,
                          InventoryStatus.broken,
                          if (canDisposeInventory &&
                              item.status != InventoryStatus.sold &&
                              item.status != InventoryStatus.disposed)
                            InventoryStatus.disposed,
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
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: isUpdatingStatus
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.swap_horiz, size: 18),
                        label: Text(
                          isUpdatingStatus ? 'Updating...' : 'Change Status',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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

    return _CollapsibleDetailSection(
      key: const Key('inventoryDealSection'),
      icon: Icons.handshake_outlined,
      title: 'Deal / Warranty',
      summary: message,
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
          return const SizedBox.shrink(key: Key('inventoryTradeHistoryEmpty'));
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
            return _CollapsibleDetailSection(
              key: const Key('inventoryTradeHistorySection'),
              icon: Icons.swap_horiz,
              title: 'Trade History',
              summary: ' -  related ',
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
          return const SizedBox.shrink(
            key: Key('inventoryDisposalHistoryEmpty'),
          );
        }
        return _CollapsibleDetailSection(
          key: const Key('inventoryDisposalHistorySection'),
          icon: Icons.delete_outline,
          title: 'Disposal History',
          summary: disposals.first.reason.label,
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

    if (repairs.isEmpty) {
      return const _StaticSummarySection(
        key: Key('inventoryRepairHistoryEmpty'),
        icon: Icons.build_outlined,
        title: 'Repair History',
        summary: 'No repairs have been recorded for this item.',
      );
    }

    return _CollapsibleDetailSection(
      key: const Key('inventoryRepairHistorySection'),
      icon: Icons.build_outlined,
      title: 'Repair History',
      summary:
          '${repairs.length} ${repairs.length == 1 ? 'repair' : 'repairs'}'
          '${canViewFinancialData ? ' - ${CurrencyFormatter.formatCents(totalRepairCostCents)} total' : ''}',
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
        const SizedBox(height: 8),
        for (var index = 0; index < repairs.length; index++) ...[
          if (index > 0) const Divider(height: 24),
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
      return const _StaticSummarySection(
        key: Key('inventorySellerEmpty'),
        icon: Icons.person_outline,
        title: 'Seller Information',
        summary: 'No seller linked',
      );
    }

    final sellerAsync = ref.watch(contactProvider(contactId));
    return sellerAsync.when(
      loading: () => const _StaticSummarySection(
        icon: Icons.person_outline,
        title: 'Seller Information',
        summary: 'Loading seller...',
      ),
      error: (error, stackTrace) => _StaticSummarySection(
        icon: Icons.person_outline,
        title: 'Seller Information',
        summary: 'Unable to load seller information.',
      ),
      data: (seller) {
        if (seller == null) {
          return const _StaticSummarySection(
            icon: Icons.person_outline,
            title: 'Seller Information',
            summary:
                'A seller is linked to this item, but the Contact record is unavailable.',
          );
        }

        return _CollapsibleDetailSection(
          key: const Key('inventorySellerSection'),
          icon: Icons.person_outline,
          title: 'Seller Information',
          summary: seller.name,
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('inventoryItemViewSellerButton'),
              onPressed: () {
                context.goNamed(
                  AppRouteNames.contactDetail,
                  pathParameters: {'contactId': contactId},
                );
              },
              icon: const Icon(Icons.person_outline),
              label: const Text('View Contact'),
            ),
          ),
        );
      },
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

class _SaleInformationCardContent extends ConsumerWidget {
  const _SaleInformationCardContent({
    required this.sale,
    required this.canViewFinancialData,
  });

  final SaleTransaction sale;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactId = sale.buyerContactId?.trim() ?? '';
    final buyerAsync = contactId.isEmpty
        ? const AsyncValue<dynamic>.data(null)
        : ref.watch(contactProvider(contactId));
    final buyerName = buyerAsync.maybeWhen(
      data: (buyer) {
        if (buyer != null) {
          return buyer.name;
        }
        return contactId.isEmpty
            ? 'No buyer linked'
            : 'A buyer is linked to this sale, but the Contact record is unavailable.';
      },
      orElse: () => 'Loading buyer...',
    );
    final buyerIsAvailable = buyerAsync.maybeWhen(
      data: (buyer) => buyer != null,
      orElse: () => false,
    );
    final profit = sale.profitCents;
    final price = _formatCompactPrice(sale.salePriceCents);
    final profitText = canViewFinancialData && profit != null
        ? ' (${_formatProfit(profit)})'
        : '';
    final summary =
        '${_formatDate(sale.saleDate)}  $buyerName  $price$profitText';

    return _CollapsibleDetailSection(
      key: const Key('inventorySaleInformationSection'),
      icon: Icons.sell_outlined,
      title: 'Sale Information',
      summary: summary,
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (contactId.isNotEmpty && buyerIsAvailable)
            OutlinedButton.icon(
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
          OutlinedButton.icon(
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
        ],
      ),
    );
  }
}

class _CollapsibleDetailSection extends StatefulWidget {
  const _CollapsibleDetailSection({
    required this.icon,
    required this.title,
    this.child,
    this.children,
    this.summary,
    super.key,
  }) : assert(
         (child == null) != (children == null),
         'Provide exactly one of child or children.',
       );

  final IconData icon;
  final String title;
  final String? summary;
  final Widget? child;
  final List<Widget>? children;

  @override
  State<_CollapsibleDetailSection> createState() =>
      _CollapsibleDetailSectionState();
}

class _CollapsibleDetailSectionState extends State<_CollapsibleDetailSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary?.trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 19,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          key: ValueKey(
                            'inventoryCollapsibleTitle-${widget.title}',
                          ),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF082A4A),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (summary != null && summary.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child:
                            widget.child ??
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.children!,
                            ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticSummarySection extends StatelessWidget {
  const _StaticSummarySection({
    required this.icon,
    required this.title,
    required this.summary,
    super.key,
  });

  final IconData icon;
  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: ValueKey('inventoryStaticTitle-$title'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF082A4A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeValueSummary extends StatelessWidget {
  const _ThreeValueSummary({required this.values});

  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  values[i].$1,
                  key: ValueKey('inventoryExpandedFieldLabel-${values[i].$1}'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF082A4A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(values[i].$2),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _singleLineSummary(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = constraints.maxWidth < 420 ? 132.0 : 190.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  key: ValueKey('inventoryDetailRowLabel-$label'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF082A4A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(value)),
            ],
          );
        },
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

IconData _inventoryCategoryIcon(InventoryCategory category) {
  return switch (category) {
    InventoryCategory.bat => Icons.sports_baseball,
    InventoryCategory.glove => Icons.sports_outlined,
    InventoryCategory.catchersGear => Icons.shield_outlined,
    InventoryCategory.helmet => Icons.sports_motorsports_outlined,
    InventoryCategory.other => Icons.inventory_2_outlined,
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
