import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/labels/inventory_label_data.dart';
import 'package:hit_the_deck_manager/features/inventory/application/labels/inventory_label_pdf_generator.dart';
import 'package:hit_the_deck_manager/features/inventory/application/labels/inventory_label_template.dart';

void main() {
  group('InventoryLabelPdfGenerator', () {
    const label = InventoryLabelData(
      qrValue: 'hitthedeck://inventory/item-123',
      inventoryNumber: 'BAT-2608-0100',
      displayName: 'Combat Spec H1',
    );

    test('generates a non-empty PDF for Avery 5366', () async {
      final bytes = await InventoryLabelPdfGenerator.generateSingleLabelSheet(
        label: label,
        template: InventoryLabelTemplate.avery5366,
        startingPosition: 1,
      );

      expect(bytes, isNotEmpty);

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('generates a sheet using a later starting position', () async {
      final bytes = await InventoryLabelPdfGenerator.generateSingleLabelSheet(
        label: label,
        template: InventoryLabelTemplate.avery5366,
        startingPosition: 17,
      );

      expect(bytes, isNotEmpty);
    });

    test('rejects an invalid starting position', () {
      expect(
        () => InventoryLabelPdfGenerator.generateSingleLabelSheet(
          label: label,
          template: InventoryLabelTemplate.avery5366,
          startingPosition: 31,
        ),
        throwsRangeError,
      );
    });
  });
}
