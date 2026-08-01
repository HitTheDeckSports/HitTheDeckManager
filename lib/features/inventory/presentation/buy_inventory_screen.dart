import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/app_validators.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../domain/models/inventory_enums.dart';
import 'forms/buy_inventory_form_controller.dart';

class BuyInventoryScreen extends ConsumerStatefulWidget {
  const BuyInventoryScreen({super.key});

  @override
  ConsumerState<BuyInventoryScreen> createState() =>
      _BuyInventoryScreenState();
}

class _BuyInventoryScreenState
    extends ConsumerState<BuyInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(
      buyInventoryFormControllerProvider,
    );

    final formController = ref.read(
      buyInventoryFormControllerProvider.notifier,
    );

    return AppPage(
      title: 'Buy Inventory',
      subtitle:
          'Record equipment purchased, traded, or accepted on consignment.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the primary information for the inventory item.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<InventoryCategory>(
              key: const Key('buyInventoryCategoryField'),
              initialValue: formState.category,
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
              onChanged: (category) {
                if (category != null) {
                  formController.setCategory(category);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('buyInventoryBrandField'),
              initialValue: formState.brand,
              decoration: const InputDecoration(
                labelText: 'Brand',
                hintText: 'Example: Combat',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                return AppValidators.requiredText(
                  value,
                  fieldName: 'Brand',
                );
              },
              onChanged: formController.setBrand,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('buyInventoryModelField'),
              initialValue: formState.model,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'Example: Spec H1',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: formController.setModel,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AcquisitionType>(
              key: const Key('buyInventoryAcquisitionTypeField'),
              initialValue: formState.acquisitionType,
              decoration: const InputDecoration(
                labelText: 'Acquisition Type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final acquisitionType in AcquisitionType.values)
                  DropdownMenuItem(
                    value: acquisitionType,
                    child: Text(acquisitionType.label),
                  ),
              ],
              onChanged: (acquisitionType) {
                if (acquisitionType != null) {
                  formController.setAcquisitionType(
                    acquisitionType,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
              TextFormField(
                key: const Key('buyInventoryAcquisitionValueField'),
                initialValue: formState.acquisitionValue,
                decoration: const InputDecoration(
                labelText: 'Acquisition Value',
                hintText: r'Example: $200.00',
                prefixText: r'$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                return AppValidators.nonNegativeMoney(
                  value,
                  fieldName: 'Acquisition value',
                  required: true,
                );
              },
              onChanged: formController.setAcquisitionValue,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('buyInventoryValidateButton'),
              onPressed: () {
                final isValid =
                    _formKey.currentState?.validate() ?? false;

                if (!isValid) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Basic inventory information is valid.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Validate Information'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Additional inventory fields will be added in the next steps.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}