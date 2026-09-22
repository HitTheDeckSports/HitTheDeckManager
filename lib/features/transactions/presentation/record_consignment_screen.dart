import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/validation/app_validators.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import 'providers/consignment_transaction_controller.dart';
import 'providers/transaction_providers.dart';
import 'widgets/inventory_summary_card.dart';

class RecordConsignmentScreen extends ConsumerWidget {
  const RecordConsignmentScreen({required this.inventoryItemId, super.key});

  final String inventoryItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemProvider(inventoryItemId));

    return itemAsync.when(
      loading: () => const AppPage(
        title: 'Record Consignment Agreement',
        child: AppLoadingState(message: 'Loading inventory item...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Record Consignment Agreement',
        child: AppErrorState(
          message: 'Unable to load inventory item.',
          details: error.toString(),
        ),
      ),
      data: (item) {
        if (item == null) {
          return const AppPage(
            title: 'Record Consignment Agreement',
            child: AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Inventory item not found.',
              message: 'A consignment agreement cannot be recorded.',
            ),
          );
        }

        if (item.acquisitionType != AcquisitionType.consignment) {
          return const AppPage(
            title: 'Record Consignment Agreement',
            child: AppEmptyState(
              icon: Icons.block_outlined,
              title: 'Not consigned inventory.',
              message:
                  'Only inventory acquired as Consignment can use this workflow.',
            ),
          );
        }

        final existingAsync = ref.watch(
          consignmentForInventoryItemProvider(inventoryItemId),
        );

        return existingAsync.when(
          loading: () => const AppPage(
            title: 'Record Consignment Agreement',
            child: AppLoadingState(
              message: 'Checking consignment agreement...',
            ),
          ),
          error: (error, stackTrace) => AppPage(
            title: 'Record Consignment Agreement',
            child: AppErrorState(
              message: 'Unable to check consignment agreement.',
              details: error.toString(),
            ),
          ),
          data: (existing) {
            if (existing != null) {
              return AppPage(
                title: 'Record Consignment Agreement',
                child: AppEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Agreement already recorded.',
                  message:
                      'This inventory item already has a consignment agreement.',
                  action: OutlinedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.goNamed(
                          AppRouteNames.inventoryDetail,
                          pathParameters: {'itemId': inventoryItemId},
                        );
                      }
                    },
                    child: const Text('Return to Inventory Item'),
                  ),
                ),
              );
            }

            return _RecordConsignmentForm(item: item);
          },
        );
      },
    );
  }
}

class _RecordConsignmentForm extends ConsumerStatefulWidget {
  const _RecordConsignmentForm({required this.item});

  final InventoryItem item;

  @override
  ConsumerState<_RecordConsignmentForm> createState() {
    return _RecordConsignmentFormState();
  }
}

class _RecordConsignmentFormState
    extends ConsumerState<_RecordConsignmentForm> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _agreementDate;
  late final TextEditingController _dateController;
  late final TextEditingController _commissionController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _agreementDate = DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_agreementDate));
    _commissionController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _agreementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _agreementDate = selected;
      _dateController.text = _formatDate(selected);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final commissionCents = CurrencyFormatter.tryParseToCents(
      _commissionController.text,
    );

    if (commissionCents == null) {
      return;
    }

    try {
      await ref
          .read(consignmentTransactionControllerProvider.notifier)
          .createConsignment(
            item: widget.item,
            consignmentDate: _agreementDate,
            commissionCents: commissionCents,
            notes: _notesController.text,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consignment agreement recorded.')),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(
          AppRouteNames.inventoryDetail,
          pathParameters: {'itemId': widget.item.id!},
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to record consignment agreement: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(consignmentTransactionControllerProvider);
    final isSaving = controllerState.isLoading;

    return AppPage(
      title: 'Record Consignment Agreement',
      showHeader: false,
      compact: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventorySummaryCard.full(
              key: const Key('consignmentInventoryItemCard'),
              item: widget.item,
              contextLabel: 'Consignment',
              statusLabel: widget.item.status.label,
              onTap: () => context.pushNamed(
                AppRouteNames.inventoryDetail,
                pathParameters: {'itemId': widget.item.id!},
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Commission Agreement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record the amount Hit the Deck will keep when this item sells. '
                      'The consignor payout will be the final sale price minus this commission.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('consignmentAgreementDateField'),
              controller: _dateController,
              enabled: !isSaving,
              readOnly: true,
              onTap: isSaving ? null : _selectDate,
              decoration: const InputDecoration(
                labelText: 'Agreement Date',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('consignmentCommissionField'),
              controller: _commissionController,
              enabled: !isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Hit the Deck Commission',
                prefixText: r'$ ',
                hintText: r'Example: $50.00',
              ),
              validator: (value) {
                return AppValidators.nonNegativeMoney(
                  value,
                  fieldName: 'Commission',
                  required: true,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('consignmentNotesField'),
              controller: _notesController,
              enabled: !isSaving,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional agreement, payout, or consignor details.',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              key: const Key('consignmentActionRow'),
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('cancelConsignmentAgreementButton'),
                    onPressed: isSaving
                        ? null
                        : () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.goNamed(
                                AppRouteNames.inventoryDetail,
                                pathParameters: {'itemId': widget.item.id!},
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('saveConsignmentAgreementButton'),
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
                        : const Icon(Icons.assignment_turned_in_outlined),
                    label: Text(isSaving ? 'Saving...' : 'Save Agreement'),
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
