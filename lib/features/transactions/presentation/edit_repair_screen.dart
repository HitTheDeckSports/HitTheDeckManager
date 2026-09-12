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
import '../domain/models/repair_transaction.dart';
import 'forms/repair_form_controller.dart';
import 'providers/repair_transaction_controller.dart';
import 'providers/transaction_providers.dart';
import 'widgets/inventory_summary_card.dart';

class EditRepairScreen extends ConsumerWidget {
  const EditRepairScreen({required this.repairId, super.key});

  final String repairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repairAsync = ref.watch(repairTransactionProvider(repairId));

    return repairAsync.when(
      loading: () => const AppPage(
        title: 'Edit Repair',
        showHeader: false,
        compact: true,
        child: AppLoadingState(message: 'Loading repair...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Edit Repair',
        showHeader: false,
        compact: true,
        child: AppErrorState(
          message: 'Unable to load the repair.',
          details: error.toString(),
          onRetry: () => ref.invalidate(repairTransactionProvider(repairId)),
        ),
      ),
      data: (repair) {
        if (repair == null) {
          return const AppPage(
            title: 'Edit Repair',
            showHeader: false,
            compact: true,
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
            showHeader: false,
            compact: true,
            child: AppLoadingState(message: 'Loading inventory item...'),
          ),
          error: (error, stackTrace) => AppPage(
            title: 'Edit Repair',
            showHeader: false,
            compact: true,
            child: AppErrorState(
              message: 'Unable to load the linked inventory item.',
              details: error.toString(),
              onRetry: () =>
                  ref.invalidate(inventoryItemProvider(repair.inventoryItemId)),
            ),
          ),
          data: (inventoryItem) {
            if (inventoryItem == null) {
              return const AppPage(
                title: 'Edit Repair',
                showHeader: false,
                compact: true,
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
  ConsumerState<_EditRepairForm> createState() => _EditRepairFormState();
}

class _EditRepairFormState extends ConsumerState<_EditRepairForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _repairDateController;
  late final TextEditingController _costController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  bool _hasLoadedRepair = false;

  String get _inventoryItemId => widget.inventoryItem.id!;

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
    if (_hasLoadedRepair) return;
    _hasLoadedRepair = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

  Future<void> _selectRepairDate() async {
    final formProvider = repairFormControllerProvider(_inventoryItemId);
    final formState = ref.read(formProvider);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: formState.repairDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) return;

    ref.read(formProvider.notifier).setRepairDate(selectedDate);
    _repairDateController.text = _formatDate(selectedDate);
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final formProvider = repairFormControllerProvider(_inventoryItemId);

    try {
      final updatedRepair = ref
          .read(formProvider.notifier)
          .buildRepairTransaction();

      final savedRepair = await ref
          .read(repairTransactionControllerProvider.notifier)
          .updateRepair(updatedRepair);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repair was updated successfully.')),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(
          AppRouteNames.repairDetail,
          pathParameters: {'repairId': savedRepair.id!},
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update repair: $error')),
      );
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed(
      AppRouteNames.repairDetail,
      pathParameters: {'repairId': widget.repair.id!},
    );
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
      showHeader: false,
      compact: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventorySummaryCard.full(
              key: const Key('editRepairInventoryItemField'),
              item: widget.inventoryItem,
              contextLabel: 'Repair',
              contextDate: _formatDate(widget.repair.repairDate),
              statusLabel: widget.inventoryItem.status.label,
              onTap: () => context.pushNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': _inventoryItemId},
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.edit_outlined,
              title: 'Repair Information',
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('editRepairDateField'),
                    controller: _repairDateController,
                    enabled: !isSaving,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Repair Date',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onTap: isSaving ? null : _selectRepairDate,
                  ),
                  const SizedBox(height: 14),
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
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) => formState.costError,
                    onChanged: formController.setCostInput,
                  ),
                  const SizedBox(height: 14),
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
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) => formState.descriptionError,
                    onChanged: formController.setDescription,
                  ),
                  const SizedBox(height: 14),
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
                      border: OutlineInputBorder(),
                    ),
                    onChanged: formController.setNotes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('editRepairCancelButton'),
              onPressed: isSaving ? null : _cancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

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
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}

String _formatCentsForInput(int cents) => (cents / 100).toStringAsFixed(2);
