import 'package:flutter/material.dart';

import '../../application/filters/inventory_filter.dart';
import '../../domain/models/inventory_enums.dart';
import '../../domain/models/inventory_location.dart';

class InventoryFilterDialog extends StatefulWidget {
  const InventoryFilterDialog({
    required this.initialCriteria,
    required this.availableBrands,
    this.availableLocations = const [],
    super.key,
  });

  final InventoryFilterCriteria initialCriteria;
  final List<String> availableBrands;
  final List<InventoryLocation> availableLocations;

  @override
  State<InventoryFilterDialog> createState() => _InventoryFilterDialogState();
}

class _InventoryFilterDialogState extends State<InventoryFilterDialog> {
  late Set<InventoryCategory> _selectedCategories;
  late Set<String> _selectedBrands;
  late Set<InventoryCondition> _selectedConditions;
  late Set<InventoryStatus> _selectedStatuses;
  late Set<String> _selectedLocationIds;
  late bool _includeUnassignedLocation;
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
    _selectedCategories = Set<InventoryCategory>.from(
      criteria.selectedCategories,
    );
    if (_selectedCategories.isEmpty && criteria.category != null) {
      _selectedCategories.add(criteria.category!);
    }
    _selectedBrands = Set<String>.from(criteria.selectedBrands);
    if (_selectedBrands.isEmpty &&
        criteria.brand != null &&
        criteria.brand!.trim().isNotEmpty) {
      _selectedBrands.add(criteria.brand!.trim());
    }
    _selectedConditions = Set<InventoryCondition>.from(
      criteria.selectedConditions,
    );
    if (_selectedConditions.isEmpty && criteria.condition != null) {
      _selectedConditions.add(criteria.condition!);
    }
    _selectedStatuses = Set<InventoryStatus>.from(criteria.selectedStatuses);
    if (_selectedStatuses.isEmpty && criteria.status != null) {
      _selectedStatuses.add(criteria.status!);
    }
    _selectedLocationIds = Set<String>.from(criteria.selectedLocationIds);
    _includeUnassignedLocation = criteria.includeUnassignedLocation;
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          const Icon(Icons.filter_list_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Filter Inventory'),
                SizedBox(height: 4),
                Text(
                  'Choose filters to narrow your results',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('inventoryFilterCloseButton'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 640),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterSummaryTile(
                  key: const Key('inventoryFilterCategoryRow'),
                  icon: Icons.sell_outlined,
                  title: 'Category',
                  summary: _categorySummary(),
                  onTap: _selectCategories,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterBrandRow'),
                  icon: Icons.star_border_rounded,
                  title: 'Brand',
                  summary: _brandSummary(),
                  onTap: _selectBrands,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterConditionRow'),
                  icon: Icons.shield_outlined,
                  title: 'Condition',
                  summary: _conditionSummary(),
                  onTap: _selectConditions,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterStatusRow'),
                  icon: Icons.flag_outlined,
                  title: 'Status',
                  summary: _statusSummary(),
                  onTap: _selectStatuses,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterLocationRow'),
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  summary: _locationSummary(),
                  onTap: _selectLocations,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterPurchaseDateRow'),
                  icon: Icons.calendar_today_outlined,
                  title: 'Purchase Date',
                  summary: _dateSummary(_purchaseDateFrom, _purchaseDateTo),
                  onTap: _editPurchaseDate,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterCostRangeRow'),
                  icon: Icons.attach_money_rounded,
                  title: 'Cost Range',
                  summary: _currencyRangeSummary(
                    _minCostController.text,
                    _maxCostController.text,
                  ),
                  onTap: _editCostRange,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterAskingPriceRow'),
                  icon: Icons.local_offer_outlined,
                  title: 'Asking Price',
                  summary: _currencyRangeSummary(
                    _minAskingController.text,
                    _maxAskingController.text,
                  ),
                  onTap: _editAskingRange,
                ),
                const SizedBox(height: 10),
                _FilterSummaryTile(
                  key: const Key('inventoryFilterDaysInInventoryRow'),
                  icon: Icons.schedule_outlined,
                  title: 'Days in Inventory',
                  summary: _plainRangeSummary(
                    _minDaysController.text,
                    _maxDaysController.text,
                  ),
                  onTap: _editDaysRange,
                ),
              ],
            ),
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
                selectedCategories: Set<InventoryCategory>.unmodifiable(
                  _selectedCategories,
                ),
                selectedBrands: Set<String>.unmodifiable(_selectedBrands),
                selectedConditions: Set<InventoryCondition>.unmodifiable(
                  _selectedConditions,
                ),
                selectedStatuses: Set<InventoryStatus>.unmodifiable(
                  _selectedStatuses,
                ),
                selectedLocationIds: Set<String>.unmodifiable(
                  _selectedLocationIds,
                ),
                includeUnassignedLocation: _includeUnassignedLocation,
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

