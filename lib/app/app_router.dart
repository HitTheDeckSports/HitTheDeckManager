import 'package:go_router/go_router.dart';

import '../features/contacts/presentation/contacts_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/inventory/presentation/buy_inventory_screen.dart';
import '../features/inventory/presentation/sell_inventory_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: AppRouteNames.home,
          builder: (context, state) => const HomeScreen(),
        ),
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
          path: AppRoutes.contacts,
          name: AppRouteNames.contacts,
          builder: (context, state) => const ContactsScreen(),
        ),
        GoRoute(
          path: AppRoutes.transactions,
          name: AppRouteNames.transactions,
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          name: AppRouteNames.reports,
          builder: (context, state) => const ReportScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: AppRouteNames.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
