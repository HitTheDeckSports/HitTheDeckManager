import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/currency_formatter.dart';
import '../../../core/validation/app_validators.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../contacts/presentation/providers/contact_providers.dart';
import '../../transactions/domain/models/transaction_enums.dart';
import '../../transactions/presentation/forms/sale_trade_in_form_controller.dart';
import '../../transactions/presentation/forms/sell_inventory_form_controller.dart';
import '../../transactions/presentation/providers/sale_completion_controller.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../../transactions/presentation/widgets/sale_trade_in_section.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/inventory_item.dart';
import 'providers/inventory_providers.dart';

class SellInventoryScreen extends ConsumerStatefulWidget {
  const SellInventoryScreen({this.initialItem, super.key});

  final InventoryItem? initialItem;

  @override
  ConsumerState<SellInventoryScreen> createState() =>
      _SellInventoryScreenState();
}

class _SellInventoryScreenState extends ConsumerState<SellInventoryScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late bool _isApplyingInitialItem;

  @override
  void initState() {
    super.initState();
    _isApplyingInitialItem = widget.initialItem != null;

    if (_isApplyingInitialItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ref
            .read(sellInventoryFormControllerProvider.notifier)
            .setSelectedItem(widget.initialItem);

        setState(() {
          _isApplyingInitialItem = false;
        });
      });
    }
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
    final contactsAsync = ref.watch(contactsProvider);
    final formState = ref.watch(sellInventoryFormControllerProvider);
    final completionState = ref.watch(saleCompletionControllerProvider);
    final tradeInItems = ref.watch(saleTradeInFormControllerProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);

    final formController = ref.read(
      sellInventoryFormControllerProvider.notifier,
    );
    final isCompletingSale = completionState.isLoading;

    return AppPage(
      title: 'Sell Inventory',
      subtitle: 'Complete the sale for this item.',
      child: inventoryAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading available inventory...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load inventory.',
          details: error.toString(),
          onRetry: () => ref.invalidate(inventoryItemsProvider),
        ),
        data: (items) {
          final availableItems = items
              .where((item) => item.status == InventoryStatus.available)
              .toList();

          final selectedItem = _isApplyingInitialItem
              ? widget.initialItem
              : formState.selectedItem;

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

          final tradeCreditCents = tradeInItems.fold<int>(
            0,
            (total, item) => total + item.acquisitionValueCents,
          );

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'Item',
                  icon: Icons.inventory_2_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 0,
                        child: OverflowBox(
                          minHeight: 0,
                          maxHeight: 0,
                          child: Text('Sale Information'),
                        ),
                      ),
                      DropdownButtonFormField<InventoryItem>(
                        key: const Key('sellInventoryItemField'),
                        initialValue: selectedItem,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Inventory Item',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final item in selectableItems)
                            DropdownMenuItem<InventoryItem>(
                              value: item,
                              child: Text(
                                '${item.inventoryNumber ?? 'Not assigned'} — ${_itemDisplayName(item)}',
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
                        const SizedBox(height: 12),
                        _SelectedItemSummary(
                          item: selectedItem,
                          canViewFinancialData:
                              permissions.canViewFinancialData,
                        ),
                      ],
                    ],
                  ),
                ),
                if (selectedItem != null &&
                    selectedItem.acquisitionType ==
                        AcquisitionType.consignment) ...[
                  const SizedBox(height: 12),
                  _ConsignmentSaleAgreementCard(
                    item: selectedItem,
                    canViewFinancialData: permissions.canViewFinancialData,
                  ),
                ],
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Sale Details',
                  icon: Icons.attach_money_rounded,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final priceField = TextFormField(
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
                        validator: (value) => AppValidators.nonNegativeMoney(
                          value,
                          fieldName: 'Sale price',
                          required: true,
                        ),
                        onChanged: formController.setSalePrice,
                      );

                      final dateField = InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Sale Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formState.saleDate == null
                                    ? 'Select a sale date'
                                    : _formatDate(formState.saleDate!),
                              ),
                            ),
                            TextButton(
                              key: const Key('sellInventorySaleDateButton'),
                              onPressed: isCompletingSale
                                  ? null
                                  : () => _selectSaleDate(
                                      currentDate: formState.saleDate,
                                      formController: formController,
                                    ),
                              child: const Text('Choose'),
                            ),
                          ],
                        ),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (compact) ...[
                            priceField,
                            const SizedBox(height: 12),
                            dateField,
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: priceField),
                                const SizedBox(width: 12),
                                Expanded(child: dateField),
                              ],
                            ),
                          if (selectedItem != null) ...[
                            const SizedBox(height: 10),
                            _PriceReferenceLine(item: selectedItem),
                            if (selectedItem.minimumPriceCents != null &&
                                formState.salePriceCents != null) ...[
                              const SizedBox(height: 10),
                              _MinimumPriceFeedback(
                                salePriceCents: formState.salePriceCents!,
                                minimumPriceCents:
                                    selectedItem.minimumPriceCents!,
                              ),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Payment Method',
                  icon: Icons.credit_card_outlined,
                  child: DropdownButtonFormField<PaymentMethod>(
                    key: const Key('sellInventoryPaymentMethodField'),
                    initialValue: formState.paymentMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final method in PaymentMethod.values)
                        DropdownMenuItem(
                          value: method,
                          child: Row(
                            children: [
                              Icon(_paymentMethodIcon(method), size: 20),
                              const SizedBox(width: 10),
                              Text(method.label),
                            ],
                          ),
                        ),
                    ],
                    onChanged: isCompletingSale
                        ? null
                        : (method) {
                            if (method != null) {
                              formController.setPaymentMethod(method);
                            }
                          },
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Customer',
                  icon: Icons.person_outline,
                  child: contactsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) =>
                        Text('Unable to load contacts: $error'),
                    data: (contacts) {
                      final savedContacts = contacts
                          .where(
                            (contact) =>
                                contact.id != null &&
                                contact.id!.trim().isNotEmpty,
                          )
                          .toList();

                      final selectedBuyerExists =
                          formState.buyerContactId == null ||
                          savedContacts.any(
                            (contact) => contact.id == formState.buyerContactId,
                          );

                      return DropdownButtonFormField<String?>(
                        key: const Key('sellInventoryBuyerField'),
                        initialValue: selectedBuyerExists
                            ? formState.buyerContactId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Buyer',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Buyer Selected'),
                          ),
                          for (final contact in savedContacts)
                            DropdownMenuItem<String?>(
                              value: contact.id,
                              child: Text(contact.name),
                            ),
                        ],
                        onChanged: isCompletingSale
                            ? null
                            : formController.setBuyerContactId,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionCard(
                  title: 'Trade-In Items (Optional)',
                  icon: Icons.swap_horiz_rounded,
                  child: SaleTradeInSection(),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Notes (Optional)',
                  icon: Icons.description_outlined,
                  child: TextFormField(
                    key: const Key('sellInventoryNotesField'),
                    initialValue: formState.notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add any notes about this sale...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: formController.setNotes,
                  ),
                ),
                const SizedBox(height: 12),
                _SaleSummaryCard(
                  selectedItem: selectedItem,
                  salePriceCents: formState.salePriceCents,
                  tradeCreditCents: tradeCreditCents,
                  buyerContactId: formState.buyerContactId,
                  paymentMethod: formState.paymentMethod,
                  canViewFinancialData: permissions.canViewFinancialData,
                ),
                const SizedBox(height: 16),
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
                            final result = await formController.submit(
                              tradeInItems: ref.read(
                                saleTradeInFormControllerProvider,
                              ),
                            );

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

                            ref
                                .read(
                                  saleTradeInFormControllerProvider.notifier,
                                )
                                .reset();
                            ref.invalidate(inventoryItemsProvider);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sale completed for ${result.soldItem.inventoryNumber ?? _itemDisplayName(result.soldItem)}.',
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
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    isCompletingSale ? 'Completing Sale...' : 'Complete Sale',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: isCompletingSale
                      ? null
                      : () {
                          formController.reset();
                          ref
                              .read(saleTradeInFormControllerProvider.notifier)
                              .reset();
                          setState(() {
                            _formKey = GlobalKey<FormState>();
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConsignmentSaleAgreementCard extends ConsumerWidget {
  const _ConsignmentSaleAgreementCard({
    required this.item,
    required this.canViewFinancialData,
  });

  final InventoryItem item;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemId = item.id;
    if (itemId == null || itemId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final consignmentAsync = ref.watch(
      consignmentForInventoryItemProvider(itemId),
    );

    return _SectionCard(
      title: 'Consignment Agreement',
      icon: Icons.assignment_outlined,
      child: consignmentAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading consignment agreement...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load consignment agreement.',
          details: error.toString(),
        ),
        data: (consignment) {
          if (consignment == null) {
            return const Text(
              'Consignment agreement required before this item can be sold.',
            );
          }

          if (!canViewFinancialData) {
            return const Text(
              'A consignment agreement is on file for this item.',
            );
          }

          return Column(
            key: const Key('sellConsignmentAgreementCard'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryRow(
                label: 'Hit the Deck Commission',
                value: CurrencyFormatter.formatCents(
                  consignment.commissionCents,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The consignor payout will be the final sale price minus this commission.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF082A4A),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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
}

class _SelectedItemSummary extends StatelessWidget {
  const _SelectedItemSummary({
    required this.item,
    required this.canViewFinancialData,
  });

  final InventoryItem item;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sellInventorySelectedItemSummary'),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3EB)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _ItemImage(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemDisplayName(item),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF082A4A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inventory Number: ${item.inventoryNumber ?? 'Not assigned'}',
                ),
                const SizedBox(height: 4),
                Text(
                  item.askingPriceCents == null
                      ? 'Asking Price: Not entered'
                      : 'Asking Price: ${CurrencyFormatter.formatCents(item.askingPriceCents!)}',
                ),
                if (canViewFinancialData) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Acquisition Value: ${CurrencyFormatter.formatCents(item.acquisitionValueCents)}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Chip(
            label: Text('Available'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final photo = item.photoUrls.isEmpty ? null : item.photoUrls.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 76,
        height: 76,
        child: photo == null
            ? Container(
                color: const Color(0xFFE9EEF5),
                child: const Icon(Icons.sports_baseball_outlined, size: 34),
              )
            : Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE9EEF5),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
      ),
    );
  }
}

class _PriceReferenceLine extends StatelessWidget {
  const _PriceReferenceLine({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final asking = item.askingPriceCents == null
        ? 'Not entered'
        : CurrencyFormatter.formatCents(item.askingPriceCents!);
    final minimum = item.minimumPriceCents == null
        ? 'Not entered'
        : CurrencyFormatter.formatCents(item.minimumPriceCents!);

    return Text(
      'Asking: $asking   |   Minimum: $minimum',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667383)),
    );
  }
}

class _MinimumPriceFeedback extends StatelessWidget {
  const _MinimumPriceFeedback({
    required this.salePriceCents,
    required this.minimumPriceCents,
  });

  final int salePriceCents;
  final int minimumPriceCents;

  @override
  Widget build(BuildContext context) {
    final difference = salePriceCents - minimumPriceCents;
    final above = difference >= 0;
    final background = above
        ? const Color(0xFFE7F6EC)
        : const Color(0xFFFFECEC);
    final foreground = above
        ? const Color(0xFF167A3E)
        : const Color(0xFFB4232C);

    return Container(
      key: const Key('sellInventoryMinimumPriceFeedback'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            above ? Icons.check_circle : Icons.warning_amber_rounded,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              above
                  ? 'Above Minimum Price — ${CurrencyFormatter.formatCents(difference)} above minimum.'
                  : 'Below Minimum Price — ${CurrencyFormatter.formatCents(difference.abs())} below minimum.',
              style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleSummaryCard extends StatelessWidget {
  const _SaleSummaryCard({
    required this.selectedItem,
    required this.salePriceCents,
    required this.tradeCreditCents,
    required this.buyerContactId,
    required this.paymentMethod,
    required this.canViewFinancialData,
  });

  final InventoryItem? selectedItem;
  final int? salePriceCents;
  final int tradeCreditCents;
  final String? buyerContactId;
  final PaymentMethod paymentMethod;
  final bool canViewFinancialData;

  @override
  Widget build(BuildContext context) {
    final price = salePriceCents;
    final cashDue = price == null ? null : (price - tradeCreditCents);
    final profit = selectedItem == null || price == null
        ? null
        : price - selectedItem!.acquisitionValueCents;
    final margin = price == null || price == 0 || profit == null
        ? null
        : profit / price;

    return _SectionCard(
      title: 'Live Sale Summary',
      icon: Icons.bar_chart_rounded,
      child: Column(
        key: const Key('sellTradeAccountingSummary'),
        children: [
          _SummaryRow(
            label: 'Sale Price',
            value: price == null
                ? 'Not entered'
                : CurrencyFormatter.formatCents(price),
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Trade-In Credit',
            value: CurrencyFormatter.formatCents(tradeCreditCents),
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Cash Due',
            value: cashDue == null
                ? 'Not available'
                : CurrencyFormatter.formatCents(cashDue),
            emphasize: true,
          ),
          if (canViewFinancialData) ...[
            const Divider(height: 22),
            _SummaryRow(
              label: 'Acquisition Value',
              value: selectedItem == null
                  ? 'Not available'
                  : CurrencyFormatter.formatCents(
                      selectedItem!.acquisitionValueCents,
                    ),
            ),
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'Profit',
              value: profit == null
                  ? 'Not available'
                  : CurrencyFormatter.formatCents(profit),
            ),
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'Gross Margin',
              value: margin == null
                  ? 'Not available'
                  : '${(margin * 100).toStringAsFixed(1)}%',
            ),
          ],
          const Divider(height: 22),
          _SummaryRow(
            label: 'Customer',
            value: buyerContactId == null ? 'None selected' : 'Selected',
          ),
          const SizedBox(height: 6),
          _SummaryRow(label: 'Payment', value: paymentMethod.label),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF082A4A),
          )
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 12),
        Text(value, style: style),
      ],
    );
  }
}

String _itemDisplayName(InventoryItem item) {
  final model = item.model?.trim();
  return model == null || model.isEmpty ? item.brand : '${item.brand} $model';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}

IconData _paymentMethodIcon(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.card => Icons.credit_card_outlined,
    PaymentMethod.venmo => Icons.account_balance_wallet_outlined,
    PaymentMethod.paypal => Icons.account_balance_wallet_outlined,
    PaymentMethod.zelle => Icons.account_balance_outlined,
  };
}
