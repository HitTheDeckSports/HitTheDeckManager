import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/login_screen.dart';
import '../features/contacts/presentation/contact_detail_screen.dart';
import '../features/inventory/presentation/inventory_qr_scanner_screen.dart';
import '../features/contacts/presentation/contacts_screen.dart';
import '../features/contacts/presentation/create_contact_screen.dart';
import '../features/contacts/presentation/edit_contact_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/inventory/presentation/inventory_item_detail_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/search/presentation/universal_search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/add_repair_screen.dart';
import '../features/transactions/presentation/deal_detail_screen.dart';
import '../features/transactions/presentation/dispose_inventory_screen.dart';
import '../features/transactions/presentation/record_consignment_screen.dart';
import '../features/transactions/presentation/repair_detail_screen.dart';
import '../features/transactions/presentation/warranty_replacement_screen.dart';
import '../features/transactions/presentation/edit_repair_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/inventory/presentation/buy_inventory_screen.dart';
import '../features/inventory/presentation/edit_inventory_screen.dart';
import '../features/inventory/presentation/sell_inventory_screen.dart';
import '../features/authentication/presentation/providers/authorization_providers.dart';
import '../features/authentication/presentation/user_access_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Provides the application's router.
///
/// Authentication state is watched here so the router is rebuilt when the
/// user's authorized session changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(authenticatedSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,

    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // While Firebase restores a previous session or authorization is being
      // checked, keep the user outside the protected application shell.
      if (sessionState.isLoading) {
        return isLoginRoute ? null : AppRoutes.login;
      }

      // Authentication/authorization errors must never grant application
      // access. The login screen remains the safe destination.
      if (sessionState.hasError) {
        return isLoginRoute ? null : AppRoutes.login;
      }

      final session = sessionState.value;
      final isAuthorized = session != null;

      if (!isAuthorized) {
        return isLoginRoute ? null : AppRoutes.login;
      }

      // Once an authorized session exists, the login page is no longer needed.
      if (isLoginRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            name: AppRouteNames.inventory,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventoryScanner,
            name: AppRouteNames.inventoryScanner,
            builder: (context, state) => const InventoryQrScannerScreen(),
          ),
          GoRoute(
            path: AppRoutes.buyInventory,
            name: AppRouteNames.buyInventory,
            builder: (context, state) => const BuyInventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.sellInventory,
            name: AppRouteNames.sellInventory,
            builder: (context, state) => const SellInventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventoryEdit,
            name: AppRouteNames.inventoryEdit,
            builder: (context, state) {
              final itemId = state.pathParameters['itemId'];

              if (itemId == null || itemId.isEmpty) {
                throw StateError('Inventory edit route requires an item ID.');
              }

              return EditInventoryScreen(itemId: itemId);
            },
          ),

          GoRoute(
            path: AppRoutes.addRepair,
            name: AppRouteNames.addRepair,
            builder: (context, state) {
              final itemId = state.pathParameters['itemId'];

              if (itemId == null || itemId.isEmpty) {
                throw StateError(
                  'Add Repair route requires an inventory item ID.',
                );
              }

              return AddRepairScreen(inventoryItemId: itemId);
            },
          ),
          GoRoute(
            path: AppRoutes.disposeInventory,
            name: AppRouteNames.disposeInventory,
            builder: (context, state) {
              final itemId = state.pathParameters['itemId'];
              if (itemId == null || itemId.isEmpty) {
                throw StateError(
                  'Dispose Inventory route requires an inventory item ID.',
                );
              }
              return DisposeInventoryScreen(inventoryItemId: itemId);
            },
          ),
          GoRoute(
            path: AppRoutes.recordConsignment,
            name: AppRouteNames.recordConsignment,
            builder: (context, state) {
              final itemId = state.pathParameters['itemId'];

              if (itemId == null || itemId.isEmpty) {
                throw StateError(
                  'Record Consignment route requires an inventory item ID.',
                );
              }

              return RecordConsignmentScreen(inventoryItemId: itemId);
            },
          ),
          GoRoute(
            path: AppRoutes.warrantyReplacement,
            name: AppRouteNames.warrantyReplacement,
            builder: (context, state) {
              final disposalId = state.pathParameters['disposalId'];

              if (disposalId == null || disposalId.isEmpty) {
                throw StateError(
                  'Warranty Replacement route requires a disposal ID.',
                );
              }

              return WarrantyReplacementScreen(disposalId: disposalId);
            },
          ),
          GoRoute(
            path: AppRoutes.repairDetail,
            name: AppRouteNames.repairDetail,
            builder: (context, state) {
              final repairId = state.pathParameters['repairId'];

              if (repairId == null || repairId.isEmpty) {
                throw StateError('Repair detail route requires a repair ID.');
              }

              return RepairDetailScreen(repairId: repairId);
            },
          ),
          GoRoute(
            path: AppRoutes.editRepair,
            name: AppRouteNames.editRepair,
            builder: (context, state) {
              final repairId = state.pathParameters['repairId'];

              if (repairId == null || repairId.isEmpty) {
                throw StateError('Edit Repair route requires a repair ID.');
              }

              return EditRepairScreen(repairId: repairId);
            },
          ),

          GoRoute(
            path: AppRoutes.inventoryDetail,
            name: AppRouteNames.inventoryDetail,
            builder: (context, state) {
              final itemId = state.pathParameters['itemId'];

              if (itemId == null || itemId.isEmpty) {
                throw StateError('Inventory detail route requires an item ID.');
              }

              return InventoryItemDetailScreen(itemId: itemId);
            },
          ),
          GoRoute(
            path: AppRoutes.contacts,
            name: AppRouteNames.contacts,
            builder: (context, state) => const ContactsScreen(),
          ),
          GoRoute(
            path: AppRoutes.createContact,
            name: AppRouteNames.createContact,
            builder: (context, state) => const CreateContactScreen(),
          ),
          GoRoute(
            path: AppRoutes.contactDetail,
            name: AppRouteNames.contactDetail,
            builder: (context, state) {
              final contactId = state.pathParameters['contactId'];

              if (contactId == null || contactId.isEmpty) {
                throw StateError('Contact detail route requires a contact ID.');
              }

              return ContactDetailScreen(contactId: contactId);
            },
          ),
          GoRoute(
            path: AppRoutes.editContact,
            name: AppRouteNames.editContact,
            builder: (context, state) {
              final contactId = state.pathParameters['contactId'];

              if (contactId == null || contactId.isEmpty) {
                throw StateError('Edit Contact route requires a contact ID.');
              }

              return EditContactScreen(contactId: contactId);
            },
          ),
          GoRoute(
            path: AppRoutes.transactions,
            name: AppRouteNames.transactions,
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactionDetail,
            name: AppRouteNames.transactionDetail,
            builder: (context, state) {
              final transactionId = state.pathParameters['transactionId'];

              if (transactionId == null || transactionId.isEmpty) {
                throw StateError(
                  'Transaction detail route requires a transaction ID.',
                );
              }

              return TransactionDetailScreen(transactionId: transactionId);
            },
          ),
          GoRoute(
            path: AppRoutes.dealDetail,
            name: AppRouteNames.dealDetail,
            builder: (context, state) {
              final dealId = state.pathParameters['dealId'];

              if (dealId == null || dealId.isEmpty) {
                throw StateError('Deal detail route requires a Deal ID.');
              }

              return DealDetailScreen(dealId: dealId);
            },
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: AppRouteNames.reports,
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            name: AppRouteNames.search,
            builder: (context, state) => const UniversalSearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: AppRouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.userAccess,
            name: AppRouteNames.userAccess,
            builder: (context, state) => const UserAccessScreen(),
          ),
        ],
      ),
    ],
  );
});
