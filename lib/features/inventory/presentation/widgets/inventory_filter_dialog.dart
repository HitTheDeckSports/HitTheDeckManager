import 'package:flutter/material.dart';

import '../../application/filters/inventory_filter.dart';
import '../../domain/models/inventory_enums.dart';

class InventoryFilterDialog extends StatefulWidget {
  const InventoryFilterDialog({
    required this.initialCriteria,
    required this.availableBrands,
    super.key,
  });

  final InventoryFilterCriteria initialCriteria;
  final List<String> availableBrands;

  @override
  State<InventoryFilterDialog> createState() => _InventoryFilterDialogState();
}

class _InventoryFilterDialogState extends State<InventoryFilterDialog> {
  late InventoryCategory? _category;
  late String? _brand;
  late InventoryCondition? _condition;
  late InventoryStatus? _status;
  late DateTime? _purchaseDateFrom;
  late DateTime? _purchaseDateTo;

  late final TextEditingController _minCostController;
  late final TextEditingController _maxCostController;
  late final TextEditingController _minAskingController;
  late final TextEditingController _maxAskingController;
  late final TextEditingController _minDaysController;
  late final TextEditingController _maxDaysController;

  @override
  void initState() {
    super.initState();
    final criteria = widget.initialCriteria;
    _category = criteria.category;
    _brand = criteria.brand;
    _condition = criteria.condition;
    _status = criteria.status;
    _purchaseDateFrom = criteria.purchaseDateFrom;
    _purchaseDateTo = criteria.purchaseDateTo;
    _minCostController = TextEditingController(
      text: _dollars(criteria.minimumAcquisitionValueCents),
    );
    _maxCostController = TextEditingController(
      text: _dollars(criteria.maximumAcquisitionValueCents),
    );
    _minAskingController = TextEditingController(
      text: _dollars(criteria.minimumAskingPriceCents),
    );
    _maxAskingController = TextEditingController(
      text: _dollars(criteria.maximumAskingPriceCents),
    );
    _minDaysController = TextEditingController(
      text: criteria.minimumDaysInInventory?.toString() ?? '',
    );
    _maxDaysController = TextEditingController(
      text: criteria.maximumDaysInInventory?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minCostController.dispose();
    _maxCostController.dispose();
    _minAskingController.dispose();
    _maxAskingController.dispose();
    _minDaysController.dispose();
    _maxDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('inventoryFilterDialog'),
      title: const Text('Filter Inventory'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<InventoryCategory?>(
                key: const Key('inventoryFilterCategory'),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  for (final value in InventoryCategory.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('inventoryFilterBrand'),
                initialValue: _brand,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  for (final value in widget.availableBrands)
                    DropdownMenuItem(value: value, child: Text(value)),
                ],
                onChanged: (value) => setState(() => _brand = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InventoryCondition?>(
                key: const Key('inventoryFilterCondition'),
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  for (final value in InventoryCondition.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) => setState(() => _condition = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InventoryStatus?>(
                key: const Key('inventoryFilterStatus'),
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  for (final value in InventoryStatus.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 16),
              _DateFilterRow(
                from: _purchaseDateFrom,
                to: _purchaseDateTo,
                onPickFrom: () => _pickDate(isFrom: true),
                onPickTo: () => _pickDate(isFrom: false),
              ),
              const SizedBox(height: 16),
              _RangeFields(
                leftKey: const Key('inventoryFilterMinCost'),
                rightKey: const Key('inventoryFilterMaxCost'),
                leftController: _minCostController,
                rightController: _maxCostController,
                leftLabel: 'Min Cost (\$)',
                rightLabel: 'Max Cost (\$)',
                decimal: true,
              ),
              const SizedBox(height: 12),
              _RangeFields(
                leftKey: const Key('inventoryFilterMinAsking'),
                rightKey: const Key('inventoryFilterMaxAsking'),
                leftController: _minAskingController,
                rightController: _maxAskingController,
                leftLabel: 'Min Asking (\$)',
                rightLabel: 'Max Asking (\$)',
                decimal: true,
              ),
              const SizedBox(height: 12),
              _RangeFields(
                leftKey: const Key('inventoryFilterMinDays'),
                rightKey: const Key('inventoryFilterMaxDays'),
                leftController: _minDaysController,
                rightController: _maxDaysController,
                leftLabel: 'Min Days',
                rightLabel: 'Max Days',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventoryFilterClearButton'),
          onPressed: () {
            Navigator.of(context).pop(const InventoryFilterCriteria());
          },
          child: const Text('Clear Filters'),
        ),
        TextButton(
          key: const Key('inventoryFilterCancelButton'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('inventoryFilterApplyButton'),
          onPressed: () {
            Navigator.of(context).pop(
              InventoryFilterCriteria(
                category: _category,
                brand: _brand,
                condition: _condition,
                status: _status,
                purchaseDateFrom: _purchaseDateFrom,
                purchaseDateTo: _purchaseDateTo,
                minimumAcquisitionValueCents: _parseDollars(
                  _minCostController.text,
                ),
                maximumAcquisitionValueCents: _parseDollars(
                  _maxCostController.text,
                ),
                minimumAskingPriceCents: _parseDollars(
                  _minAskingController.text,
                ),
                maximumAskingPriceCents: _parseDollars(
                  _maxAskingController.text,
                ),
                minimumDaysInInventory: _parseInt(_minDaysController.text),
                maximumDaysInInventory: _parseInt(_maxDaysController.text),
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_purchaseDateFrom ?? DateTime.now())
        : (_purchaseDateTo ?? DateTime.now());

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isFrom) {
        _purchaseDateFrom = selected;
      } else {
        _purchaseDateTo = selected;
      }
    });
  }

  static String _dollars(int? cents) {
    if (cents == null) {
      return '';
    }
    return (cents / 100).toStringAsFixed(2);
  }

  static int? _parseDollars(String value) {
    final number = double.tryParse(value.trim());
    if (number == null) {
      return null;
    }
    return (number * 100).round();
  }

  static int? _parseInt(String value) => int.tryParse(value.trim());
}

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('inventoryFilterPurchaseFrom'),
            onPressed: onPickFrom,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('From: ${_format(from)}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('inventoryFilterPurchaseTo'),
            onPressed: onPickTo,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('To: ${_format(to)}'),
          ),
        ),
      ],
    );
  }

  String _format(DateTime? value) {
    if (value == null) {
      return 'Any';
    }
    return '${value.month}/${value.day}/${value.year}';
  }
}

class _RangeFields extends StatelessWidget {
  const _RangeFields({
    required this.leftKey,
    required this.rightKey,
    required this.leftController,
    required this.rightController,
    required this.leftLabel,
    required this.rightLabel,
    this.decimal = false,
  });

  final Key leftKey;
  final Key rightKey;
  final TextEditingController leftController;
  final TextEditingController rightController;
  final String leftLabel;
  final String rightLabel;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final keyboardType = decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number;

    return Row(
      children: [
        Expanded(
          child: TextField(
            key: leftKey,
            controller: leftController,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: leftLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            key: rightKey,
            controller: rightController,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: rightLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
