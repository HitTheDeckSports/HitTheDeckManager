import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/repair_transaction.dart';
import 'repair_form_state.dart';

final repairFormControllerProvider = NotifierProvider.autoDispose
    .family<RepairFormController, RepairFormState, String>(
      RepairFormController.new,
    );

class RepairFormController extends Notifier<RepairFormState> {
  RepairFormController(this.inventoryItemId);

  final String inventoryItemId;

  @override
  RepairFormState build() {
    return RepairFormState.initial(inventoryItemId: inventoryItemId);
  }

  void setRepairDate(DateTime value) {
    state = state.copyWith(repairDate: value);
  }

  void setCostInput(String value) {
    state = state.copyWith(costInput: value);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void loadRepair(RepairTransaction repair) {
    state = RepairFormState(
      repairId: repair.id,
      inventoryItemId: repair.inventoryItemId,
      repairDate: repair.repairDate,
      costInput: _formatCentsForInput(repair.costCents),
      description: repair.description,
      notes: repair.notes ?? '',
    );
  }

  void reset({DateTime? repairDate}) {
    state = RepairFormState.initial(
      inventoryItemId: inventoryItemId,
      repairDate: repairDate,
    );
  }

  RepairTransaction buildRepairTransaction() {
    return state.toRepairTransaction();
  }
}

String _formatCentsForInput(int cents) {
  return (cents / 100).toStringAsFixed(2);
}