  Future<void> _selectCategories() async {
    final result = await _showMultiSelectSheet<InventoryCategory>(
      title: 'Category',
      currentValues: _selectedCategories,
      options: [
        for (final value in InventoryCategory.values)
          _SelectionOption(label: value.label, value: value),
      ],
      keyPrefix: 'Category',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _selectedCategories = result);
  }

  Future<void> _selectBrands() async {
    final result = await _showMultiSelectSheet<String>(
      title: 'Brand',
      currentValues: _selectedBrands,
      options: [
        for (final value in widget.availableBrands)
          _SelectionOption(label: value, value: value),
      ],
      keyPrefix: 'Brand',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _selectedBrands = result);
  }

  Future<void> _selectConditions() async {
    final result = await _showMultiSelectSheet<InventoryCondition>(
      title: 'Condition',
      currentValues: _selectedConditions,
      options: [
        for (final value in InventoryCondition.values)
          _SelectionOption(label: value.label, value: value),
      ],
      keyPrefix: 'Condition',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _selectedConditions = result);
  }

  Future<void> _selectStatuses() async {
    final result = await _showMultiSelectSheet<InventoryStatus>(
      title: 'Status',
      currentValues: _selectedStatuses,
      options: [
        for (final value in InventoryStatus.values)
          _SelectionOption(label: value.label, value: value),
      ],
      keyPrefix: 'Status',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _selectedStatuses = result);
  }

