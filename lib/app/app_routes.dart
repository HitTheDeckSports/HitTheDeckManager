abstract final class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String contacts = '/contacts';
  static const String transactions = '/transactions';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static const String buyInventory = '/inventory/buy';
  static const String sellInventory = '/inventory/sell';
  static const String inventoryDetail = '/inventory/:itemId';
}

abstract final class AppRouteNames {
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String inventory = 'inventory';
  static const String contacts = 'contacts';
  static const String transactions = 'transactions';
  static const String reports = 'reports';
  static const String settings = 'settings';

  static const String buyInventory = 'buyInventory';
  static const String sellInventory = 'sellInventory';
  static const String inventoryDetail = 'inventoryDetail';
}
