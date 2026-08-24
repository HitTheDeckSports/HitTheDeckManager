import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/inventory_enums.dart';
import '../../domain/models/inventory_item.dart';
import '../providers/inventory_controller.dart';
import 'buy_inventory_form_state.dart';

final buyInventoryFormControllerProvider =
    NotifierProvider<BuyInventoryFormController, BuyInventoryFormState>(
      BuyInventoryFormController.new,
    );

class BuyInventoryFormController extends Notifier<BuyInventoryFormState> {
  @override
  BuyInventoryFormState build() {
    return _newFormState();
  }

  void initializeFromItem(InventoryItem item) {
    state = BuyInventoryFormState.fromInventoryItem(item);
  }

  void setCategory(InventoryCategory category) {
    state = state.copyWith(category: category);
  }

  void setBrand(String brand) {
    state = state.copyWith(brand: brand);
  }

  void setModel(String model) {
    state = state.copyWith(model: model);
  }

  void setAcquisitionType(AcquisitionType acquisitionType) {
    state = state.copyWith(acquisitionType: acquisitionType);
  }

  void setAcquisitionValue(String acquisitionValue) {
    state = state.copyWith(acquisitionValue: acquisitionValue);
  }

  void setCondition(InventoryCondition? condition) {
    state = state.copyWith(condition: condition);
  }

  void setPurchaseDate(DateTime? purchaseDate) {
    state = state.copyWith(purchaseDate: purchaseDate);
  }

  void setNewValue(String newValue) {
    state = state.copyWith(newValue: newValue);
  }

  void setAskingPrice(String askingPrice) {
    state = state.copyWith(askingPrice: askingPrice);
  }

  void setMinimumPrice(String minimumPrice) {
    state = state.copyWith(minimumPrice: minimumPrice);
  }

  void setSellerContactId(String? sellerContactId) {
    state = state.copyWith(sellerContactId: sellerContactId);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setLengthInches(String lengthInches) {
    final parsedLength = double.tryParse(lengthInches.trim());
    final parsedWeight = double.tryParse(state.weightOunces.trim());
    final parsedDrop = double.tryParse(state.drop.trim());

    if (parsedLength == null || parsedLength <= 0) {
      state = state.copyWith(lengthInches: lengthInches);
      return;
    }

    if (parsedWeight != null && parsedWeight > 0) {
      state = state.copyWith(
        lengthInches: lengthInches,
        drop: _formatNumber(parsedWeight - parsedLength),
      );
      return;
    }

    if (parsedDrop != null && parsedDrop < 0) {
      final calculatedWeight = parsedLength + parsedDrop;

      state = state.copyWith(
        lengthInches: lengthInches,
        weightOunces: calculatedWeight > 0
            ? _formatNumber(calculatedWeight)
            : state.weightOunces,
      );
      return;
    }

    state = state.copyWith(lengthInches: lengthInches);
  }

  void setWeightOunces(String weightOunces) {
    final parsedLength = double.tryParse(state.lengthInches.trim());
    final parsedWeight = double.tryParse(weightOunces.trim());

    if (parsedLength == null ||
        parsedLength <= 0 ||
        parsedWeight == null ||
        parsedWeight <= 0) {
      state = state.copyWith(weightOunces: weightOunces);
      return;
    }

    state = state.copyWith(
      weightOunces: weightOunces,
      drop: _formatNumber(parsedWeight - parsedLength),
    );
  }

  void setDrop(String drop) {
    final trimmedDrop = drop.trim();
    final enteredDrop = double.tryParse(trimmedDrop);
    final parsedLength = double.tryParse(state.lengthInches.trim());

    if (trimmedDrop.isEmpty || enteredDrop == null) {
      state = state.copyWith(drop: drop);
      return;
    }

    final signedDrop = -enteredDrop.abs();
    final storedDrop = _formatNumber(signedDrop);

    if (parsedLength == null || parsedLength <= 0) {
      state = state.copyWith(drop: storedDrop);
      return;
    }

    final calculatedWeight = parsedLength + signedDrop;

    state = state.copyWith(
      drop: storedDrop,
      weightOunces: calculatedWeight > 0
          ? _formatNumber(calculatedWeight)
          : state.weightOunces,
    );
  }

  void setCertification(String certification) {
    state = state.copyWith(certification: certification);
  }

  void setGloveSizeInches(String gloveSizeInches) {
    state = state.copyWith(gloveSizeInches: gloveSizeInches);
  }

  void setHandOrientation(String handOrientation) {
    state = state.copyWith(handOrientation: handOrientation);
  }

  void setCatchersGearSize(String catchersGearSize) {
    state = state.copyWith(catchersGearSize: catchersGearSize);
  }

  void setPhotoUrls(List<String> photoUrls) {
    state = state.copyWith(photoUrls: photoUrls);
  }

  Future<InventoryItem?> submit({bool resetAfterSave = true}) async {
    final item = state.toInventoryItem();

    if (item == null) {
      return null;
    }

    final savedItem = await ref
        .read(inventoryControllerProvider.notifier)
        .createItem(item);

    if (resetAfterSave) {
      state = _newFormState();
    }

    return savedItem;
  }

  Future<InventoryItem?> submitUpdate(
    InventoryItem existingItem, {
    bool resetAfterSave = true,
  }) async {
    final editedItem = state.toInventoryItem();

    if (editedItem == null) {
      return null;
    }

    final itemToUpdate = editedItem.copyWith(
      id: existingItem.id,
      inventoryNumber: existingItem.inventoryNumber,
      status: existingItem.status,
    );

    final updatedItem = await ref
        .read(inventoryControllerProvider.notifier)
        .updateItem(itemToUpdate);

    if (resetAfterSave) {
      state = _newFormState();
    }

    return updatedItem;
  }

  void reset() {
    state = _newFormState();
  }
}

BuyInventoryFormState _newFormState() {
  final now = DateTime.now();
  return BuyInventoryFormState(
    purchaseDate: DateTime(now.year, now.month, now.day),
  );
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
