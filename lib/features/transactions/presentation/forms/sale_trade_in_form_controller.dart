import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/incoming_trade_item_draft.dart';

final saleTradeInFormControllerProvider =
    NotifierProvider<SaleTradeInFormController, List<IncomingTradeItemDraft>>(
      SaleTradeInFormController.new,
    );

class SaleTradeInFormController extends Notifier<List<IncomingTradeItemDraft>> {
  @override
  List<IncomingTradeItemDraft> build() => const [];

  void addItem() {
    state = [...state, const IncomingTradeItemDraft()];
  }

  void updateItem(int index, IncomingTradeItemDraft item) {
    final updated = [...state];
    updated[index] = item;
    state = updated;
  }

  void removeItem(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void reset() {
    state = const [];
  }
}
