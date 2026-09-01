import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/media/photo_source.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../inventory/domain/models/inventory_enums.dart';
import '../../inventory/application/photos/inventory_photo_workflow.dart';
import '../../inventory/domain/models/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_controller.dart';
import '../../inventory/presentation/providers/inventory_location_providers.dart';
import '../../inventory/presentation/providers/inventory_photo_providers.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../../inventory/presentation/widgets/inventory_photo_section.dart';
import '../domain/models/disposal_reason.dart';
import '../domain/models/warranty_replacement_inventory_draft.dart';
import 'providers/transaction_providers.dart';
import 'providers/warranty_replacement_controller.dart';
import 'providers/warranty_replacement_providers.dart';

class WarrantyReplacementScreen extends ConsumerWidget {
  const WarrantyReplacementScreen({required this.disposalId, super.key});

  final String disposalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disposalAsync = ref.watch(disposalTransactionProvider(disposalId));

    return disposalAsync.when(
      loading: () => const AppPage(
        title: 'Warranty Replacement',
        child: AppLoadingState(message: 'Loading disposal...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Warranty Replacement',
        child: AppErrorState(
          message: 'Unable to load disposal.',
          details: error.toString(),
        ),
      ),
      data: (disposal) {
        if (disposal == null) {
          return const AppPage(
            title: 'Warranty Replacement',
            child: AppEmptyState(
              icon: Icons.autorenew_outlined,
              title: 'Disposal not found.',
              message: 'The warranty replacement cannot be created.',
            ),
          );
        }

        if (disposal.reason != DisposalReason.warrantyReplacement) {
          return const AppPage(
            title: 'Warranty Replacement',
            child: AppEmptyState(
              icon: Icons.block_outlined,
              title: 'Not a warranty replacement.',
              message:
                  'Only Warranty Replacement disposals can create replacement inventory.',
            ),
          );
        }

        final itemAsync = ref.watch(
          inventoryItemProvider(disposal.inventoryItemId),
        );

        return itemAsync.when(
          loading: () => const AppPage(
            title: 'Warranty Replacement',
            child: AppLoadingState(message: 'Loading disposed inventory...'),
          ),
          error: (error, stackTrace) => AppPage(
            title: 'Warranty Replacement',
            child: AppErrorState(
              message: 'Unable to load disposed inventory.',
              details: error.toString(),
            ),
          ),
          data: (item) {
            if (item == null) {
              return const AppPage(
                title: 'Warranty Replacement',
                child: AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Disposed inventory not found.',
                  message:
                      'The replacement cannot be created without the original item.',
                ),
              );
            }

            return _WarrantyReplacementForm(
              disposalId: disposalId,
              disposedItem: item,
            );
          },
        );
      },
    );
  }
}

class _WarrantyReplacementForm extends ConsumerStatefulWidget {
  const _WarrantyReplacementForm({
    required this.disposalId,
    required this.disposedItem,
  });

  final String disposalId;
  final InventoryItem disposedItem;

  @override
  ConsumerState<_WarrantyReplacementForm> createState() =>
      _WarrantyReplacementFormState();
}

