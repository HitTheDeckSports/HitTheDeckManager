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
import 'forms/repair_form_controller.dart';
import 'providers/repair_transaction_controller.dart';

class AddRepairScreen extends ConsumerWidget {
  const AddRepairScreen({
    required this.inventoryItemId,
    this.onSaved,
    super.key,
  });

  final String inventoryItemId;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryItemAsync = ref.watch(
      inventoryItemProvider(inventoryItemId),
    );

    return inventoryItemAsync.when(
      loading: () => const AppPage(
        title: 'Add Repair',
        child: AppLoadingState(message: 'Loading inventory item...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Add Repair',
        child: AppErrorState(
          message: 'Unable to load the inventory item.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(inventoryItemProvider(inventoryItemId));
          },
        ),
      ),
      data: (inventoryItem) {
        if (inventoryItem == null) {
          return const AppPage(
            title: 'Add Repair',
            child: AppEmptyState(
              icon: Icons.build_circle_outlined,
              title: 'Inventory item not found.',
              message:
                  'A repair cannot be added because the inventory item is unavailable.',
            ),
          );
        }

        return _AddRepairForm(inventoryItem: inventoryItem, onSaved: onSaved);
      },
    );
  }
}

class _AddRepairForm extends ConsumerStatefulWidget {
  const _AddRepairForm({required this.inventoryItem, this.onSaved});

  final InventoryItem inventoryItem;
  final VoidCallback? onSaved;

  @override
  ConsumerState<_AddRepairForm> createState() {
    return _AddRepairFormState();
  }
}

class _AddRepairFormState extends ConsumerState<_AddRepairForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _repairDateController;
  late final TextEditingController _costController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  String get _inventoryItemId {
    return widget.inventoryItem.id!;
  }

  @override
  void initState() {
    super.initState();

    final initialState = ref.read(
      repairFormControllerProvider(_inventoryItemId),
    );

    _repairDateController = TextEditingController(
      text: _formatDate(initialState.repairDate),
    );

    _costController = TextEditingController(text: initialState.costInput);

    _descriptionController = TextEditingController(
      text: initialState.description,
    );

    _notesController = TextEditingController(text: initialState.notes);
  }

  @override
  void dispose() {
    _repairDateController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$month/$day/${date.year}';
  }

  String _inventoryDisplayName() {
    final item = widget.inventoryItem;
    final model = item.model?.trim();

    final equipmentName = model == null || model.isEmpty
        ? item.brand
        : '${item.brand} $model';

    final inventoryNumber =
        item.inventoryNumber ?? 'Inventory number not assigned';

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

    final formController = ref.read(formProvider.notifier);

    try {
      final repair = formController.buildRepairTransaction();

      await ref
          .read(repairTransactionControllerProvider.notifier)
          .createRepair(repair);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repair was added successfully.')),
      );

      widget.onSaved?.call();

      if (!mounted) {
        return;
      }

      context.goNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': _inventoryItemId},
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add repair: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = repairFormControllerProvider(_inventoryItemId);

    final formState = ref.watch(formProvider);

    final repairControllerState = ref.watch(
      repairTransactionControllerProvider,
    );

    final formController = ref.read(formProvider.notifier);

    final isSaving = repairControllerState.isLoading;

    return AppPage(
      title: 'Add Repair',
      subtitle: _inventoryDisplayName(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('addRepairInventoryItemField'),
              initialValue: _inventoryDisplayName(),
              enabled: false,
              decoration: const InputDecoration(labelText: 'Inventory Item'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('addRepairDateField'),
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
              key: const Key('addRepairCostField'),
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
              key: const Key('addRepairDescriptionField'),
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
              key: const Key('addRepairNotesField'),
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
              key: const Key('addRepairSubmitButton'),
              onPressed: isSaving ? null : _submit,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Saving Repair...' : 'Add Repair'),
            ),
          ],
        ),
      ),
    );
  }
}
