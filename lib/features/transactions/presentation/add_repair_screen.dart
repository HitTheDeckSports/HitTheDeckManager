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
import 'forms/repair_form_controller.dart';
import 'providers/repair_transaction_controller.dart';
import 'widgets/inventory_summary_card.dart';

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
        showHeader: false,
        compact: true,
        child: AppLoadingState(message: 'Loading inventory item...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Add Repair',
        showHeader: false,
        compact: true,
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
            showHeader: false,
            compact: true,
            child: AppEmptyState(
              icon: Icons.build_circle_outlined,
              title: 'Inventory item not found.',
              message:
                  'A repair cannot be added because the inventory item is unavailable.',
            ),
          );
        }

        if (inventoryItem.status == InventoryStatus.sold ||
            inventoryItem.status == InventoryStatus.disposed) {
          return AppPage(
            title: 'Add Repair',
            showHeader: false,
            compact: true,
            child: AppEmptyState(
              icon: Icons.lock_outline,
              title: 'Repair unavailable.',
              message:
                  '${inventoryItem.status.label} inventory is no longer in '
                  'possession. Reverse the original business event before '
                  'recording additional work.',
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
  ConsumerState<_AddRepairForm> createState() => _AddRepairFormState();
}

class _AddRepairFormState extends ConsumerState<_AddRepairForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _repairDateController;
  late final TextEditingController _costController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  String get _inventoryItemId => widget.inventoryItem.id!;

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
    final formController = ref.read(formProvider.notifier);

    try {
      final repair = formController.buildRepairTransaction();
      await ref
          .read(repairTransactionControllerProvider.notifier)
          .createRepair(repair);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repair was added successfully.')),
      );

      widget.onSaved?.call();

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(
          AppRouteNames.inventoryDetail,
          pathParameters: {'itemId': _inventoryItemId},
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add repair: $error')));
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(
      AppRouteNames.inventoryDetail,
      pathParameters: {'itemId': _inventoryItemId},
    );
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
      showHeader: false,
      compact: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventorySummaryCard.full(
              key: const Key('addRepairInventoryItemField'),
              item: widget.inventoryItem,
              contextLabel: 'New Repair',
              statusLabel: widget.inventoryItem.status.label,
              onTap: () => context.pushNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': _inventoryItemId},
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.build_outlined,
              title: 'Repair Information',
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('addRepairDateField'),
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
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) => formState.costError,
                    onChanged: formController.setCostInput,
                  ),
                  const SizedBox(height: 14),
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
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) => formState.descriptionError,
                    onChanged: formController.setDescription,
                  ),
                  const SizedBox(height: 14),
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
                      border: OutlineInputBorder(),
                    ),
                    onChanged: formController.setNotes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              key: const Key('addRepairActionRow'),
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('addRepairCancelButton'),
                    onPressed: isSaving ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('addRepairSubmitButton'),
                    onPressed: isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(isSaving ? 'Saving...' : 'Add Repair'),
                  ),
                ),
              ],
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