class _WarrantyReplacementFormState
    extends ConsumerState<_WarrantyReplacementForm> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _replacementDate;
  late final TextEditingController _dateController;
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _newValueController = TextEditingController();
  final _askingPriceController = TextEditingController();
  final _minimumPriceController = TextEditingController();
  final _itemNotesController = TextEditingController();
  final _warrantyNotesController = TextEditingController();

  final _lengthController = TextEditingController();
  final _weightController = TextEditingController();
  final _dropController = TextEditingController();
  final _certificationController = TextEditingController();
  final _gloveSizeController = TextEditingController();
  final _handOrientationController = TextEditingController();
  final _catchersGearSizeController = TextEditingController();
  final _helmetSizeController = TextEditingController();

  InventoryCategory _category = InventoryCategory.bat;
  InventoryCondition? _condition = InventoryCondition.newItem;
  String? _locationId;
  final List<PendingInventoryPhoto> _pendingPhotos = [];
  bool _isPickingPhoto = false;
  bool _isUploadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _replacementDate = DateTime.now();
    _dateController = TextEditingController(
      text: _formatDate(_replacementDate),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _newValueController.dispose();
    _askingPriceController.dispose();
    _minimumPriceController.dispose();
    _itemNotesController.dispose();
    _warrantyNotesController.dispose();
    _lengthController.dispose();
    _weightController.dispose();
    _dropController.dispose();
    _certificationController.dispose();
    _gloveSizeController.dispose();
    _handOrientationController.dispose();
    _catchersGearSizeController.dispose();
    _helmetSizeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  String _originalDisplayName() {
    final inventoryNumber = widget.disposedItem.inventoryNumber?.trim();
    final model = widget.disposedItem.model?.trim();
    final name = model == null || model.isEmpty
        ? widget.disposedItem.brand
        : '${widget.disposedItem.brand} $model';

    return inventoryNumber == null || inventoryNumber.isEmpty
        ? name
        : '$inventoryNumber - $name';
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _replacementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _replacementDate = selected;
      _dateController.text = _formatDate(selected);
    });
  }

  int? _optionalCents(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    return CurrencyFormatter.tryParseToCents(value);
  }

  String? _validateOptionalCurrency(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final cents = CurrencyFormatter.tryParseToCents(trimmed);
    if (cents == null || cents < 0) {
      return 'Enter a valid amount.';
    }
    return null;
  }

  double? _optionalDouble(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : double.tryParse(value);
  }

  WarrantyReplacementInventoryDraft _buildDraft() {
    return WarrantyReplacementInventoryDraft(
      category: _category,
      brand: _brandController.text,
      model: _modelController.text,
      condition: _condition,
      newValueCents: _optionalCents(_newValueController.text),
      askingPriceCents: _optionalCents(_askingPriceController.text),
      minimumPriceCents: _optionalCents(_minimumPriceController.text),
      locationId: _locationId,
      notes: _itemNotesController.text,
      lengthInches: _category == InventoryCategory.bat
          ? _optionalDouble(_lengthController)
          : null,
      weightOunces: _category == InventoryCategory.bat
          ? _optionalDouble(_weightController)
          : null,
      drop: _category == InventoryCategory.bat
          ? _optionalDouble(_dropController)
          : null,
      certification: _category == InventoryCategory.bat
          ? _certificationController.text
          : null,
      gloveSizeInches: _category == InventoryCategory.glove
          ? _optionalDouble(_gloveSizeController)
          : null,
      handOrientation: _category == InventoryCategory.glove
          ? _handOrientationController.text
          : null,
      catchersGearSize: _category == InventoryCategory.catchersGear
          ? _catchersGearSizeController.text
          : null,
      helmetSize: _category == InventoryCategory.helmet
          ? _helmetSizeController.text
          : null,
    );
  }

  Future<void> _pickReplacementPhoto(PhotoSource source) async {
    if (_isPickingPhoto || _isUploadingPhotos) {
      return;
    }

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final selectedPhoto = await ref
          .read(inventoryPhotoWorkflowProvider)
          .pickPhoto(
            source: source,
            storedPhotoCount: 0,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to add replacement photo: $error')),
      );
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

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final draft = _buildDraft();
    if (!draft.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(draft.validationErrors.join(' '))));
      return;
    }

    final disposal = await ref.read(
      disposalTransactionProvider(widget.disposalId).future,
    );

    if (disposal == null) {
      return;
    }

    try {
      final deal = await ref
          .read(warrantyReplacementControllerProvider.notifier)
          .createReplacementFromDraft(
            disposal: disposal,
            disposedItem: widget.disposedItem,
            replacementDate: _replacementDate,
            replacementDraft: draft,
            notes: _warrantyNotesController.text,
          );

      final replacementId = deal.replacementInventoryItemId;
      var photoMessage = 'Warranty replacement inventory created.';

      if (_pendingPhotos.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isUploadingPhotos = true;
          });
        }

        try {
          final savedReplacement = await ref.read(
            inventoryItemProvider(replacementId).future,
          );

          if (savedReplacement == null) {
            throw StateError(
              'Replacement inventory could not be reloaded for photo upload.',
            );
          }

          final uploadResult = await ref
              .read(inventoryPhotoWorkflowProvider)
              .uploadPendingPhotos(
                item: savedReplacement,
                pendingPhotos: List<PendingInventoryPhoto>.unmodifiable(
                  _pendingPhotos,
                ),
              );

          if (uploadResult.uploadedPhotos.isNotEmpty) {
            await ref
                .read(inventoryControllerProvider.notifier)
                .updateItem(uploadResult.updatedItem);
            ref.invalidate(inventoryItemProvider(replacementId));
          }

          if (uploadResult.hasFailures) {
            photoMessage =
                'Replacement created. Some photos could not be uploaded.';
          } else {
            photoMessage = 'Warranty replacement inventory and photos created.';
          }
        } catch (error) {
          photoMessage =
              'Replacement created, but photos could not be uploaded: $error';
        } finally {
          if (mounted) {
            setState(() {
              _isUploadingPhotos = false;
            });
          }
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(photoMessage)));

      context.goNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': replacementId},
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create warranty replacement: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(warrantyReplacementControllerProvider);
    final permissions = ref.watch(currentAppPermissionsProvider);
    final existingDealAsync = ref.watch(
      warrantyReplacementDealForDisposalProvider(widget.disposalId),
    );
    final locationsAsync = ref.watch(activeInventoryLocationsProvider);
    final isSaving = controllerState.isLoading || _isUploadingPhotos;

    return existingDealAsync.when(
      loading: () => const AppPage(
        title: 'Warranty Replacement',
        child: AppLoadingState(message: 'Checking replacement...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Warranty Replacement',
        child: AppErrorState(
          message: 'Unable to check replacement.',
          details: error.toString(),
        ),
      ),
      data: (existingDeal) {
        if (existingDeal != null) {
          return AppPage(
            title: 'Warranty Replacement',
            child: AppEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Replacement already created.',
              message:
                  'This disposal is already linked to replacement inventory.',
              action: OutlinedButton(
                onPressed: () {
                  context.goNamed(
                    AppRouteNames.inventoryDetail,
                    pathParameters: {
                      'itemId': existingDeal.replacementInventoryItemId,
                    },
                  );
                },
                child: const Text('View Item'),
              ),
            ),
          );
        }

        return AppPage(
          title: 'Warranty Replacement',
          subtitle: _originalDisplayName(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Original Item',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(_originalDisplayName()),
                        if (permissions.canViewFinancialData) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Carried cost basis: '
                            '${CurrencyFormatter.formatCents(widget.disposedItem.acquisitionValueCents)}',
                            key: const Key('warrantyReplacementCostBasis'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the actual item received from the manufacturer. '
                          'Product details are intentionally not copied from the disposed item.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Replacement Inventory',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InventoryCategory>(
                  key: const Key('warrantyReplacementCategoryField'),
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in InventoryCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('warrantyReplacementBrandField'),
                  controller: _brandController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: 'Brand'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Brand is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('warrantyReplacementModelField'),
                  controller: _modelController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InventoryCondition?>(
                  key: const Key('warrantyReplacementConditionField'),
                  initialValue: _condition,
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
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _condition = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('warrantyReplacementDateField'),
                  controller: _dateController,
                  readOnly: true,
                  enabled: !isSaving,
                  onTap: isSaving ? null : _selectDate,
                  decoration: const InputDecoration(
                    labelText: 'Replacement Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('warrantyReplacementNewValueField'),
                  controller: _newValueController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'New Value'),
                  validator: _validateOptionalCurrency,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('warrantyReplacementAskingPriceField'),
                  controller: _askingPriceController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Asking Price'),
                  validator: _validateOptionalCurrency,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('warrantyReplacementMinimumPriceField'),
                  controller: _minimumPriceController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum Price'),
                  validator: _validateOptionalCurrency,
                ),
                const SizedBox(height: 12),
                locationsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text(
                    'Locations unavailable: $error',
                    key: const Key('warrantyReplacementLocationError'),
                  ),
                  data: (locations) => DropdownButtonFormField<String?>(
                    key: const Key('warrantyReplacementLocationField'),
                    initialValue: _locationId,
                    decoration: const InputDecoration(labelText: 'Location'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      for (final location in locations)
                        DropdownMenuItem<String?>(
                          value: location.id,
                          child: Text(location.name),
                        ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) => setState(() => _locationId = value),
                  ),
                ),
                const SizedBox(height: 16),
                ..._categoryFields(isSaving),
                InventoryPhotoSection(
                  storedPhotoUrls: const [],
                  pendingPhotos: _pendingPhotos,
                  onTakePhoto: () => _pickReplacementPhoto(PhotoSource.camera),
                  onChoosePhoto: () =>
                      _pickReplacementPhoto(PhotoSource.gallery),
                  onRemovePendingPhoto: _removePendingPhoto,
                  isBusy: isSaving || _isPickingPhoto,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('warrantyReplacementItemNotesField'),
                  controller: _itemNotesController,
                  enabled: !isSaving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Inventory Notes',
                    hintText: 'Notes about the physical replacement item.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('warrantyReplacementNotesField'),
                  controller: _warrantyNotesController,
                  enabled: !isSaving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Warranty Notes',
                    hintText: 'Optional claim or manufacturer details.',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('createWarrantyReplacementDealButton'),
                  onPressed: isSaving ? null : _submit,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.autorenew_outlined),
                  label: Text(
                    isSaving
                        ? 'Creating Replacement...'
                        : 'Create Replacement Inventory',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _categoryFields(bool isSaving) {
    switch (_category) {
      case InventoryCategory.bat:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('warrantyReplacementLengthField'),
                  controller: _lengthController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Length'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('warrantyReplacementWeightField'),
                  controller: _weightController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('warrantyReplacementDropField'),
                  controller: _dropController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Drop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('warrantyReplacementCertificationField'),
            controller: _certificationController,
            enabled: !isSaving,
            decoration: const InputDecoration(labelText: 'Certification'),
          ),
          const SizedBox(height: 12),
        ];
      case InventoryCategory.glove:
        return [
          TextFormField(
            key: const Key('warrantyReplacementGloveSizeField'),
            controller: _gloveSizeController,
            enabled: !isSaving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Glove Size'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('warrantyReplacementHandOrientationField'),
            controller: _handOrientationController,
            enabled: !isSaving,
            decoration: const InputDecoration(labelText: 'Hand Orientation'),
          ),
          const SizedBox(height: 12),
        ];
      case InventoryCategory.catchersGear:
        return [
          TextFormField(
            key: const Key('warrantyReplacementCatchersGearSizeField'),
            controller: _catchersGearSizeController,
            enabled: !isSaving,
            decoration: const InputDecoration(labelText: "Catcher's Gear Size"),
          ),
          const SizedBox(height: 12),
        ];
      case InventoryCategory.helmet:
        return [
          TextFormField(
            key: const Key('warrantyReplacementHelmetSizeField'),
            controller: _helmetSizeController,
            enabled: !isSaving,
            decoration: const InputDecoration(labelText: 'Helmet Size'),
          ),
          const SizedBox(height: 12),
        ];
      case InventoryCategory.other:
        return const [];
    }
  }
}
