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
    return const BuyInventoryFormState();
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
    state = state.copyWith(lengthInches: lengthInches);
  }

  void setWeightOunces(String weightOunces) {
    state = state.copyWith(weightOunces: weightOunces);
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

  Future<InventoryItem?> submit() async {
    final item = state.toInventoryItem();

    if (item == null) {
      return null;
    }

    final savedItem = await ref
        .read(inventoryControllerProvider.notifier)
        .createItem(item);

    state = const BuyInventoryFormState();

    return savedItem;
  }

  void reset() {
    state = const BuyInventoryFormState();
  }
}
