import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/warranty_replacement_inventory_draft.dart';

void main() {
  test('creates fresh inventory while carrying only financial basis', () {
    const draft = WarrantyReplacementInventoryDraft(
      category: InventoryCategory.bat,
      brand: 'Marucci',
      model: 'CatX2',
      condition: InventoryCondition.likeNew,
      askingPriceCents: 34900,
      locationId: 'showroom',
      lengthInches: 32,
      weightOunces: 29,
      certification: 'BBCOR',
      photoUrls: ['replacement-photo'],
    );

    final replacement = draft.toInventoryItem(
      carriedAcquisitionType: AcquisitionType.traded,
      carriedAcquisitionValueCents: 18000,
      replacementDate: DateTime(2026, 9, 5),
    );

    expect(replacement.brand, 'Marucci');
    expect(replacement.model, 'CatX2');
    expect(replacement.condition, InventoryCondition.likeNew);
    expect(replacement.acquisitionType, AcquisitionType.traded);
    expect(replacement.acquisitionValueCents, 18000);
    expect(replacement.status, InventoryStatus.available);
    expect(replacement.sellerContactId, isNull);
    expect(replacement.locationId, 'showroom');
    expect(replacement.photoUrls, const ['replacement-photo']);
  });

  test('rejects missing brand and invalid pricing', () {
    const draft = WarrantyReplacementInventoryDraft(
      category: InventoryCategory.bat,
      brand: ' ',
      askingPriceCents: 10000,
      minimumPriceCents: 12000,
    );

    expect(draft.isValid, isFalse);
    expect(draft.validationErrors, contains('Brand is required.'));
    expect(
      draft.validationErrors,
      contains('Minimum price cannot exceed asking price.'),
    );
  });
}
