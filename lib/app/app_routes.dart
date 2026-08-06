abstract final class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String contacts = '/contacts';
  static const String createContact = '/contacts/new';
  static const String contactDetail = '/contacts/:contactId';
  static const String editContact = '/contacts/:contactId/edit';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transactions/:transactionId';
  static const String createTrade = '/trades/new';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static const String buyInventory = '/inventory/buy';
  static const String sellInventory = '/inventory/sell';
  static const String inventoryEdit = '/inventory/:itemId/edit';
  static const String addRepair = '/inventory/:itemId/repairs/new';
  static const String repairDetail = '/repairs/:repairId';
  static const String editRepair = '/repairs/:repairId/edit';
  static const String inventoryDetail = '/inventory/:itemId';
}

abstract final class AppRouteNames {
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String inventory = 'inventory';
  static const String contacts = 'contacts';
  static const String createContact = 'createContact';
  static const String contactDetail = 'contactDetail';
  static const String editContact = 'editContact';
  static const String transactions = 'transactions';
  static const String transactionDetail = 'transactionDetail';
  static const String createTrade = 'createTrade';
  static const String reports = 'reports';
  static const String settings = 'settings';

  static const String buyInventory = 'buyInventory';
  static const String sellInventory = 'sellInventory';
  static const String inventoryEdit = 'inventoryEdit';
  static const String addRepair = 'addRepair';
  static const String repairDetail = 'repairDetail';
  static const String editRepair = 'editRepair';
  static const String inventoryDetail = 'inventoryDetail';
}
