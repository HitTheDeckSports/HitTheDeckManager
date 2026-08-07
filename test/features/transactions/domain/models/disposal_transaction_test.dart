import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';

void main() {
  test('valid disposal requires an inventory item ID', () {
    final disposal = DisposalTransaction(
      inventoryItemId: 'item-a',
      disposalDate: DateTime(2026, 8, 7),
      reason: DisposalReason.damagedBeyondRepair,
    );
    expect(disposal.isValid, isTrue);
  });

  test('blank inventory item ID is invalid', () {
    final disposal = DisposalTransaction(
      inventoryItemId: '   ',
      disposalDate: DateTime(2026, 8, 7),
      reason: DisposalReason.other,
    );
    expect(disposal.isValid, isFalse);
  });

  test('warranty replacement flags future replacement Deal workflow', () {
    final disposal = DisposalTransaction(
      inventoryItemId: 'item-a',
      disposalDate: DateTime(2026, 8, 7),
      reason: DisposalReason.warrantyReplacement,
    );
    expect(disposal.requiresReplacementDeal, isTrue);
    expect(DisposalReason.other.requiresReplacementDeal, isFalse);
  });
}
