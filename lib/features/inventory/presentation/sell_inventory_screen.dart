import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/currency_formatter.dart';
import '../../../core/validation/app_validators.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../transactions/domain/models/transaction_enums.dart';
import '../../transactions/presentation/forms/sell_inventory_form_controller.dart';
import '../../transactions/presentation/providers/sale_completion_controller.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/inventory_item.dart';
import 'providers/inventory_providers.dart';

class SellInventoryScreen extends ConsumerStatefulWidget {
  const SellInventoryScreen({super.key});

  @override
  ConsumerState<SellInventoryScreen> createState() =>
      _SellInventoryScreenState();
}

class _SellInventoryScreenState extends ConsumerState<SellInventoryScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$month/$day/${date.year}';
  }

  String _formatMargin(double margin) {
    return '${(margin * 100).toStringAsFixed(1)}%';
  }

  String _itemDisplayName(InventoryItem item) {
    final model = item.model?.trim();

    if (model == null || model.isEmpty) {
      return item.brand;
    }

    return '${item.brand} $model';
  }

  Future<void> _selectSaleDate({
    required DateTime? currentDate,
    required SellInventoryFormController formController,
  }) async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
    );

    if (selectedDate != null) {
      formController.setSaleDate(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final formState = ref.watch(sellInventoryFormControllerProvider);
    final completionState = ref.watch(saleCompletionControllerProvider);

    final formController = ref.read(
      sellInventoryFormControllerProvider.notifier,
    );

    final isCompletingSale = completionState.isLoading;

    return AppPage(
      title: 'Sell Inventory',
      subtitle: 'Select inventory, record payment, and complete a sale.',
      child: inventoryAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading available inventory...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load inventory.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(inventoryItemsProvider);
          },
        ),
        data: (items) {
          final availableItems = items
              .where((item) => item.status == InventoryStatus.available)
              .toList();

          final selectedItem = formState.selectedItem;

          final selectableItems = [...availableItems];

          if (selectedItem != null &&
              !selectableItems.any((item) => item.id == selectedItem.id)) {
            selectableItems.insert(0, selectedItem);
          }

          if (availableItems.isEmpty && selectedItem == null) {
            return const AppEmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'No available inventory.',
              message:
                  'Add inventory or change an item to Available before recording a sale.',
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sale Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an available item and enter the completed sale details.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<InventoryItem>(
                  key: const Key('sellInventoryItemField'),
                  initialValue: selectedItem,
                  decoration: const InputDecoration(
                    labelText: 'Inventory Item',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: [
                    for (final item in selectableItems)
                      DropdownMenuItem<InventoryItem>(
                        value: item,
                        child: Text(
                          '${item.inventoryNumber ?? 'Not assigned'} — '
                          '${_itemDisplayName(item)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  validator: (item) {
                    if (item == null) {
                      return 'Inventory item is required.';
                    }

                    if (item.status != InventoryStatus.available) {
                      return 'Only available inventory can be sold.';
                    }

                    return null;
                  },
                  onChanged: isCompletingSale
                      ? null
                      : formController.setSelectedItem,
                ),
                if (selectedItem != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _itemDisplayName(selectedItem),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inventory Number: '
                            '${selectedItem.inventoryNumber ?? 'Not assigned'}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Acquisition Value: '
                            '${CurrencyFormatter.formatCents(selectedItem.acquisitionValueCents)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedItem.askingPriceCents == null
                                ? 'Asking Price: Not entered'
                                : 'Asking Price: '
                                      '${CurrencyFormatter.formatCents(selectedItem.askingPriceCents!)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('sellInventorySalePriceField'),
                  initialValue: formState.salePrice,
                  decoration: const InputDecoration(
                    labelText: 'Sale Price',
                    hintText: r'Example: $325.00',
                    prefixText: r'$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    return AppValidators.nonNegativeMoney(
                      value,
                      fieldName: 'Sale price',
                      required: true,
                    );
                  },
                  onChanged: formController.setSalePrice,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Sale Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formState.saleDate == null
                              ? 'Select a sale date'
                              : _formatDate(formState.saleDate!),
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('sellInventorySaleDateButton'),
                        onPressed: isCompletingSale
                            ? null
                            : () {
                                _selectSaleDate(
                                  currentDate: formState.saleDate,
                                  formController: formController,
                                );
                              },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Choose Date'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  key: const Key('sellInventoryPaymentMethodField'),
                  initialValue: formState.paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final paymentMethod in PaymentMethod.values)
                      DropdownMenuItem<PaymentMethod>(
                        value: paymentMethod,
                        child: Text(paymentMethod.label),
                      ),
                  ],
                  onChanged: isCompletingSale
                      ? null
                      : (paymentMethod) {
                          if (paymentMethod != null) {
                            formController.setPaymentMethod(paymentMethod);
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('sellInventoryNotesField'),
                  initialValue: formState.notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText:
                        'Enter any additional information about the sale.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: formController.setNotes,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Sale Summary',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Sale Price',
                          value: formState.salePriceCents == null
                              ? '—'
                              : CurrencyFormatter.formatCents(
                                  formState.salePriceCents!,
                                ),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Acquisition Value',
                          value: selectedItem == null
                              ? '—'
                              : CurrencyFormatter.formatCents(
                                  selectedItem.acquisitionValueCents,
                                ),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Profit',
                          value: formState.profitCents == null
                              ? '—'
                              : CurrencyFormatter.formatCents(
                                  formState.profitCents!,
                                ),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Gross Margin',
                          value: formState.grossMargin == null
                              ? '—'
                              : _formatMargin(formState.grossMargin!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('sellInventorySubmitButton'),
                  onPressed: isCompletingSale
                      ? null
                      : () async {
                          final isValid =
                              _formKey.currentState?.validate() ?? false;

                          if (!isValid) {
                            return;
                          }

                          try {
                            final result = await formController.submit();

                            if (!context.mounted) {
                              return;
                            }

                            if (result == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unable to complete the sale. Review the entered information.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _formKey = GlobalKey<FormState>();
                            });

                            ref.invalidate(inventoryItemsProvider);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sale completed for '
                                  '${result.soldItem.inventoryNumber ?? _itemDisplayName(result.soldItem)}.',
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
                                  'Unable to complete sale: $error',
                                ),
                              ),
                            );
                          }
                        },
                  icon: isCompletingSale
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.point_of_sale_outlined),
                  label: Text(
                    isCompletingSale ? 'Completing Sale...' : 'Complete Sale',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
