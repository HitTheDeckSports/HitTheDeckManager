import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/disposal_reason.dart';
import 'providers/disposal_transaction_controller.dart';

class DisposeInventoryScreen extends ConsumerWidget {
  const DisposeInventoryScreen({required this.inventoryItemId, super.key});
  final String inventoryItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemProvider(inventoryItemId));
    return itemAsync.when(
      loading: () => const AppPage(
        title: 'Dispose Inventory',
        child: AppLoadingState(message: 'Loading inventory item...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Dispose Inventory',
        child: AppErrorState(
          message: 'Unable to load the inventory item.',
          details: error.toString(),
          onRetry: () => ref.invalidate(inventoryItemProvider(inventoryItemId)),
        ),
      ),
      data: (item) {
        if (item == null) {
          return const AppPage(
            title: 'Dispose Inventory',
            child: AppEmptyState(
              icon: Icons.delete_outline,
              title: 'Inventory item not found.',
              message:
                  'The item cannot be disposed because its inventory record is unavailable.',
            ),
          );
        }
        if (item.status == InventoryStatus.sold) {
          return const AppPage(
            title: 'Dispose Inventory',
            child: AppEmptyState(
              icon: Icons.block_outlined,
              title: 'Sold inventory cannot be disposed.',
              message:
                  'A completed sale must be corrected through the sale workflow.',
            ),
          );
        }
        if (item.status == InventoryStatus.disposed) {
          return const AppPage(
            title: 'Dispose Inventory',
            child: AppEmptyState(
              icon: Icons.delete_forever_outlined,
              title: 'Inventory already disposed.',
              message:
                  'Review Disposal History on the Inventory Item Detail screen.',
            ),
          );
        }
        return _DisposeInventoryForm(item: item);
      },
    );
  }
}

class _DisposeInventoryForm extends ConsumerStatefulWidget {
  const _DisposeInventoryForm({required this.item});
  final InventoryItem item;

  @override
  ConsumerState<_DisposeInventoryForm> createState() =>
      _DisposeInventoryFormState();
}

class _DisposeInventoryFormState extends ConsumerState<_DisposeInventoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  late DateTime _disposalDate;
  DisposalReason? _reason;

  @override
  void initState() {
    super.initState();
    _disposalDate = DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_disposalDate));
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

  String _inventoryDisplayName() {
    final model = widget.item.model?.trim();
    final equipmentName = model == null || model.isEmpty
        ? widget.item.brand
        : '${widget.item.brand} $model';
    return '${widget.item.inventoryNumber ?? 'Not assigned'} â€” $equipmentName';
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _disposalDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selectedDate == null || !mounted) return;
    setState(() {
      _disposalDate = selectedDate;
      _dateController.text = _formatDate(selectedDate);
    });
  }

  Future<bool> _confirmDisposal() async {
    final reason = _reason;
    if (reason == null) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Disposal'),
        content: Text(
          'Dispose ${_inventoryDisplayName()} as ${reason.label}? This will remove the item from active inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDisposalButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dispose Item'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _reason == null) {
      return;
    }

    if (!await _confirmDisposal()) {
      return;
    }
    try {
      final disposal = await ref
          .read(disposalTransactionControllerProvider.notifier)
          .disposeInventoryItem(
            item: widget.item,
            disposalDate: _disposalDate,
            reason: _reason!,
            notes: _notesController.text,
          );
      if (!mounted) return;
      final message = disposal.requiresReplacementDeal
          ? 'Inventory disposed. Warranty replacement Deal follow-up is required.'
          : 'Inventory disposed successfully.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      context.goNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': widget.item.id!},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to dispose inventory: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(disposalTransactionControllerProvider).isLoading;
    return AppPage(
      title: 'Dispose Inventory',
      subtitle: _inventoryDisplayName(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('disposeInventoryItemField'),
              initialValue: _inventoryDisplayName(),
              enabled: false,
              decoration: const InputDecoration(labelText: 'Inventory Item'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('disposeInventoryDateField'),
              controller: _dateController,
              readOnly: true,
              enabled: !isSaving,
              onTap: isSaving ? null : _selectDate,
              decoration: const InputDecoration(
                labelText: 'Disposal Date',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DisposalReason>(
              key: const Key('disposeInventoryReasonField'),
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Disposal Reason'),
              items: [
                for (final reason in DisposalReason.values)
                  DropdownMenuItem(value: reason, child: Text(reason.label)),
              ],
              onChanged: isSaving
                  ? null
                  : (reason) => setState(() => _reason = reason),
              validator: (reason) =>
                  reason == null ? 'Select a disposal reason.' : null,
            ),
            if (_reason == DisposalReason.warrantyReplacement) ...[
              const SizedBox(height: 16),
              const Card(
                key: Key('warrantyReplacementNotice'),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.handshake_outlined),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Warranty Replacement will flag this disposal for a replacement Deal. The replacement inventory and Deal will be linked in the next workflow step.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('disposeInventoryNotesField'),
              controller: _notesController,
              enabled: !isSaving,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText:
                    'Optional details about why this inventory was disposed.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('disposeInventorySaveButton'),
              onPressed: isSaving ? null : _submit,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(isSaving ? 'Disposing...' : 'Dispose Inventory'),
            ),
          ],
        ),
      ),
    );
  }
}
