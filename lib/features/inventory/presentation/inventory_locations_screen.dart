import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/widgets/app_page.dart';
import '../domain/models/inventory_location.dart';
import 'providers/inventory_location_providers.dart';

class InventoryLocationsScreen extends ConsumerWidget {
  const InventoryLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(inventoryLocationsProvider);

    return AppPage(
      title: 'Inventory Locations',
      subtitle:
          'Manage the preset places where inventory is displayed or stored.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('addInventoryLocationButton'),
              onPressed: () => _addLocation(context, ref),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Location'),
            ),
          ),
          const SizedBox(height: 16),
          locationsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load inventory locations.\n$error'),
              ),
            ),
            data: (locations) {
              if (locations.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined, size: 36),
                        SizedBox(height: 10),
                        Text(
                          'No inventory locations yet.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add your display, storage, or repair locations here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final location in locations)
                    _LocationTile(
                      location: location,
                      onEdit: () => _renameLocation(context, ref, location),
                      onToggleActive: () =>
                          _setActive(context, ref, location, !location.active),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Inactive locations remain attached to inventory already assigned there, but they will not be offered for new assignments.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _addLocation(BuildContext context, WidgetRef ref) async {
    final name = await _showLocationNameDialog(
      context,
      title: 'Add Inventory Location',
      actionLabel: 'Add',
    );
    if (name == null || !context.mounted) return;
    try {
      await ref.read(inventoryLocationRepositoryProvider).createLocation(name);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _renameLocation(
    BuildContext context,
    WidgetRef ref,
    InventoryLocation location,
  ) async {
    final name = await _showLocationNameDialog(
      context,
      title: 'Edit Inventory Location',
      actionLabel: 'Save',
      initialValue: location.name,
    );
    if (name == null || !context.mounted) return;
    try {
      await ref
          .read(inventoryLocationRepositoryProvider)
          .renameLocation(location.id, name);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    InventoryLocation location,
    bool active,
  ) async {
    try {
      await ref
          .read(inventoryLocationRepositoryProvider)
          .setLocationActive(location.id, active);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.location,
    required this.onEdit,
    required this.onToggleActive,
  });
  final InventoryLocation location;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('inventoryLocation-${location.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          location.active
              ? Icons.location_on_outlined
              : Icons.location_off_outlined,
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(location.active ? 'Active' : 'Inactive'),
        trailing: PopupMenuButton<String>(
          key: ValueKey('inventoryLocationMenu-${location.id}'),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'toggle') onToggleActive();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit name')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(
                location.active ? 'Make inactive' : 'Restore location',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showLocationNameDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
  String initialValue = '',
}) {
  var value = initialValue;
  String? errorText;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          void submit() {
            final trimmed = value.trim();
            if (trimmed.isEmpty) {
              setState(() {
                errorText = 'Enter a location name.';
              });
              return;
            }

            Navigator.of(dialogContext).pop(trimmed);
          }

          return AlertDialog(
            title: Text(title),
            content: TextFormField(
              key: const Key('inventoryLocationNameField'),
              initialValue: initialValue,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Location name',
                hintText: 'Example: Main Bat Rack',
                errorText: errorText,
              ),
              onChanged: (newValue) {
                value = newValue;
                if (errorText != null && newValue.trim().isNotEmpty) {
                  setState(() {
                    errorText = null;
                  });
                }
              },
              onFieldSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(onPressed: submit, child: Text(actionLabel)),
            ],
          );
        },
      );
    },
  );
}
