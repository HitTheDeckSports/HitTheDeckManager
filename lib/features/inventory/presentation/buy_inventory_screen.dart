import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/validation/app_validators.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../../shared/media/photo_source.dart';
import '../../contacts/presentation/providers/contact_providers.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/inventory_item.dart';
import '../application/photos/inventory_photo_workflow.dart';
import 'forms/buy_inventory_form_controller.dart';
import 'providers/inventory_controller.dart';
import 'providers/inventory_providers.dart';
import 'providers/inventory_photo_providers.dart';
import 'widgets/inventory_photo_section.dart';

class BuyInventoryScreen extends ConsumerStatefulWidget {
  const BuyInventoryScreen({this.existingItem, super.key});

  final InventoryItem? existingItem;

  bool get isEditing => existingItem != null;

  @override
  ConsumerState<BuyInventoryScreen> createState() => _BuyInventoryScreenState();
}

class _BuyInventoryScreenState extends ConsumerState<BuyInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _lengthController = TextEditingController();
  final _weightController = TextEditingController();
  final _dropController = TextEditingController();

  bool _isFormInitialized = false;
  bool _isPickingPhoto = false;
  final List<PendingInventoryPhoto> _pendingPhotos = [];
  InventoryItem? _savedItemForPhotoRetry;
  bool _isUploadingPhotos = false;
  bool _isDeletingStoredPhoto = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final formController = ref.read(
        buyInventoryFormControllerProvider.notifier,
      );

      final existingItem = widget.existingItem;

      if (existingItem == null) {
        formController.reset();
      } else {
        formController.initializeFromItem(existingItem);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isFormInitialized = true;
      });
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$month/$day/${date.year}';
  }

  Future<void> _selectPurchaseDate({
    required DateTime? currentDate,
    required BuyInventoryFormController formController,
  }) async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
    );

    if (selectedDate != null) {
      formController.setPurchaseDate(selectedDate);
    }
  }

  Future<void> _pickInventoryPhoto(PhotoSource source) async {
    if (_isPickingPhoto) {
      return;
    }

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final formState = ref.read(buyInventoryFormControllerProvider);
      final workflow = ref.read(inventoryPhotoWorkflowProvider);

      final selectedPhoto = await workflow.pickPhoto(
        source: source,
        storedPhotoCount: formState.photoUrls.length,
        pendingPhotoCount: _pendingPhotos.length,
      );

      if (!mounted || selectedPhoto == null) {
        return;
      }

      setState(() {
        _pendingPhotos.add(selectedPhoto);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add photo: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  void _removePendingPhoto(String photoId) {
    setState(() {
      _pendingPhotos.removeWhere((photo) => photo.id == photoId);
    });
  }

  Future<void> _removeStoredInventoryPhoto({
    required String photoUrl,
    required BuyInventoryFormController formController,
  }) async {
    final existingItem = widget.existingItem;

    if (existingItem == null) {
      return;
    }

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Photo?'),
          content: const Text(
            'This permanently removes the saved photo from this inventory item.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmRemoveStoredInventoryPhotoButton'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !mounted) {
      return;
    }

    setState(() {
      _isDeletingStoredPhoto = true;
    });

    try {
      final formState = ref.read(buyInventoryFormControllerProvider);

      if (!formState.photoUrls.contains(photoUrl)) {
        return;
      }

      final sourceItem = existingItem.copyWith(
        photoUrls: List<String>.unmodifiable(formState.photoUrls),
      );

      final itemWithoutPhoto = sourceItem.copyWith(
        photoUrls: formState.photoUrls
            .where((storedUrl) => storedUrl != photoUrl)
            .toList(growable: false),
      );

      final persistedItem = await ref
          .read(inventoryControllerProvider.notifier)
          .updateItem(itemWithoutPhoto);

      formController.setPhotoUrls(persistedItem.photoUrls);

      if (persistedItem.id != null) {
        ref.invalidate(inventoryItemProvider(persistedItem.id!));
      }

      var cleanupFailed = false;

      try {
        await ref
            .read(inventoryPhotoWorkflowProvider)
            .removeStoredPhoto(item: sourceItem, photoUrl: photoUrl);
      } catch (_) {
        cleanupFailed = true;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cleanupFailed
                ? 'Photo was removed from the inventory item, but Storage cleanup failed.'
                : 'Photo removed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to remove photo: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingStoredPhoto = false;
        });
      }
    }
  }

  Future<void> _saveInventoryWithPhotos({
    required BuyInventoryFormController formController,
  }) async {
    final retryItem = _savedItemForPhotoRetry;

    if (retryItem == null) {
      final isValid = _formKey.currentState?.validate() ?? false;

      if (!isValid) {
        return;
      }
    }

    setState(() {
      _isUploadingPhotos = true;
    });

    try {
      InventoryItem? savedItem = retryItem;

      if (savedItem == null) {
        final permissions = ref.read(currentAppPermissionsProvider);

        savedItem = widget.isEditing
            ? await formController.submitUpdate(
                widget.existingItem!,
                preserveAcquisitionValue: !permissions.canViewFinancialData,
                resetAfterSave: false,
              )
            : await formController.submit(resetAfterSave: false);

        if (!mounted) {
          return;
        }

        if (savedItem == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEditing
                    ? 'Unable to update the inventory item.'
                    : 'Unable to create the inventory item.',
              ),
            ),
          );
          return;
        }
      }

      var completedItem = savedItem;

      if (_pendingPhotos.isNotEmpty) {
        _savedItemForPhotoRetry = savedItem;

        final workflow = ref.read(inventoryPhotoWorkflowProvider);
        final uploadResult = await workflow.uploadPendingPhotos(
          item: savedItem,
          pendingPhotos: List<PendingInventoryPhoto>.unmodifiable(
            _pendingPhotos,
          ),
        );

        completedItem = uploadResult.updatedItem;

        if (uploadResult.uploadedPhotos.isNotEmpty) {
          completedItem = await ref
              .read(inventoryControllerProvider.notifier)
              .updateItem(completedItem);
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _pendingPhotos
            ..clear()
            ..addAll(uploadResult.failedPhotos);
        });

        if (uploadResult.hasFailures) {
          _savedItemForPhotoRetry = completedItem;
          formController.initializeFromItem(completedItem);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Inventory item ${completedItem.inventoryNumber} was saved, '
                'but ${uploadResult.failedPhotos.length} photo upload(s) failed. '
                'Retry the failed photo uploads.',
              ),
            ),
          );
          return;
        }
      }

      _savedItemForPhotoRetry = null;
      formController.reset();

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingPhotos.clear();
      });

      _formKey.currentState?.reset();
      _lengthController.clear();
      _weightController.clear();
      _dropController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Inventory item ${completedItem.inventoryNumber} was updated.'
                : 'Inventory item ${completedItem.inventoryNumber} was created.',
          ),
        ),
      );

      if (widget.isEditing && completedItem.id != null) {
        ref.invalidate(inventoryItemProvider(completedItem.id!));

        context.goNamed(
          AppRouteNames.inventoryDetail,
          pathParameters: {'itemId': completedItem.id!},
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save inventory: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhotos = false;
        });
      }
    }
  }

  void _updateControllerText({
    required TextEditingController controller,
    required String value,
  }) {
    if (controller.text == value) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _weightController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFormInitialized) {
      return AppPage(
        title: widget.isEditing ? 'Edit Inventory' : 'Buy Inventory',
        subtitle: widget.isEditing
            ? 'Update the saved information for this inventory item.'
            : 'Record equipment purchased, traded, or accepted on consignment.',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final formState = ref.watch(buyInventoryFormControllerProvider);
    ref.listen(buyInventoryFormControllerProvider, (previous, next) {
      _updateControllerText(
        controller: _lengthController,
        value: next.lengthInches,
      );

      _updateControllerText(
        controller: _weightController,
        value: next.weightOunces,
      );

      _updateControllerText(
        controller: _dropController,
        value: next.drop.isEmpty ? '' : next.drop.replaceFirst('-', ''),
      );
    });
    if (_lengthController.text.isEmpty && formState.lengthInches.isNotEmpty) {
      _lengthController.text = formState.lengthInches;
    }

    if (_weightController.text.isEmpty && formState.weightOunces.isNotEmpty) {
      _weightController.text = formState.weightOunces;
    }

    final displayedDrop = formState.drop.isEmpty
        ? ''
        : formState.drop.replaceFirst('-', '');

    if (_dropController.text.isEmpty && displayedDrop.isNotEmpty) {
      _dropController.text = displayedDrop;
    }

    final formController = ref.read(
      buyInventoryFormControllerProvider.notifier,
    );

    final inventoryControllerState = ref.watch(inventoryControllerProvider);

    final contactsAsync = ref.watch(contactsProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);
    final showAcquisitionValue =
        !widget.isEditing || permissions.canViewFinancialData;

    final isSaving =
        inventoryControllerState.isLoading ||
        _isUploadingPhotos ||
        _isDeletingStoredPhoto;

    final hasFailedPhotoUploads = _pendingPhotos.any(
      (photo) => photo.status == PendingInventoryPhotoStatus.failed,
    );
    return AppPage(
      title: widget.isEditing ? 'Edit Inventory' : 'Buy Inventory',
      subtitle: widget.isEditing
          ? 'Update the saved information for this inventory item.'
          : 'Record equipment purchased, traded, or accepted on consignment.',
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
                return AppValidators.requiredText(value, fieldName: 'Brand');
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
                  formController.setAcquisitionType(acquisitionType);
                }
              },
            ),
            if (showAcquisitionValue) ...[
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
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<InventoryCondition?>(
              key: const Key('buyInventoryConditionField'),
              initialValue: formState.condition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<InventoryCondition?>(
                  value: null,
                  child: Text('Not Specified'),
                ),
                for (final condition in InventoryCondition.values)
                  DropdownMenuItem<InventoryCondition?>(
                    value: condition,
                    child: Text(condition.label),
                  ),
              ],
              onChanged: formController.setCondition,
            ),
            const SizedBox(height: 16),
            InkWell(
              key: const Key('buyInventoryPurchaseDateField'),
              onTap: isSaving
                  ? null
                  : () async {
                      await _selectPurchaseDate(
                        currentDate: formState.purchaseDate,
                        formController: formController,
                      );
                    },
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Purchase Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  formState.purchaseDate == null
                      ? 'Not Specified'
                      : _formatDate(formState.purchaseDate!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Seller Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Optionally link the person who sold, traded, or consigned this item.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            contactsAsync.when(
              loading: () => const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Seller',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading contacts...'),
                  ],
                ),
              ),
              error: (error, stackTrace) => InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Seller',
                  border: OutlineInputBorder(),
                  errorText: 'Unable to load contacts.',
                ),
                child: Text(error.toString()),
              ),
              data: (contacts) {
                final savedContacts = contacts
                    .where(
                      (contact) =>
                          contact.id != null && contact.id!.trim().isNotEmpty,
                    )
                    .toList();

                final selectedSellerExists =
                    formState.sellerContactId == null ||
                    savedContacts.any(
                      (contact) => contact.id == formState.sellerContactId,
                    );

                return DropdownButtonFormField<String?>(
                  key: const Key('buyInventorySellerField'),
                  initialValue: selectedSellerExists
                      ? formState.sellerContactId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Seller',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Seller Selected'),
                    ),
                    for (final contact in savedContacts)
                      DropdownMenuItem<String?>(
                        value: contact.id,
                        child: Text(contact.name),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : formController.setSellerContactId,
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Pricing', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enter the estimated value and planned selling prices.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('buyInventoryNewValueField'),
              initialValue: formState.newValue,
              decoration: const InputDecoration(
                labelText: 'New Value',
                hintText: r'Example: $399.99',
                prefixText: r'$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                return AppValidators.nonNegativeMoney(
                  value,
                  fieldName: 'New value',
                );
              },
              onChanged: formController.setNewValue,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('buyInventoryAskingPriceField'),
              initialValue: formState.askingPrice,
              decoration: const InputDecoration(
                labelText: 'Asking Price',
                hintText: r'Example: $275.00',
                prefixText: r'$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                return AppValidators.nonNegativeMoney(
                  value,
                  fieldName: 'Asking price',
                );
              },
              onChanged: formController.setAskingPrice,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('buyInventoryMinimumPriceField'),
              initialValue: formState.minimumPrice,
              decoration: const InputDecoration(
                labelText: 'Minimum Acceptable Price',
                hintText: r'Example: $225.00',
                prefixText: r'$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                return AppValidators.nonNegativeMoney(
                  value,
                  fieldName: 'Minimum acceptable price',
                );
              },
              onChanged: formController.setMinimumPrice,
            ),
            const SizedBox(height: 24),
            Text('Item Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enter details specific to the selected equipment category.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            if (formState.category == InventoryCategory.bat) ...[
              TextFormField(
                key: const Key('buyInventoryLengthField'),
                controller: _lengthController,
                decoration: const InputDecoration(
                  labelText: 'Bat Length',
                  hintText: 'Example: 32',
                  suffixText: 'in',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  return AppValidators.positiveNumber(
                    value,
                    fieldName: 'Bat length',
                  );
                },
                onChanged: formController.setLengthInches,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('buyInventoryWeightField'),
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Bat Weight',
                  hintText: 'Example: 29',
                  suffixText: 'oz',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  return AppValidators.positiveNumber(
                    value,
                    fieldName: 'Bat weight',
                  );
                },
                onChanged: formController.setWeightOunces,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('buyInventoryDropField'),
                controller: _dropController,
                decoration: const InputDecoration(
                  labelText: 'Drop',
                  hintText: 'Example: 3',
                  prefixText: '- ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final trimmedValue = value?.trim() ?? '';

                  if (trimmedValue.isEmpty) {
                    return null;
                  }

                  final parsedDrop = double.tryParse(trimmedValue);

                  if (parsedDrop == null) {
                    return 'Enter a valid Drop.';
                  }

                  if (parsedDrop <= 0) {
                    return 'Drop must be greater than zero.';
                  }

                  return null;
                },
                onChanged: formController.setDrop,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('buyInventoryCertificationField'),
                initialValue: formState.certification,
                decoration: const InputDecoration(
                  labelText: 'Certification',
                  hintText: 'Example: BBCOR, USSSA, or USA Baseball',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: formController.setCertification,
              ),
              const SizedBox(height: 16),
            ],

            if (formState.category == InventoryCategory.glove) ...[
              TextFormField(
                key: const Key('buyInventoryGloveSizeField'),
                initialValue: formState.gloveSizeInches,
                decoration: const InputDecoration(
                  labelText: 'Glove Size',
                  hintText: 'Example: 11.5',
                  suffixText: 'in',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  return AppValidators.positiveNumber(
                    value,
                    fieldName: 'Glove size',
                  );
                },
                onChanged: formController.setGloveSizeInches,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('buyInventoryHandOrientationField'),
                initialValue: formState.handOrientation.isEmpty
                    ? null
                    : formState.handOrientation,
                decoration: const InputDecoration(
                  labelText: 'Hand Orientation',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not Specified'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Right Hand Throw',
                    child: Text('Right Hand Throw'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Left Hand Throw',
                    child: Text('Left Hand Throw'),
                  ),
                ],
                onChanged: (value) {
                  formController.setHandOrientation(value ?? '');
                },
              ),
              const SizedBox(height: 16),
            ],

            if (formState.category == InventoryCategory.catchersGear) ...[
              TextFormField(
                key: const Key('buyInventoryCatchersGearSizeField'),
                initialValue: formState.catchersGearSize,
                decoration: const InputDecoration(
                  labelText: "Catcher's Gear Size",
                  hintText: 'Example: Adult, Intermediate, or Youth',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: formController.setCatchersGearSize,
              ),
              const SizedBox(height: 16),
            ],

            if (formState.category == InventoryCategory.helmet) ...[
              TextFormField(
                key: const Key('buyInventoryHelmetSizeField'),
                initialValue: formState.helmetSize,
                decoration: const InputDecoration(
                  labelText: 'Helmet Size',
                  hintText: 'Example: L/XL, Adult, or Youth',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: formController.setHelmetSize,
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              key: const Key('buyInventoryNotesField'),
              initialValue: formState.notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText:
                    'Enter condition details, included accessories, or other information.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              onChanged: formController.setNotes,
            ),
            const SizedBox(height: 24),
            if (_savedItemForPhotoRetry != null && hasFailedPhotoUploads) ...[
              Container(
                key: const Key('inventoryPhotoRetryMessage'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'The inventory item is saved. One or more photo uploads '
                  'failed; use Retry Photo Uploads to finish attaching them.',
                ),
              ),
              const SizedBox(height: 12),
            ],
            InventoryPhotoSection(
              storedPhotoUrls: formState.photoUrls,
              pendingPhotos: _pendingPhotos,
              isBusy: isSaving || _isPickingPhoto,
              onTakePhoto: () => _pickInventoryPhoto(PhotoSource.camera),
              onChoosePhoto: () => _pickInventoryPhoto(PhotoSource.gallery),
              onRemovePendingPhoto: _removePendingPhoto,
              onRemoveStoredPhoto: widget.isEditing
                  ? (photoUrl) => _removeStoredInventoryPhoto(
                      photoUrl: photoUrl,
                      formController: formController,
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('buyInventorySubmitButton'),
              onPressed: isSaving
                  ? null
                  : () => _saveInventoryWithPhotos(
                      formController: formController,
                    ),
              icon: _savedItemForPhotoRetry != null && hasFailedPhotoUploads
                  ? const Icon(Icons.refresh)
                  : isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _savedItemForPhotoRetry != null && hasFailedPhotoUploads
                    ? isSaving
                          ? 'Retrying Photo Uploads...'
                          : 'Retry Photo Uploads'
                    : isSaving
                    ? widget.isEditing
                          ? 'Saving Changes...'
                          : 'Saving Inventory...'
                    : widget.isEditing
                    ? 'Save Changes'
                    : 'Save Inventory',
              ),
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
