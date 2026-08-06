import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../contacts/presentation/providers/contact_providers.dart';
import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../domain/models/incoming_trade_item_draft.dart';
import '../domain/models/transaction_enums.dart';
import 'providers/create_trade_controller.dart';

enum _CashDirection { none, paid, received }

class CreateTradeScreen extends ConsumerStatefulWidget {
  const CreateTradeScreen({super.key});

  @override
  ConsumerState<CreateTradeScreen> createState() => _CreateTradeScreenState();
}

class _CreateTradeScreenState extends ConsumerState<CreateTradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _tradeDate = DateTime.now();
  String? _contactId;
  PaymentMethod? _paymentMethod;
  _CashDirection _cashDirection = _CashDirection.none;
  final Set<String> _outgoingItemIds = {};
  final List<IncomingTradeItemDraft> _incomingItems = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_tradeDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTradeDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _tradeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _tradeDate = selectedDate;
      _dateController.text = _formatDate(selectedDate);
    });
  }

  int? _parseCents(String value) {
    final normalized = value.trim().replaceAll(r'$', '').replaceAll(',', '');
    if (normalized.isEmpty) {
      return 0;
    }

    final amount = double.tryParse(normalized);
    if (amount == null || amount < 0) {
      return null;
    }

    return (amount * 100).round();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_outgoingItemIds.isEmpty && _incomingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an outgoing item or add an incoming item.'),
        ),
      );
      return;
    }

    final cashCents = _parseCents(_cashController.text);
    if (cashCents == null) {
      return;
    }

    try {
      await ref
          .read(createTradeControllerProvider.notifier)
          .createTrade(
            CreateTradeRequest(
              outgoingInventoryItemIds: _outgoingItemIds.toList(),
              incomingItems: _incomingItems,
              tradeDate: _tradeDate,
              contactId: _contactId,
              cashPaidCents: _cashDirection == _CashDirection.paid
                  ? cashCents
                  : 0,
              cashReceivedCents: _cashDirection == _CashDirection.received
                  ? cashCents
                  : 0,
              paymentMethod: _cashDirection == _CashDirection.none
                  ? null
                  : _paymentMethod,
              notes: _notesController.text,
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade was created successfully.')),
      );

      context.goNamed(AppRouteNames.transactions);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to create trade: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final contactsAsync = ref.watch(contactsProvider);
    final operationState = ref.watch(createTradeControllerProvider);
    final isSaving = operationState.isLoading;

    return AppPage(
      title: 'Create Trade',
      subtitle:
          'Select inventory leaving the business and add items being received.',
      child: inventoryAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading available inventory...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load inventory.',
          details: error.toString(),
          onRetry: () => ref.invalidate(inventoryItemsProvider),
        ),
        data: (inventoryItems) {
          final availableItems = inventoryItems
              .where((item) => item.status == InventoryStatus.available)
              .toList();

          return contactsAsync.when(
            loading: () =>
                const AppLoadingState(message: 'Loading contacts...'),
            error: (error, stackTrace) => AppErrorState(
              message: 'Unable to load contacts.',
              details: error.toString(),
              onRetry: () => ref.invalidate(contactsProvider),
            ),
            data: (contacts) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('tradeDateField'),
                      controller: _dateController,
                      readOnly: true,
                      enabled: !isSaving,
                      onTap: _selectTradeDate,
                      decoration: const InputDecoration(
                        labelText: 'Trade Date',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      key: const Key('tradeContactField'),
                      initialValue: _contactId,
                      decoration: const InputDecoration(
                        labelText: 'Trade Contact',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No contact selected'),
                        ),
                        for (final contact in contacts)
                          if (contact.id != null)
                            DropdownMenuItem<String?>(
                              value: contact.id,
                              child: Text(contact.name),
                            ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) => setState(() => _contactId = value),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Outgoing Inventory',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (availableItems.isEmpty)
                      const Text('No available inventory items can be traded.')
                    else
                      for (final item in availableItems)
                        CheckboxListTile(
                          key: ValueKey('tradeOutgoingItem-${item.id}'),
                          contentPadding: EdgeInsets.zero,
                          value: _outgoingItemIds.contains(item.id),
                          title: Text(_itemDisplayName(item)),
                          subtitle: Text(
                            'Acquisition value: ${_formatMoney(item.acquisitionValueCents)}',
                          ),
                          onChanged: isSaving || item.id == null
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected ?? false) {
                                      _outgoingItemIds.add(item.id!);
                                    } else {
                                      _outgoingItemIds.remove(item.id);
                                    }
                                  });
                                },
                        ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Incoming Inventory',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const Key('addIncomingTradeItemButton'),
                          onPressed: isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _incomingItems.add(
                                      const IncomingTradeItemDraft(),
                                    );
                                  });
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_incomingItems.isEmpty)
                      const Text('No incoming items added.')
                    else
                      for (
                        var index = 0;
                        index < _incomingItems.length;
                        index++
                      ) ...[
                        _IncomingTradeItemEditor(
                          key: ValueKey('incomingTradeItem-$index'),
                          index: index,
                          draft: _incomingItems[index],
                          enabled: !isSaving,
                          onChanged: (draft) {
                            setState(() => _incomingItems[index] = draft);
                          },
                          onRemove: () {
                            setState(() => _incomingItems.removeAt(index));
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 24),
                    DropdownButtonFormField<_CashDirection>(
                      key: const Key('tradeCashDirectionField'),
                      initialValue: _cashDirection,
                      decoration: const InputDecoration(
                        labelText: 'Cash Adjustment',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _CashDirection.none,
                          child: Text('No cash included'),
                        ),
                        DropdownMenuItem(
                          value: _CashDirection.paid,
                          child: Text('Cash paid by Hit the Deck'),
                        ),
                        DropdownMenuItem(
                          value: _CashDirection.received,
                          child: Text('Cash received by Hit the Deck'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _cashDirection = value ?? _CashDirection.none;
                                if (_cashDirection == _CashDirection.none) {
                                  _cashController.clear();
                                  _paymentMethod = null;
                                }
                              });
                            },
                    ),
                    if (_cashDirection != _CashDirection.none) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('tradeCashAmountField'),
                        controller: _cashController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cash Amount',
                          prefixText: r'$',
                        ),
                        validator: (value) {
                          if (_parseCents(value ?? '') == null) {
                            return 'Enter a valid cash amount.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMethod>(
                        key: const Key('tradePaymentMethodField'),
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                        ),
                        items: [
                          for (final method in PaymentMethod.values)
                            DropdownMenuItem(
                              value: method,
                              child: Text(method.label),
                            ),
                        ],
                        validator: (value) {
                          if (_cashDirection != _CashDirection.none &&
                              value == null) {
                            return 'Select a payment method.';
                          }
                          return null;
                        },
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() => _paymentMethod = value),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('tradeNotesField'),
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('createTradeSubmitButton'),
                      onPressed: isSaving ? null : _submit,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.swap_horiz_outlined),
                      label: Text(
                        isSaving ? 'Saving Trade...' : 'Create Trade',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _IncomingTradeItemEditor extends StatelessWidget {
  const _IncomingTradeItemEditor({
    required this.index,
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final IncomingTradeItemDraft draft;
  final bool enabled;
  final ValueChanged<IncomingTradeItemDraft> onChanged;
  final VoidCallback onRemove;

  int? _parseCents(String value) {
    final amount = double.tryParse(value.trim());
    if (amount == null || amount < 0) {
      return null;
    }
    return (amount * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Incoming Item ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: ValueKey('removeIncomingTradeItem-$index'),
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove incoming item',
                ),
              ],
            ),
            DropdownButtonFormField<InventoryCategory>(
              key: ValueKey('incomingTradeCategory-$index'),
              initialValue: draft.category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in InventoryCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: enabled
                  ? (value) => onChanged(draft.copyWith(category: value))
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('incomingTradeBrand-$index'),
              initialValue: draft.brand,
              enabled: enabled,
              decoration: const InputDecoration(labelText: 'Brand'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Brand is required.';
                }
                return null;
              },
              onChanged: (value) => onChanged(draft.copyWith(brand: value)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('incomingTradeModel-$index'),
              initialValue: draft.model ?? '',
              enabled: enabled,
              decoration: const InputDecoration(labelText: 'Model'),
              onChanged: (value) => onChanged(draft.copyWith(model: value)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InventoryCondition?>(
              key: ValueKey('incomingTradeCondition-$index'),
              initialValue: draft.condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: [
                const DropdownMenuItem<InventoryCondition?>(
                  value: null,
                  child: Text('Not specified'),
                ),
                for (final condition in InventoryCondition.values)
                  DropdownMenuItem<InventoryCondition?>(
                    value: condition,
                    child: Text(condition.label),
                  ),
              ],
              onChanged: enabled
                  ? (value) => onChanged(draft.copyWith(condition: value))
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('incomingTradeValue-$index'),
              initialValue: (draft.acquisitionValueCents / 100).toStringAsFixed(
                2,
              ),
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Acquisition Value',
                prefixText: r'$',
              ),
              validator: (value) {
                if (_parseCents(value ?? '') == null) {
                  return 'Enter a valid acquisition value.';
                }
                return null;
              },
              onChanged: (value) {
                final cents = _parseCents(value);
                if (cents != null) {
                  onChanged(draft.copyWith(acquisitionValueCents: cents));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _itemDisplayName(InventoryItem item) {
  final model = item.model?.trim();
  final name = model == null || model.isEmpty
      ? item.brand
      : '${item.brand} $model';
  return '${item.inventoryNumber ?? 'Not assigned'} — $name';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}

String _formatMoney(int cents) {
  return '\$${(cents / 100).toStringAsFixed(2)}';
}
