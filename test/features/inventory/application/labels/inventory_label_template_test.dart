import 'package:flutter_test/flutter_test.dart';

import 'package:hit_the_deck_manager/features/inventory/application/labels/inventory_label_template.dart';

void main() {
  group('InventoryLabelTemplate', () {
    test('Avery 5366 has the expected physical layout', () {
      const template = InventoryLabelTemplate.avery5366;

      expect(template.id, 'avery-5366');
      expect(template.name, 'Avery 5366');

      expect(template.pageWidthInches, 8.5);
      expect(template.pageHeightInches, 11.0);

      expect(template.labelWidthInches, 3.4375);
      expect(template.labelHeightInches, closeTo(2 / 3, 0.0001));

      expect(template.columns, 2);
      expect(template.rows, 15);
      expect(template.labelsPerSheet, 30);
    });

    test('Avery 5366 accepts starting positions 1 through 30', () {
      const template = InventoryLabelTemplate.avery5366;

      expect(template.isValidStartingPosition(1), isTrue);
      expect(template.isValidStartingPosition(15), isTrue);
      expect(template.isValidStartingPosition(30), isTrue);
    });

    test('Avery 5366 rejects positions outside the sheet', () {
      const template = InventoryLabelTemplate.avery5366;

      expect(template.isValidStartingPosition(0), isFalse);
      expect(template.isValidStartingPosition(31), isFalse);
    });
  });
}
