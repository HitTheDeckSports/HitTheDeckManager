import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/repair_transaction.dart';
import 'forms/repair_form_controller.dart';
import 'providers/repair_transaction_controller.dart';
import 'providers/transaction_providers.dart';

class EditRepairScreen extends ConsumerWidget {
  const EditRepairScreen({required this.repairId, super.key});

  final String repairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repairAsync = ref.watch(repairTransactionProvider(repairId));

    return repairAsync.when(
      loading: () => const AppPage(
        title: 'Edit Repair',
        child: AppLoadingState(message: 'Loading repair...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Edit Repair',
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
            title: 'Edit Repair',
            child: AppEmptyState(
              icon: Icons.build_circle_outlined,
              title: 'Repair not found.',
              message:
                  'The repair may have been removed or is no longer available.',
            ),
          );
        }

        final inventoryItemAsync = ref.watch(
          inventoryItemProvider(repair.inventoryItemId),
        );

        return inventoryItemAsync.when(
          loading: () => const AppPage(
            title: 'Edit Repair',
            child: AppLoadingState(message: 'Loading inventory item...'),
          ),
          error: (error, stackTrace) => AppPage(
            title: 'Edit Repair',
            child: AppErrorState(
              message: 'Unable to load the linked inventory item.',
              details: error.toString(),
              onRetry: () {
                ref.invalidate(inventoryItemProvider(repair.inventoryItemId));
              },
            ),
          ),
          data: (inventoryItem) {
            if (inventoryItem == null) {
              return const AppPage(
                title: 'Edit Repair',
                child: AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory item not found.',
                  message:
                      'The repair cannot be edited because its linked inventory item is unavailable.',
                ),
              );
            }

            return _EditRepairForm(
              repair: repair,
              inventoryItem: inventoryItem,
            );
          },
        );
      },
    );
  }
}

class _EditRepairForm extends ConsumerStatefulWidget {
  const _EditRepairForm({required this.repair, required this.inventoryItem});

  final RepairTransaction repair;
  final InventoryItem inventoryItem;

  @override
  ConsumerState<_EditRepairForm> createState() {
    return _EditRepairFormState();
  }
}

class _EditRepairFormState extends ConsumerState<_EditRepairForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _repairDateController;
  late final TextEditingController _costController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  bool _hasLoadedRepair = false;

  String get _inventoryItemId {
    return widget.inventoryItem.id!;
  }

  @override
  void initState() {
    super.initState();

    _repairDateController = TextEditingController(
      text: _formatDate(widget.repair.repairDate),
    );

    _costController = TextEditingController(
      text: _formatCentsForInput(widget.repair.costCents),
    );

    _descriptionController = TextEditingController(
      text: widget.repair.description,
    );

    _notesController = TextEditingController(text: widget.repair.notes ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasLoadedRepair) {
      return;
    }

    _hasLoadedRepair = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref
          .read(repairFormControllerProvider(_inventoryItemId).notifier)
          .loadRepair(widget.repair);
    });
  }

  @override
  void dispose() {
    _repairDateController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  String _inventoryDisplayName() {
    final model = widget.inventoryItem.model?.trim();

    final equipmentName = model == null || model.isEmpty
        ? widget.inventoryItem.brand
        : '${widget.inventoryItem.brand} $model';

    final inventoryNumber =
        widget.inventoryItem.inventoryNumber ?? 'Inventory number not assigned';

    return '$inventoryNumber — $equipmentName';
  }

  Future<void> _selectRepairDate() async {
    final formProvider = repairFormControllerProvider(_inventoryItemId);

    final formState = ref.read(formProvider);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: formState.repairDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    ref.read(formProvider.notifier).setRepairDate(selectedDate);

    _repairDateController.text = _formatDate(selectedDate);
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final formProvider = repairFormControllerProvider(_inventoryItemId);

    try {
      final updatedRepair = ref
          .read(formProvider.notifier)
          .buildRepairTransaction();

      final savedRepair = await ref
          .read(repairTransactionControllerProvider.notifier)
          .updateRepair(updatedRepair);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repair was updated successfully.')),
      );

      context.goNamed(
        AppRouteNames.repairDetail,
        pathParameters: {'repairId': savedRepair.id!},
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update repair: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = repairFormControllerProvider(_inventoryItemId);

    final formState = ref.watch(formProvider);

    final operationState = ref.watch(repairTransactionControllerProvider);

    final formController = ref.read(formProvider.notifier);

    final isSaving = operationState.isLoading;

    return AppPage(
      title: 'Edit Repair',
      subtitle: _inventoryDisplayName(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('editRepairInventoryItemField'),
              initialValue: _inventoryDisplayName(),
              enabled: false,
              decoration: const InputDecoration(labelText: 'Inventory Item'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('editRepairDateField'),
              controller: _repairDateController,
              enabled: !isSaving,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Repair Date',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onTap: isSaving ? null : _selectRepairDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('editRepairCostField'),
              controller: _costController,
              enabled: !isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Repair Cost',
                prefixText: r'$',
                hintText: '0.00',
              ),
              validator: (_) => formState.costError,
              onChanged: formController.setCostInput,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('editRepairDescriptionField'),
              controller: _descriptionController,
              enabled: !isSaving,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Repair Description',
                hintText: 'Describe the work that was performed',
                alignLabelWithHint: true,
              ),
              validator: (_) => formState.descriptionError,
              onChanged: formController.setDescription,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('editRepairNotesField'),
              controller: _notesController,
              enabled: !isSaving,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter optional repair notes',
                alignLabelWithHint: true,
              ),
              onChanged: formController.setNotes,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('editRepairSubmitButton'),
              onPressed: isSaving ? null : _submit,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Saving Repair...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month/$day/${date.year}';
}

String _formatCentsForInput(int cents) {
  return (cents / 100).toStringAsFixed(2);
}
