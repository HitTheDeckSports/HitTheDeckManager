enum InventoryCategory { bat, glove, catchersGear, helmet, other }

enum AcquisitionType { purchased, traded, consignment }

enum InventoryCondition { newItem, likeNew, good, fair, poor }

enum InventoryStatus { available, sold, inactive, broken, disposed }

extension InventoryCategoryLabel on InventoryCategory {
  String get label {
    return switch (this) {
      InventoryCategory.bat => 'Bat',
      InventoryCategory.glove => 'Glove',
      InventoryCategory.catchersGear => "Catcher's Gear",
      InventoryCategory.helmet => 'Helmet',
      InventoryCategory.other => 'Other',
    };
  }
}

extension AcquisitionTypeLabel on AcquisitionType {
  String get label {
    return switch (this) {
      AcquisitionType.purchased => 'Purchased',
      AcquisitionType.traded => 'Traded',
      AcquisitionType.consignment => 'Consignment',
    };
  }
}

extension InventoryConditionLabel on InventoryCondition {
  String get label {
    return switch (this) {
      InventoryCondition.newItem => 'New',
      InventoryCondition.likeNew => 'Like New',
      InventoryCondition.good => 'Good',
      InventoryCondition.fair => 'Fair',
      InventoryCondition.poor => 'Poor',
    };
  }
}

extension InventoryStatusLabel on InventoryStatus {
  String get label {
    return switch (this) {
      InventoryStatus.available => 'Available',
      InventoryStatus.sold => 'Sold',
      InventoryStatus.inactive => 'Inactive',
      InventoryStatus.broken => 'Broken',
      InventoryStatus.disposed => 'Disposed',
    };
  }
}