  Future<void> _selectLocations() async {
    final result = await showModalBottomSheet<_LocationSelectionResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var tempIds = Set<String>.from(_selectedLocationIds);
        var tempUnassigned = _includeUnassignedLocation;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('inventoryFilterLocationSheetClear'),
                          onPressed: () {
                            setModalState(() {
                              tempIds.clear();
                              tempUnassigned = false;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            CheckboxListTile(
                              key: const Key(
                                'inventoryFilterLocationUnassigned',
                              ),
                              value: tempUnassigned,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('Unassigned / No Location'),
                              onChanged: (value) {
                                setModalState(() {
                                  tempUnassigned = value ?? false;
                                });
                              },
                            ),
                            for (final location in widget.availableLocations)
                              CheckboxListTile(
                                key: ValueKey(
                                  'inventoryFilterLocation-${location.id}',
                                ),
                                value: tempIds.contains(location.id),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  location.active
                                      ? location.name
                                      : '${location.name} (Inactive)',
                                ),
                                onChanged: (selected) {
                                  setModalState(() {
                                    if (selected ?? false) {
                                      tempIds.add(location.id);
                                    } else {
                                      tempIds.remove(location.id);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key(
                              'inventoryFilterLocationSheetCancel',
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('inventoryFilterLocationSheetApply'),
                            onPressed: () {
                              Navigator.of(sheetContext).pop(
                                _LocationSelectionResult(
                                  selectedLocationIds: tempIds,
                                  includeUnassignedLocation: tempUnassigned,
                                ),
                              );
                            },
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLocationIds = result.selectedLocationIds;
      _includeUnassignedLocation = result.includeUnassignedLocation;
    });
  }

  Future<void> _editPurchaseDate() async {
    final result = await showModalBottomSheet<_DateRangeResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var tempFrom = _purchaseDateFrom;
        var tempTo = _purchaseDateTo;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate({required bool isFrom}) async {
              final initial = isFrom
                  ? (tempFrom ?? DateTime.now())
                  : (tempTo ?? tempFrom ?? DateTime.now());
              final selected = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selected == null) {
                return;
              }
              setModalState(() {
                if (isFrom) {
                  tempFrom = selected;
                } else {
                  tempTo = selected;
                }
              });
            }

            return _BottomSheetScaffold(
              title: 'Purchase Date',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateActionButton(
                    key: const Key('inventoryFilterPurchaseFrom'),
                    label: 'From',
                    value: tempFrom,
                    onPressed: () => pickDate(isFrom: true),
                  ),
                  const SizedBox(height: 12),
                  _DateActionButton(
                    key: const Key('inventoryFilterPurchaseTo'),
                    label: 'To',
                    value: tempTo,
                    onPressed: () => pickDate(isFrom: false),
                  ),
                ],
              ),
              onClear: () {
                setModalState(() {
                  tempFrom = null;
                  tempTo = null;
                });
              },
              onCancel: () => Navigator.of(sheetContext).pop(),
              onApply: () {
                Navigator.of(
                  sheetContext,
                ).pop(_DateRangeResult(from: tempFrom, to: tempTo));
              },
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _purchaseDateFrom = result.from;
      _purchaseDateTo = result.to;
    });
  }

  Future<void> _editCostRange() => _editRangeSheet(
    title: 'Cost Range',
    leftKey: const Key('inventoryFilterMinCost'),
    rightKey: const Key('inventoryFilterMaxCost'),
    leftLabel: 'Min Cost (\$)',
    rightLabel: 'Max Cost (\$)',
    leftController: _minCostController,
    rightController: _maxCostController,
    decimal: true,
  );

  Future<void> _editAskingRange() => _editRangeSheet(
    title: 'Asking Price',
    leftKey: const Key('inventoryFilterMinAsking'),
    rightKey: const Key('inventoryFilterMaxAsking'),
    leftLabel: 'Min Asking (\$)',
    rightLabel: 'Max Asking (\$)',
    leftController: _minAskingController,
    rightController: _maxAskingController,
    decimal: true,
  );

  Future<void> _editDaysRange() => _editRangeSheet(
    title: 'Days in Inventory',
    leftKey: const Key('inventoryFilterMinDays'),
    rightKey: const Key('inventoryFilterMaxDays'),
    leftLabel: 'Min Days',
    rightLabel: 'Max Days',
    leftController: _minDaysController,
    rightController: _maxDaysController,
  );

  Future<void> _editRangeSheet({
    required String title,
    required Key leftKey,
    required Key rightKey,
    required String leftLabel,
    required String rightLabel,
    required TextEditingController leftController,
    required TextEditingController rightController,
    bool decimal = false,
  }) async {
    final leftText = leftController.text;
    final rightText = rightController.text;

    final result = await showModalBottomSheet<_RangeResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final tempLeft = TextEditingController(text: leftText);
        final tempRight = TextEditingController(text: rightText);
        final keyboardType = decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number;

        return _BottomSheetScaffold(
          title: title,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: leftKey,
                  controller: tempLeft,
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
                  controller: tempRight,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    labelText: rightLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          onClear: () {
            tempLeft.clear();
            tempRight.clear();
          },
          onCancel: () => Navigator.of(sheetContext).pop(),
          onApply: () {
            Navigator.of(
              sheetContext,
            ).pop(_RangeResult(left: tempLeft.text, right: tempRight.text));
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      leftController.text = result.left;
      rightController.text = result.right;
    });
  }

  Future<Set<T>?> _showMultiSelectSheet<T>({
    required String title,
    required Set<T> currentValues,
    required List<_SelectionOption<T>> options,
    required String keyPrefix,
  }) {
    return showModalBottomSheet<Set<T>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var tempValues = Set<T>.from(currentValues);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          key: ValueKey(
                            'inventoryFilter${keyPrefix}SheetClear',
                          ),
                          onPressed: () {
                            setModalState(tempValues.clear);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final option in options)
                              CheckboxListTile(
                                key: ValueKey(
                                  'inventoryFilter$keyPrefix-${option.value}',
                                ),
                                value: tempValues.contains(option.value),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(option.label),
                                onChanged: (selected) {
                                  setModalState(() {
                                    final value = option.value;
                                    if (value == null) {
                                      return;
                                    }
                                    if (selected ?? false) {
                                      tempValues.add(value);
                                    } else {
                                      tempValues.remove(value);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: ValueKey(
                              'inventoryFilter${keyPrefix}SheetCancel',
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: ValueKey(
                              'inventoryFilter${keyPrefix}SheetApply',
                            ),
                            onPressed: () => Navigator.of(
                              sheetContext,
                            ).pop(Set<T>.unmodifiable(tempValues)),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _categorySummary() {
    if (_selectedCategories.isEmpty) {
      return 'Any';
    }
    if (_selectedCategories.length == 1) {
      return _selectedCategories.single.label;
    }
    return '${_selectedCategories.length} selected';
  }

  String _brandSummary() {
    if (_selectedBrands.isEmpty) {
      return 'Any';
    }
    if (_selectedBrands.length == 1) {
      return _selectedBrands.single;
    }
    return '${_selectedBrands.length} selected';
  }

  String _conditionSummary() {
    if (_selectedConditions.isEmpty) {
      return 'Any';
    }
    if (_selectedConditions.length == 1) {
      return _selectedConditions.single.label;
    }
    return '${_selectedConditions.length} selected';
  }

  String _statusSummary() {
    if (_selectedStatuses.isEmpty) {
      return 'Any';
    }
    if (_selectedStatuses.length == 1) {
      return _selectedStatuses.single.label;
    }
    return '${_selectedStatuses.length} selected';
  }

  String _locationSummary() {
    final count =
        _selectedLocationIds.length + (_includeUnassignedLocation ? 1 : 0);
    if (count == 0) {
      return 'Any';
    }
    if (count > 1) {
      return '$count selected';
    }
    if (_includeUnassignedLocation) {
      return 'Unassigned / No Location';
    }
    for (final location in widget.availableLocations) {
      if (_selectedLocationIds.contains(location.id)) {
        return location.name;
      }
    }
    return '1 selected';
  }

  static String _dateSummary(DateTime? from, DateTime? to) {
    if (from == null && to == null) {
      return 'Any';
    }
    if (from != null && to != null) {
      return '${_formatDate(from)} - ${_formatDate(to)}';
    }
    if (from != null) {
      return 'From ${_formatDate(from)}';
    }
    return 'To ${_formatDate(to!)}';
  }

  static String _currencyRangeSummary(String left, String right) {
    final hasLeft = left.trim().isNotEmpty;
    final hasRight = right.trim().isNotEmpty;
    if (!hasLeft && !hasRight) {
      return 'Any';
    }
    if (hasLeft && hasRight) {
      return '\$${left.trim()} - \$${right.trim()}';
    }
    if (hasLeft) {
      return 'Min \$${left.trim()}';
    }
    return 'Max \$${right.trim()}';
  }

  static String _plainRangeSummary(String left, String right) {
    final hasLeft = left.trim().isNotEmpty;
    final hasRight = right.trim().isNotEmpty;
    if (!hasLeft && !hasRight) {
      return 'Any';
    }
    if (hasLeft && hasRight) {
      return '${left.trim()} - ${right.trim()}';
    }
    if (hasLeft) {
      return 'Min ${left.trim()}';
    }
    return 'Max ${right.trim()}';
  }

  static String _formatDate(DateTime value) {
    return '${value.month}/${value.day}/${value.year}';
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

class _FilterSummaryTile extends StatelessWidget {
  const _FilterSummaryTile({
    required super.key,
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD7DFEA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF082A4A)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF082A4A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5E6A79),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetScaffold extends StatelessWidget {
  const _BottomSheetScaffold({
    required this.title,
    required this.child,
    required this.onClear,
    required this.onCancel,
    required this.onApply,
  });

  final String title;
  final Widget child;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: onClear, child: const Text('Clear')),
                const Spacer(),
                TextButton(onPressed: onCancel, child: const Text('Cancel')),
                const SizedBox(width: 12),
                FilledButton(onPressed: onApply, child: const Text('Done')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateActionButton extends StatelessWidget {
  const _DateActionButton({
    required super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$label: ${value == null ? 'Any' : _InventoryFilterDialogState._formatDate(value!)}',
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

class _SelectionOption<T> {
  const _SelectionOption({required this.label, this.value});

  final String label;
  final T? value;
}

class _LocationSelectionResult {
  const _LocationSelectionResult({
    required this.selectedLocationIds,
    required this.includeUnassignedLocation,
  });

  final Set<String> selectedLocationIds;
  final bool includeUnassignedLocation;
}

class _DateRangeResult {
  const _DateRangeResult({required this.from, required this.to});

  final DateTime? from;
  final DateTime? to;
}

class _RangeResult {
  const _RangeResult({required this.left, required this.right});

  final String left;
  final String right;
}
