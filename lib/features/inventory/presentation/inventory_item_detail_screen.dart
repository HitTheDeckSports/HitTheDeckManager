import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
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
import 'providers/inventory_providers.dart';
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
            label: const Text('QR Code'),
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
        if (item.id != null &&
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
          if (item.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 24),
            _InventoryPhotosSection(photoUrls: item.photoUrls),
          ],
          const SizedBox(height: 24),
          _SellerInformationSection(sellerContactId: item.sellerContactId),
          if (item.acquisitionType == AcquisitionType.consignment &&
              item.id != null) ...[
            const SizedBox(height: 24),
            _ConsignmentSection(item: item),
          ],
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
          if (item.id != null) ...[
            const SizedBox(height: 24),
            _RepairHistorySection(
              inventoryItemId: item.id!,
              acquisitionValueCents: item.acquisitionValueCents,
            ),
            const SizedBox(height: 24),
            _DisposalHistorySection(inventoryItemId: item.id!),
          ],
          if (item.status == InventoryStatus.sold && item.id != null) ...[
            const SizedBox(height: 24),
            _SaleInformationSection(inventoryItemId: item.id!),
          ],
          if (item.id != null) ...[
            const SizedBox(height: 24),
            _TradeHistorySection(inventoryItemId: item.id!),
            const SizedBox(height: 24),
            _InventoryDealSection(
              inventoryItemId: item.id!,
              status: item.status,
            ),
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
      ],
    );
  }
}

class _InventoryPhotosSection extends StatelessWidget {
  const _InventoryPhotosSection({required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Photos',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              photoUrls.first,
              key: const Key('inventoryPrimaryPhoto'),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFFE0E0E0),
                  child: Center(
                    child: Icon(Icons.broken_image_outlined, size: 40),
                  ),
                );
              },
            ),
          ),
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
        const SizedBox(height: 8),
        Text(
          '${photoUrls.length} ${photoUrls.length == 1 ? 'photo' : 'photos'}',
          key: const Key('inventoryPhotoCountLabel'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
  const _TradeHistorySection({required this.inventoryItemId});

  final String inventoryItemId;

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
  });

  final String inventoryItemId;
  final TradeTransaction trade;
  final Map<String, InventoryItem> inventoryById;

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
  });

  final String inventoryItemId;
  final InventoryItem? item;

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
  });

  final String inventoryItemId;
  final int acquisitionValueCents;

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
        );
      },
    );
  }
}

class _RepairHistoryContent extends StatelessWidget {
  const _RepairHistoryContent({
    required this.repairs,
    required this.acquisitionValueCents,
  });

  final List<RepairTransaction> repairs;
  final int acquisitionValueCents;

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
        _DetailRow(
          label: 'Total Repair Cost',
          value: CurrencyFormatter.formatCents(totalRepairCostCents),
        ),
        _DetailRow(
          label: 'True Cost',
          value: CurrencyFormatter.formatCents(trueCostCents),
        ),
        const SizedBox(height: 12),
        if (repairs.isEmpty)
          const Text('No repairs have been recorded for this item.')
        else
          for (var index = 0; index < repairs.length; index++) ...[
            if (index > 0) const Divider(height: 32),
            _RepairHistoryEntry(repair: repairs[index]),
          ],
      ],
    );
  }
}

class _RepairHistoryEntry extends StatelessWidget {
  const _RepairHistoryEntry({required this.repair});

  final RepairTransaction repair;

  @override
  Widget build(BuildContext context) {
    final repairId = repair.id;

    return Column(
      key: ValueKey('repairHistoryEntry-${repair.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(label: 'Repair Date', value: _formatDate(repair.repairDate)),
        _DetailRow(label: 'Description', value: repair.description),
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
        _SaleBuyerInformation(buyerContactId: sale.buyerContactId),
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
