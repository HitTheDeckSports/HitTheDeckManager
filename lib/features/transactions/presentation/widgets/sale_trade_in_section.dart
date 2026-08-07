import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/domain/models/inventory_enums.dart';
import '../../domain/models/incoming_trade_item_draft.dart';
import '../forms/sale_trade_in_form_controller.dart';

class SaleTradeInSection extends ConsumerWidget {
  const SaleTradeInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(saleTradeInFormControllerProvider);
    final controller = ref.read(saleTradeInFormControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trade-In Items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optionally add equipment received from the buyer as part of this sale.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              key: const Key('addSaleTradeInItemButton'),
              onPressed: controller.addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Trade-In'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('No trade-in items added.')
        else
          for (var index = 0; index < items.length; index++) ...[
            _TradeInItemEditor(
              key: ValueKey('saleTradeInItem-$index'),
              index: index,
              item: items[index],
              onChanged: (item) => controller.updateItem(index, item),
              onRemove: () => controller.removeItem(index),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _TradeInItemEditor extends StatelessWidget {
  const _TradeInItemEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final IncomingTradeItemDraft item;
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
                    'Trade-In Item ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: ValueKey('removeSaleTradeInItem-$index'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove trade-in item',
                ),
              ],
            ),
            DropdownButtonFormField<InventoryCategory>(
              key: ValueKey('saleTradeInCategory-$index'),
              initialValue: item.category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in InventoryCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(item.copyWith(category: value));
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('saleTradeInBrand-$index'),
              initialValue: item.brand,
              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Brand is required.';
                }

                return null;
              },
              onChanged: (value) => onChanged(item.copyWith(brand: value)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('saleTradeInModel-$index'),
              initialValue: item.model ?? '',
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => onChanged(item.copyWith(model: value)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InventoryCondition?>(
              key: ValueKey('saleTradeInCondition-$index'),
              initialValue: item.condition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
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
              onChanged: (value) => onChanged(item.copyWith(condition: value)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('saleTradeInValue-$index'),
              initialValue: (item.acquisitionValueCents / 100).toStringAsFixed(
                2,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Acquisition Value',
                prefixText: r'$ ',
                border: OutlineInputBorder(),
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
                  onChanged(item.copyWith(acquisitionValueCents: cents));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
