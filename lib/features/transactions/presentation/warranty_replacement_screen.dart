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
import '../domain/models/disposal_reason.dart';
import 'providers/transaction_providers.dart';
import 'providers/warranty_replacement_controller.dart';
import 'providers/warranty_replacement_providers.dart';

class WarrantyReplacementScreen extends ConsumerWidget {
  const WarrantyReplacementScreen({required this.disposalId, super.key});

  final String disposalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disposalAsync = ref.watch(disposalTransactionProvider(disposalId));

    return disposalAsync.when(
      loading: () => const AppPage(
        title: 'Warranty Replacement',
        child: AppLoadingState(message: 'Loading disposal...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Warranty Replacement',
        child: AppErrorState(
          message: 'Unable to load disposal.',
          details: error.toString(),
        ),
      ),
      data: (disposal) {
        if (disposal == null) {
          return const AppPage(
            title: 'Warranty Replacement',
            child: AppEmptyState(
              icon: Icons.autorenew_outlined,
              title: 'Disposal not found.',
              message: 'The warranty replacement cannot be created.',
            ),
          );
        }

        if (disposal.reason != DisposalReason.warrantyReplacement) {
          return const AppPage(
            title: 'Warranty Replacement',
            child: AppEmptyState(
              icon: Icons.block_outlined,
              title: 'Not a warranty replacement.',
              message:
                  'Only Warranty Replacement disposals can create this Deal.',
            ),
          );
        }

        final itemAsync = ref.watch(
          inventoryItemProvider(disposal.inventoryItemId),
        );

        return itemAsync.when(
          loading: () => const AppPage(
            title: 'Warranty Replacement',
            child: AppLoadingState(message: 'Loading disposed inventory...'),
          ),
          error: (error, stackTrace) => AppPage(
            title: 'Warranty Replacement',
            child: AppErrorState(
              message: 'Unable to load disposed inventory.',
              details: error.toString(),
            ),
          ),
          data: (item) {
            if (item == null) {
              return const AppPage(
                title: 'Warranty Replacement',
                child: AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Disposed inventory not found.',
                  message:
                      'The replacement cannot be created without the original item.',
                ),
              );
            }

            return _WarrantyReplacementForm(
              disposalId: disposalId,
              disposedItem: item,
            );
          },
        );
      },
    );
  }
}

class _WarrantyReplacementForm extends ConsumerStatefulWidget {
  const _WarrantyReplacementForm({
    required this.disposalId,
    required this.disposedItem,
  });

  final String disposalId;
  final InventoryItem disposedItem;

  @override
  ConsumerState<_WarrantyReplacementForm> createState() {
    return _WarrantyReplacementFormState();
  }
}

class _WarrantyReplacementFormState
    extends ConsumerState<_WarrantyReplacementForm> {
  late DateTime _replacementDate;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _replacementDate = DateTime.now();
    _dateController = TextEditingController(
      text: _formatDate(_replacementDate),
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  String _displayName() {
    final model = widget.disposedItem.model?.trim();
    return model == null || model.isEmpty
        ? widget.disposedItem.brand
        : '${widget.disposedItem.brand} $model';
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _replacementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _replacementDate = selected;
      _dateController.text = _formatDate(selected);
    });
  }

  Future<void> _submit() async {
    final disposal = await ref.read(
      disposalTransactionProvider(widget.disposalId).future,
    );

    if (disposal == null) {
      return;
    }

    try {
      final deal = await ref
          .read(warrantyReplacementControllerProvider.notifier)
          .createReplacement(
            disposal: disposal,
            disposedItem: widget.disposedItem,
            replacementDate: _replacementDate,
            notes: _notesController.text,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warranty replacement inventory and Deal created.'),
        ),
      );

      context.goNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': deal.replacementInventoryItemId},
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create warranty replacement: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(warrantyReplacementControllerProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);
    final existingDealAsync = ref.watch(
      warrantyReplacementDealForDisposalProvider(widget.disposalId),
    );
    final isSaving = controllerState.isLoading;

    return existingDealAsync.when(
      loading: () => const AppPage(
        title: 'Warranty Replacement',
        child: AppLoadingState(message: 'Checking replacement Deal...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Warranty Replacement',
        child: AppErrorState(
          message: 'Unable to check replacement Deal.',
          details: error.toString(),
        ),
      ),
      data: (existingDeal) {
        if (existingDeal != null) {
          return AppPage(
            title: 'Warranty Replacement',
            child: AppEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Replacement already created.',
              message:
                  'This disposal is already linked to replacement inventory.',
              action: OutlinedButton(
                onPressed: () {
                  context.goNamed(
                    AppRouteNames.inventoryDetail,
                    pathParameters: {
                      'itemId': existingDeal.replacementInventoryItemId,
                    },
                  );
                },
                child: const Text('View Replacement Item'),
              ),
            ),
          );
        }

        return AppPage(
          title: 'Warranty Replacement',
          subtitle: _displayName(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Replacement Inventory',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        permissions.canViewFinancialData
                            ? 'The replacement will copy the original item details and carry forward its acquisition value of '
                                  '${CurrencyFormatter.formatCents(widget.disposedItem.acquisitionValueCents)}.'
                            : 'The replacement will copy the original item details and preserve its existing cost basis.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'It will enter inventory as New and Available. You can edit its details afterward if the manufacturer sends a different model or specification.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('warrantyReplacementDateField'),
                controller: _dateController,
                readOnly: true,
                enabled: !isSaving,
                onTap: isSaving ? null : _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Replacement Date',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('warrantyReplacementNotesField'),
                controller: _notesController,
                enabled: !isSaving,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Replacement Notes',
                  hintText:
                      'Optional manufacturer, claim, or replacement details.',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('createWarrantyReplacementDealButton'),
                onPressed: isSaving ? null : _submit,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew_outlined),
                label: Text(
                  isSaving
                      ? 'Creating Replacement...'
                      : 'Create Replacement Inventory',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
