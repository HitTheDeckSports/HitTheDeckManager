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

      expect(template.leftMarginInches, 0.53125);
      expect(template.topMarginInches, 0.5);
      expect(template.horizontalPitchInches, 4.0);
      expect(template.verticalPitchInches, closeTo(2 / 3, 0.0001));
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

    test('position 1 is the upper-left label', () {
      const template = InventoryLabelTemplate.avery5366;

      final slot = template.slotForPosition(1);

      expect(slot.leftInches, 0.53125);
      expect(slot.topInches, 0.5);
      expect(slot.widthInches, 3.4375);
      expect(slot.heightInches, closeTo(2 / 3, 0.0001));
    });

    test('position 2 is the upper-right label', () {
      const template = InventoryLabelTemplate.avery5366;

      final slot = template.slotForPosition(2);

      expect(slot.leftInches, 4.53125);
      expect(slot.topInches, 0.5);
    });

    test('position 3 starts the second row', () {
      const template = InventoryLabelTemplate.avery5366;

      final slot = template.slotForPosition(3);

      expect(slot.leftInches, 0.53125);
      expect(slot.topInches, closeTo(0.5 + (2 / 3), 0.0001));
    });

    test('position 30 is the lower-right label', () {
      const template = InventoryLabelTemplate.avery5366;

      final slot = template.slotForPosition(30);

      expect(slot.leftInches, 4.53125);
      expect(slot.topInches, closeTo(0.5 + (14 * (2 / 3)), 0.0001));
    });

    test('slot lookup rejects an invalid position', () {
      const template = InventoryLabelTemplate.avery5366;

      expect(() => template.slotForPosition(31), throwsRangeError);
    });
  });
}
