import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';

void main() {
  group('InventoryCategory labels', () {
    test('returns the correct user-facing labels', () {
      expect(InventoryCategory.bat.label, 'Bat');
      expect(InventoryCategory.glove.label, 'Glove');
      expect(InventoryCategory.catchersGear.label, "Catcher's Gear");
      expect(InventoryCategory.helmet.label, 'Helmet');
      expect(InventoryCategory.other.label, 'Other');
    });
  });

  group('AcquisitionType labels', () {
    test('returns the correct user-facing labels', () {
      expect(AcquisitionType.purchased.label, 'Purchased');
      expect(AcquisitionType.traded.label, 'Traded');
      expect(AcquisitionType.consignment.label, 'Consignment');
    });
  });

  group('InventoryCondition labels', () {
    test('returns the correct user-facing labels', () {
      expect(InventoryCondition.newItem.label, 'New');
      expect(InventoryCondition.likeNew.label, 'Like New');
      expect(InventoryCondition.good.label, 'Good');
      expect(InventoryCondition.fair.label, 'Fair');
      expect(InventoryCondition.poor.label, 'Poor');
    });
  });

  group('InventoryStatus labels', () {
    test('returns the correct user-facing labels', () {
      expect(InventoryStatus.available.label, 'Available');
      expect(InventoryStatus.sold.label, 'Sold');
      expect(InventoryStatus.inactive.label, 'Inactive');
      expect(InventoryStatus.broken.label, 'Broken');
      expect(InventoryStatus.disposed.label, 'Disposed');
    });
  });
}
